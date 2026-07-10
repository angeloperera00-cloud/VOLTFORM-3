import SwiftUI
import SwiftData
import AVFoundation

struct BodyScanView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]

    @State private var scanning = false
    @State private var scanLineOffset: CGFloat = -140
    @State private var result: BodyScanResult?

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
                        // Camera preview placeholder — swap in an AVCaptureVideoPreviewLayer
                        // wrapper here when wiring the real Vision pipeline.
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.white.opacity(0.04))
                            .frame(width: 260, height: 360)

                        BodyFigurePlaceholder(dark: true)
                            .frame(height: 260)

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

                    Text(scanning ? "Scanning..." : "Stand inside the frame")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.top, 26)
                    Text(scanning ? "Analyzing body type, symmetry and posture." : "Keep your full body visible, arms slightly open.")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.top, 4)

                    Spacer()

                    PrimaryButton(title: scanning ? "Scanning..." : "Start Scan", icon: "camera.fill", style: .lime, isDisabled: scanning) {
                        startScan()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
            }
            .navigationDestination(item: $result) { scan in
                ScanResultView(scan: scan) {
                    dismiss()
                }
            }
        }
    }

    private func startScan() {
        AVCaptureDevice.requestAccess(for: .video) { _ in
            // The mock engine runs either way; the permission request keeps the
            // flow identical once a real camera pipeline is dropped in.
        }

        scanning = true
        scanLineOffset = -160
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            scanLineOffset = 160
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            guard let profile = profiles.first else { return }
            let scan = BodyAnalysisEngine.analyze(profile: profile)
            context.insert(scan)
            profile.currentBodyType = scan.bodyType
            try? context.save()
            scanning = false
            result = scan
        }
    }
}

