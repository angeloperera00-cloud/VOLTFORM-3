import SwiftUI
import SwiftData
import AVFoundation
import PhotosUI

struct BodyScanView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]

    @State private var scanning = false
    @State private var scanLineOffset: CGFloat = -140
    @State private var result: BodyScanResult?
    @State private var capturedImage: UIImage?
    @State private var showCamera = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var showNoBodyAlert = false

    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.voltBlack.ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    Spacer()

                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.white.opacity(0.04))
                            .frame(width: 260, height: 360)

                        if let capturedImage {
                            Image(uiImage: capturedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 260, height: 360)
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        } else {
                            BodyFigurePlaceholder(dark: true)
                                .frame(height: 260)
                        }

                        ScanCorners()
                            .stroke(Color.voltLime, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 260, height: 360)

                        if scanning {
                            Rectangle()
                                .fill(
                                    LinearGradient(colors: [Color.voltLime.opacity(0), Color.voltLime.opacity(0.8), Color.voltLime.opacity(0)], startPoint: .leading, endPoint: .trailing)
                                )
                                .frame(width: 240, height: 3)
                                .offset(y: scanLineOffset)
                        }
                    }

                    Text(scanning ? "Scanning..." : (capturedImage == nil ? "Take or choose a photo" : "Stand inside the frame"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.top, 26)
                    Text(scanning ? "Analyzing body type, symmetry and posture." : "Keep your full body visible, arms slightly open.")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.top, 4)

                    Spacer()

                    if capturedImage == nil {
                        VStack(spacing: 10) {
                            if cameraAvailable {
                                PrimaryButton(title: "Open Camera", icon: "camera.fill", style: .lime) {
                                    showCamera = true
                                }
                            }
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                HStack(spacing: 8) {
                                    Image(systemName: "photo.on.rectangle")
                                    Text("Choose from Library")
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    } else {
                        PrimaryButton(title: scanning ? "Scanning..." : "Start Scan", icon: "camera.fill", style: .lime, isDisabled: scanning) {
                            startScan()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraCapturePicker { image in
                    capturedImage = image
                }
                .ignoresSafeArea()
            }
            .onChange(of: selectedItem) { _, item in
                guard let item else { return }
                Task { @MainActor in
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        capturedImage = image
                    }
                    selectedItem = nil
                }
            }
            .alert("No body detected", isPresented: $showNoBodyAlert) {
                Button("Retake") { capturedImage = nil }
                Button("Use anyway") { finalizeScan(metrics: nil) }
            } message: {
                Text("Make sure your full body is visible and well lit, then try again.")
            }
            .navigationDestination(item: $result) { scan in
                ScanResultView(scan: scan) {
                    dismiss()
                }
            }
        }
    }

    private func startScan() {
        guard let capturedImage else { return }

        scanning = true
        scanLineOffset = -160
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            scanLineOffset = 160
        }

        let cgImage = capturedImage.cgImage
        let orientation = CGImagePropertyOrientation(capturedImage.imageOrientation)
        let heightCm = Double(profiles.first?.heightCm ?? 0)

        Task { @MainActor in
            async let analysis = BodyImageAnalyzer.analyze(cgImage: cgImage, orientation: orientation, userHeightCm: heightCm)
            try? await Task.sleep(nanoseconds: 1_000_000_000) // let the scan line play
            let metrics = await analysis

            scanning = false
            if let metrics {
                BodyImageAnalyzer.lastMetrics = metrics
                #if DEBUG
                print("🔍 IN-APP SCAN DEBUG: \(metrics)")
                #endif
                finalizeScan(metrics: metrics)
            } else {
                showNoBodyAlert = true
            }
        }
    }

    private func finalizeScan(metrics: BodyImageMetrics?) {
        guard let profile = profiles.first else { return }
        let scan = BodyAnalysisEngine.analyze(profile: profile)
        if let posture = metrics?.posture {
            PostureStore.record(posture, confidence: metrics?.confidence ?? 0.5)
            scan.postureScore = posture.score
        }
        context.insert(scan)
        profile.currentBodyType = scan.bodyType
        try? context.save()
        result = scan
    }
}

// MARK: - Camera capture

private struct CameraCapturePicker: UIViewControllerRepresentable {
    var onImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraCapturePicker
        init(_ parent: CameraCapturePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImage(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

private extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
