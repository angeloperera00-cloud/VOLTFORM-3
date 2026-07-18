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
    /// Real posture measurements from joint positions. Nil when legs/head weren't visible enough.
    let posture: PostureMetrics?
}

/// All values measured from Vision joint coordinates — nothing invented.
struct PostureMetrics {
    /// Shoulder line angle vs horizontal, degrees. Positive = left shoulder higher.
    let shoulderTiltDegrees: Double
    /// Vertical shoulder height difference in cm (needs user height; nil otherwise).
    let shoulderOffsetCm: Double?
    /// Which side sits lower, for display ("Right shoulder slightly lower").
    let lowerShoulder: BodySide?
    /// Hip line angle vs horizontal, degrees.
    let pelvicTiltDegrees: Double
    /// Lateral head tilt vs vertical, degrees (front view CAN measure this — unlike forward-head).
    let headTiltDegrees: Double?
    /// Max horizontal knee deviation from the hip–ankle line, as fraction of leg length. 0 = perfect.
    let kneeDeviation: Double
    /// Stance asymmetry between ankles, 0 = perfectly even.
    let ankleAsymmetry: Double
    /// 40...98, computed from the deviations above.
    let score: Int

    var kneeAlignmentLabel: String { kneeDeviation < 0.035 ? "Good" : (kneeDeviation < 0.07 ? "Fair" : "Off") }
    var ankleAlignmentLabel: String { ankleAsymmetry < 0.04 ? "Good" : (ankleAsymmetry < 0.08 ? "Fair" : "Off") }
}

enum BodySide: String {
    case left = "Left"
    case right = "Right"
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

    /// Metrics from the most recent successful scan. Set by the scan flow,
    /// consumed when building the BodyScanResult. Cleared on skip/retake.
    static var lastMetrics: BodyImageMetrics?

    /// Returns nil only when no human is found in the image.
    /// Pass the user's height to get shoulder offset in real cm.
    /// Fail-open on internal errors: if a body is detected but measurement fails,
    /// returns low-confidence `.average` metrics so the flow never dead-ends.
    static func analyze(cgImage: CGImage?, orientation: CGImagePropertyOrientation, userHeightCm: Double? = nil) async -> BodyImageMetrics? {
        guard let cgImage else {
            return fallbackMetrics() // corrupt input — fail open
        }
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(returning: performAnalysis(cgImage: cgImage, orientation: orientation, userHeightCm: userHeightCm))
            }
        }
    }

    // MARK: Pipeline

    private static func performAnalysis(cgImage: CGImage, orientation: CGImagePropertyOrientation, userHeightCm: Double?) -> BodyImageMetrics? {
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

        let maskWidth = Double(CVPixelBufferGetWidth(mask))
        let maskHeight = Double(CVPixelBufferGetHeight(mask))

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

        let torsoLengthPixels = abs(shoulderY - hipY) * maskHeight
        guard torsoLengthPixels > 1 else {
            return fallbackMetrics(confidence: jointConfidence * 0.5)
        }

        let sToW = shoulderWidth / waistWidth
        let wToH = waistWidth / hipWidth
        let sToH = shoulderWidth / hipWidth
        let bulk = waistWidth / torsoLengthPixels

        let posture = measurePosture(
            points: points,
            lShoulder: lShoulder, rShoulder: rShoulder,
            lHip: lHip, rHip: rHip,
            mask: mask, maskWidth: maskWidth, maskHeight: maskHeight,
            userHeightCm: userHeightCm
        )

        return BodyImageMetrics(
            shoulderToWaistRatio: sToW,
            waistToHipRatio: wToH,
            shoulderToHipRatio: sToH,
            torsoBulk: bulk,
            confidence: jointConfidence,
            classification: classify(shoulderToWaist: sToW, torsoBulk: bulk),
            posture: posture
        )
    }

    // MARK: Posture measurement (all from real joint coordinates)

    private static func measurePosture(
        points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint],
        lShoulder: VNRecognizedPoint, rShoulder: VNRecognizedPoint,
        lHip: VNRecognizedPoint, rHip: VNRecognizedPoint,
        mask: CVPixelBuffer, maskWidth: Double, maskHeight: Double,
        userHeightCm: Double?
    ) -> PostureMetrics {

        // Convert normalized joints to pixel space so angles aren't distorted by aspect ratio.
        func px(_ p: VNRecognizedPoint) -> (x: Double, y: Double) {
            (Double(p.location.x) * maskWidth, Double(p.location.y) * maskHeight)
        }

        let ls = px(lShoulder), rs = px(rShoulder)
        let lh = px(lHip), rh = px(rHip)

        // Shoulder tilt: angle of the shoulder line vs horizontal.
        let shoulderTilt = atan2(ls.y - rs.y, abs(ls.x - rs.x)) * 180 / .pi
        let lowerShoulder: BodySide? = abs(ls.y - rs.y) < 1 ? nil : (ls.y < rs.y ? .left : .right)

        // Pelvic tilt: angle of the hip line vs horizontal.
        let pelvicTilt = atan2(lh.y - rh.y, abs(lh.x - rh.x)) * 180 / .pi

        // Shoulder offset in cm: scale pixels to real height using the person's pixel height.
        var shoulderOffsetCm: Double?
        if let userHeightCm, let personPixelHeight = personHeight(in: mask), personPixelHeight > 10 {
            let cmPerPixel = userHeightCm / personPixelHeight
            shoulderOffsetCm = abs(ls.y - rs.y) * cmPerPixel
        }

        // Lateral head tilt: nose vs mid-shoulder vertical (front view measures side tilt, not forward-head).
        var headTilt: Double?
        if let nose = points[.nose], nose.confidence > 0.3 {
            let n = px(nose)
            let midShoulder = ((ls.x + rs.x) / 2, (ls.y + rs.y) / 2)
            let dx = n.x - midShoulder.0
            let dy = n.y - midShoulder.1
            if abs(dy) > 1 {
                headTilt = abs(atan2(dx, dy) * 180 / .pi)
            }
        }

        // Knee deviation: horizontal distance of each knee from its hip–ankle line, / leg length.
        var kneeDeviation = 0.0
        var ankleAsymmetry = 0.0
        if
            let lKnee = points[.leftKnee], lKnee.confidence > 0.3,
            let rKnee = points[.rightKnee], rKnee.confidence > 0.3,
            let lAnkle = points[.leftAnkle], lAnkle.confidence > 0.3,
            let rAnkle = points[.rightAnkle], rAnkle.confidence > 0.3
        {
            let lk = px(lKnee), rk = px(rKnee)
            let la = px(lAnkle), ra = px(rAnkle)

            func deviation(hip: (x: Double, y: Double), knee: (x: Double, y: Double), ankle: (x: Double, y: Double)) -> Double {
                let legLength = hypot(hip.x - ankle.x, hip.y - ankle.y)
                guard legLength > 1 else { return 0 }
                // Expected knee x if the leg were a straight line at the knee's height.
                let t = (knee.y - hip.y) / (ankle.y - hip.y == 0 ? 1 : ankle.y - hip.y)
                let expectedX = hip.x + (ankle.x - hip.x) * t
                return abs(knee.x - expectedX) / legLength
            }

            kneeDeviation = max(deviation(hip: lh, knee: lk, ankle: la),
                                deviation(hip: rh, knee: rk, ankle: ra))

            // Ankle asymmetry: how unevenly the feet sit relative to the hip center.
            let hipCenterX = (lh.x + rh.x) / 2
            let leftSpread = abs(la.x - hipCenterX)
            let rightSpread = abs(ra.x - hipCenterX)
            let totalSpread = leftSpread + rightSpread
            if totalSpread > 1 {
                ankleAsymmetry = abs(leftSpread - rightSpread) / totalSpread
            }
        }

        // Score: start at 98, subtract weighted penalties, floor at 40.
        var score = 98.0
        score -= min(abs(shoulderTilt), 12) * 2.2
        score -= min(abs(pelvicTilt), 12) * 2.2
        score -= min(headTilt ?? 0, 15) * 0.9
        score -= min(kneeDeviation, 0.15) * 120
        score -= min(ankleAsymmetry, 0.3) * 40
        let finalScore = Int(max(40, min(98, score.rounded())))

        return PostureMetrics(
            shoulderTiltDegrees: shoulderTilt,
            shoulderOffsetCm: shoulderOffsetCm,
            lowerShoulder: lowerShoulder,
            pelvicTiltDegrees: pelvicTilt,
            headTiltDegrees: headTilt,
            kneeDeviation: kneeDeviation,
            ankleAsymmetry: ankleAsymmetry,
            score: finalScore
        )
    }

    /// Person height in mask pixels (topmost to bottommost body row), for cm-per-pixel scaling.
    private static func personHeight(in mask: CVPixelBuffer) -> Double? {
        CVPixelBufferLockBaseAddress(mask, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(mask, .readOnly) }

        guard let base = CVPixelBufferGetBaseAddress(mask) else { return nil }
        let width = CVPixelBufferGetWidth(mask)
        let height = CVPixelBufferGetHeight(mask)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(mask)

        func rowHasBody(_ row: Int) -> Bool {
            let p = base.advanced(by: row * bytesPerRow).assumingMemoryBound(to: UInt8.self)
            for x in stride(from: 0, to: width, by: 4) where p[x] > 127 { return true }
            return false
        }

        var top: Int?
        var bottom: Int?
        for row in stride(from: 0, to: height, by: 2) where rowHasBody(row) { top = row; break }
        for row in stride(from: height - 1, through: 0, by: -2) where rowHasBody(row) { bottom = row; break }

        guard let top, let bottom, bottom > top else { return nil }
        return Double(bottom - top)
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
            classification: .average,
            posture: nil
        )
    }
}
