import SwiftUI
import SwiftData

struct ScanResultView: View {
    @Query(sort: \BodyScanResult.date, order: .reverse) private var scans: [BodyScanResult]

    let scan: BodyScanResult
    let onDone: () -> Void

    var body: some View {
        ZStack {
            Color.voltBlack.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    Text("Scan Complete")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.top, 16)
                    Text(scan.date.formatted(.dateTime.weekday(.wide).day().month().hour().minute()))
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.5))

                    DarkWorkoutCard {
                        HStack(spacing: 16) {
                            BodyFigurePlaceholder(dark: true)
                                .frame(width: 80, height: 116)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Estimated body type")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.white.opacity(0.5))
                                Text(scan.bodyType.rawValue)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(Color.voltLime)
                            }
                            Spacer()
                        }
                    }

                    HStack(spacing: 12) {
                        MetricCard(icon: "arrow.left.arrow.right", title: "Symmetry", value: "\(scan.symmetryScore)/100", dark: true)
                        MetricCard(icon: "figure.stand", title: "Posture", value: "\(scan.postureScore)/100", dark: true)
                    }
                    HStack(spacing: 12) {
                        MetricCard(icon: "percent", title: "Est. Body Fat", value: String(format: "%.0f%%", scan.bodyFatPercent), dark: true)
                        MetricCard(icon: "figure.strengthtraining.traditional", title: "Est. Lean Mass", value: String(format: "%.1f kg", scan.muscleMassKg), dark: true)
                    }

                    DarkWorkoutCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Suggested focus")
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.5))
                            HStack(spacing: 8) {
                                ForEach(scan.suggestedFocus) { muscle in
                                    Text(muscle.rawValue)
                                        .font(.system(size: 13, weight: .semibold))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.voltLime)
                                        .foregroundStyle(Color.voltOnLime)
                                        .clipShape(Capsule())
                                }
                            }
                            Text("Your workout plan now adds volume to these muscles.")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.45))
                        }
                    }

                    if scans.count > 1 {
                        scanHistory
                    }

                    PrimaryButton(title: "Done", style: .lime) { onDone() }
                        .padding(.top, 4)
                }
                .padding(20)
            }
        }
        .navigationBarBackButtonHidden(false)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var scanHistory: some View {
        DarkWorkoutCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Scan History")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                ForEach(scans.prefix(5)) { item in
                    HStack {
                        Text(item.date.formatted(.dateTime.day().month().year()))
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.6))
                        Spacer()
                        Text(item.bodyType.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.voltLime)
                        Text(String(format: "%.0f%% BF", item.bodyFatPercent))
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
        }
    }
}

#Preview {
    ScanResultView(scan: PreviewSupport.sampleScan, onDone: {})
        .modelContainer(PreviewSupport.container)
}
