import SwiftUI
import SwiftData

struct BodyView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]
    @Query(sort: \BodyScanResult.date, order: .reverse) private var scans: [BodyScanResult]

    @State private var tab = 0
    @State private var showScan = false

    private var profile: UserProfile? { profiles.first }
    private var latestScan: BodyScanResult? { scans.first }

    var body: some View {
        ZStack {
            Color.voltBlack.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Text("Your Body")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Color.clear.frame(width: 36, height: 36)
                }

                PillSegmentedControl(options: ["Overview", "Muscle Balance", "Posture"], selection: $tab, dark: true)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        switch tab {
                        case 0: overviewTab
                        case 1: balanceTab
                        default: postureTab
                        }
                    }
                    .padding(.bottom, 20)
                }

                PrimaryButton(title: latestScan == nil ? "Start Body Scan" : "Update Body Scan", icon: "camera.viewfinder", style: .lime) {
                    showScan = true
                }
            }
            .padding(20)
        }
        .fullScreenCover(isPresented: $showScan) {
            BodyScanView()
        }
    }

    // MARK: Overview

    private var overviewTab: some View {
        VStack(spacing: 14) {
            DarkWorkoutCard {
                HStack(spacing: 16) {
                    BodyFigurePlaceholder(dark: true)
                        .frame(width: 90, height: 130)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Estimated body type")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.5))
                        Text(latestScan?.bodyType.rawValue ?? profile?.currentBodyType.rawValue ?? "Athletic")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Color.voltLime)
                        Text("Values are estimates from your scan and profile — not medical measurements.")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }

            HStack(spacing: 12) {
                MetricCard(icon: "percent", title: "Est. Body Fat", value: latestScan.map { String(format: "%.0f%%", $0.bodyFatPercent) } ?? "16%", dark: true)
                MetricCard(icon: "figure.strengthtraining.traditional", title: "Est. Muscle Mass", value: latestScan.map { String(format: "%.1f kg", $0.muscleMassKg) } ?? "38.6 kg", dark: true)
            }
            HStack(spacing: 12) {
                MetricCard(icon: "bolt.fill", title: "Metabolic Age", value: "\(latestScan?.metabolicAge ?? 22)", caption: "Estimated", captionColor: .voltTextMuted, dark: true)
                MetricCard(icon: "target", title: "Dream Body", value: profile?.dreamBody.rawValue ?? "Athletic", dark: true)
            }

            dreamProgressCard
        }
    }

    private var dreamProgressCard: some View {
        let progress = dreamProgress
        return DarkWorkoutCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Progress toward \(profile?.dreamBody.rawValue ?? "Athletic")")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(Int(progress))%")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.voltLime)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.1))
                        Capsule()
                            .fill(Color.voltLime)
                            .frame(width: geo.size.width * CGFloat(progress / 100))
                    }
                }
                .frame(height: 8)
                Text("Based on training consistency, scans and recovery quality.")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
    }

    private var dreamProgress: Double {
        guard let profile else { return 28 }
        if profile.currentBodyType == profile.dreamBody { return 86 }
        let base = 22.0
        let scanBoost = Double(min(scans.count, 6)) * 2
        return min(95, base + scanBoost + Double(profile.level))
    }

    // MARK: Muscle Balance

    private var balanceTab: some View {
        VStack(spacing: 14) {
            if let scan = latestScan {
                DarkWorkoutCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Symmetry Score")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.5))
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text("\(scan.symmetryScore)")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundStyle(Color.voltLime)
                            Text("/ 100")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                }
                distributionCard(scan: scan)
                balanceRow(title: "Strongest", muscles: scan.strongest, color: .voltLime)
                balanceRow(title: "Needs focus", muscles: scan.weakest, color: .voltWarning)
                DarkWorkoutCard {
                    HStack(spacing: 10) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(Color.voltLime)
                        Text("Your plan adds an extra set to \(scan.weakest.map(\.rawValue).joined(separator: " and ")) exercises to close the gap.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
            } else {
                noScanPlaceholder
            }
        }
    }

    private func distributionCard(scan: BodyScanResult) -> some View {
        DarkWorkoutCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Muscle Development")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.5))
                ForEach(MuscleGroup.allCases) { muscle in
                    let score = scan.muscleDistribution[muscle] ?? 60
                    HStack(spacing: 10) {
                        Text(muscle.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.75))
                            .frame(width: 72, alignment: .leading)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.08))
                                Capsule()
                                    .fill(score >= 65 ? Color.voltLime : (score >= 50 ? Color.voltWarning : Color.voltDanger))
                                    .frame(width: geo.size.width * CGFloat(score) / 100)
                            }
                        }
                        .frame(height: 8)
                        Text("\(score)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 26, alignment: .trailing)
                    }
                }
                Text("Estimated from your latest scan — the AI program adds sets where bars are low.")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
    }

    private func balanceRow(title: String, muscles: [MuscleGroup], color: Color) -> some View {
        DarkWorkoutCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.5))
                HStack(spacing: 8) {
                    ForEach(muscles) { muscle in
                        HStack(spacing: 6) {
                            Image(systemName: muscle.icon)
                                .font(.system(size: 12))
                            Text(muscle.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(color.opacity(0.16))
                        .foregroundStyle(color)
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: Posture

    private var postureTab: some View {
        VStack(spacing: 14) {
            if let scan = latestScan {
                DarkWorkoutCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Posture Score")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.5))
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text("\(scan.postureScore)")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundStyle(Color.voltLime)
                            Text("/ 100")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        Text(scan.postureScore >= 88 ? "Solid alignment. Keep training your core and upper back." : "Slight forward-shoulder tendency detected. Face pulls and rows will help.")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                DarkWorkoutCard {
                    VStack(spacing: 12) {
                        BodyFigurePlaceholder(dark: true, symbol: "figure.stand")
                            .frame(height: 200)
                        Text("Posture estimate from your latest scan")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                noScanPlaceholder
            }
        }
    }

    private var noScanPlaceholder: some View {
        DarkWorkoutCard {
            VStack(spacing: 12) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 30))
                    .foregroundStyle(Color.voltLime)
                Text("No scan yet")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Run a body scan to unlock this section.")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }
}
