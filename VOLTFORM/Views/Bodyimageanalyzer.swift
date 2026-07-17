import Vision
import UIKit

// MARK: - Metrics extracted from the photo

struct BodyImageMetrics {
    /// Silhouette width at shoulder line / width at waist line. Higher = more V-shaped.
    let shoulderToWaistRatio: Double
    /// Silhouette width at waist line / width at hip line.
    let waistToHipRatio: Double
    /// Silhouette width at shoulder line / width at hip line.
    let shoulderToHipRatio: Double
    /// Waist width relative to torso length. Higher = bulkier midsection.
    let torsoBulk: Double
    /// 0...1 — average Vision joint confidence for the joints used.
    let confidence: Double
    let classification: BodyImageClassification
}

enum BodyImageClassification: String {
    case lean = "Lean"
    case athletic = "Athletic"
    case muscular = "Muscular"
    case average = "Average"
    case fuller = "Fuller"

    var label: String { rawValue.lowercased() }
}

// MARK: - Analyzer

enum BodyImageAnalyzer {

    /// Metrics from the most recent successful scan. Set by the onboarding scan step,
    /// consumed in `finalize()` when building the BodyScan. Cleared on skip/retake.
    static var lastMetrics: BodyImageMetrics?

    /// Returns nil only when no human is found in the image.
    /// Fail-open on internal errors: if a body is detected but measurement fails,
    /// returns low-confidence `.average` metrics so the flow never dead-ends.
    static func analyze(cgImage: CGImage?, orientation: CGImagePropertyOrientation) async -> BodyImageMetrics? {
        guard let cgImage else {
            return fallbackMetrics() // corrupt input — fail open
        }
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(returning: performAnalysis(cgImage: cgImage, orientation: orientation))
            }
        }
    }

    // MARK: Pipeline

    private static func performAnalysis(cgImage: CGImage, orientation: CGImagePropertyOrientation) -> BodyImageMetrics? {
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation)

        let poseRequest = VNDetectHumanBodyPoseRequest()
        let segmentationRequest = VNGeneratePersonSegmentationRequest()
        segmentationRequest.qualityLevel = .accurate
        segmentationRequest.outputPixelFormat = kCVPixelFormatType_OneComponent8

        do {
            try handler.perform([poseRequest, segmentationRequest])
        } catch {
            return fallbackMetrics() // Vision failed entirely — fail open
        }

        // 1. Require a human somewhere in the frame.
        guard let pose = poseRequest.results?.first else {
            // No pose — try upper-body rectangles before declaring "no human".
            let rectRequest = VNDetectHumanRectanglesRequest()
            rectRequest.upperBodyOnly = true
            try? handler.perform([rectRequest])
            if !(rectRequest.results?.isEmpty ?? true) {
                return fallbackMetrics() // human present, joints unreadable
            }
            return nil // genuinely no body in the photo
        }

        // 2. Pull the four anchor joints.
        guard
            let points = try? pose.recognizedPoints(.all),
            let lShoulder = points[.leftShoulder], lShoulder.confidence > 0.3,
            let rShoulder = points[.rightShoulder], rShoulder.confidence > 0.3,
            let lHip = points[.leftHip], lHip.confidence > 0.3,
            let rHip = points[.rightHip], rHip.confidence > 0.3
        else {
            return fallbackMetrics()
        }

        let jointConfidence = Double(lShoulder.confidence + rShoulder.confidence + lHip.confidence + rHip.confidence) / 4.0

        // 3. Measure silhouette widths from the segmentation mask.
        guard let mask = segmentationRequest.results?.first?.pixelBuffer else {
            return fallbackMetrics(confidence: jointConfidence * 0.5)
        }

        // Vision points: normalized, origin bottom-left. Mask rows: top-down.
        let shoulderY = (Double(lShoulder.location.y) + Double(rShoulder.location.y)) / 2.0
        let hipY = (Double(lHip.location.y) + Double(rHip.location.y)) / 2.0
        let waistY = hipY + (shoulderY - hipY) * 0.42 // natural waist sits ~42% up the torso

        let shoulderWidth = silhouetteWidth(in: mask, atNormalizedY: shoulderY)
        let waistWidth = silhouetteWidth(in: mask, atNormalizedY: waistY)
        let hipWidth = silhouetteWidth(in: mask, atNormalizedY: hipY)

        guard shoulderWidth > 0, waistWidth > 0, hipWidth > 0 else {
            return fallbackMetrics(confidence: jointConfidence * 0.5)
        }

        let maskHeight = Double(CVPixelBufferGetHeight(mask))
        let torsoLengthPixels = abs(shoulderY - hipY) * maskHeight
        guard torsoLengthPixels > 1 else {
            return fallbackMetrics(confidence: jointConfidence * 0.5)
        }

        let sToW = shoulderWidth / waistWidth
        let wToH = waistWidth / hipWidth
        let sToH = shoulderWidth / hipWidth
        let bulk = waistWidth / torsoLengthPixels

        return BodyImageMetrics(
            shoulderToWaistRatio: sToW,
            waistToHipRatio: wToH,
            shoulderToHipRatio: sToH,
            torsoBulk: bulk,
            confidence: jointConfidence,
            classification: classify(shoulderToWaist: sToW, torsoBulk: bulk)
        )
    }

    // MARK: Classification heuristics (tunable thresholds)

    private static func classify(shoulderToWaist: Double, torsoBulk: Double) -> BodyImageClassification {
        switch (shoulderToWaist, torsoBulk) {
        case (1.5..., 0.85...):        return .muscular   // wide shoulders AND thick torso
        case (1.32..., _):             return .athletic   // clear V-taper
        case (..<1.12, 1.05...):       return .fuller     // straight silhouette, thick midsection
        case (_, ..<0.70):             return .lean       // narrow torso relative to its length
        default:                       return .average
        }
    }

    // MARK: Mask sampling

    /// Longest contiguous run of body pixels in the mask row at the given normalized Y
    /// (bottom-left origin). Contiguity ignores background objects at the row edges.
    private static func silhouetteWidth(in mask: CVPixelBuffer, atNormalizedY y: Double) -> Double {
        CVPixelBufferLockBaseAddress(mask, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(mask, .readOnly) }

        guard let base = CVPixelBufferGetBaseAddress(mask) else { return 0 }
        let width = CVPixelBufferGetWidth(mask)
        let height = CVPixelBufferGetHeight(mask)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(mask)

        let row = min(max(Int((1.0 - y) * Double(height)), 0), height - 1)
        let rowPointer = base.advanced(by: row * bytesPerRow).assumingMemoryBound(to: UInt8.self)

        var longestRun = 0
        var currentRun = 0
        for x in 0..<width {
            if rowPointer[x] > 127 {
                currentRun += 1
                longestRun = max(longestRun, currentRun)
            } else {
                currentRun = 0
            }
        }
        return Double(longestRun)
    }

    // MARK: Fail-open fallback

    private static func fallbackMetrics(confidence: Double = 0.25) -> BodyImageMetrics {
        BodyImageMetrics(
            shoulderToWaistRatio: 1.2,
            waistToHipRatio: 1.0,
            shoulderToHipRatio: 1.2,
            torsoBulk: 0.85,
            confidence: confidence,
            classification: .average
        )
    }
}
