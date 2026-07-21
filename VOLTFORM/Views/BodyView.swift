import SwiftUI
import SwiftData

struct BodyView: View {
    @Query private var profiles: [UserProfile]
    @Query(sort: \BodyScanResult.date, order: .reverse) private var scans: [BodyScanResult]
    @Query(sort: \WorkoutSession.startDate, order: .reverse) private var sessions: [WorkoutSession]

    @State private var tab = 0
    @State private var showScan = false

    private var profile: UserProfile? { profiles.first }
    private var latestScan: BodyScanResult? { scans.first }

    private var recoveryByMuscle: [MuscleGroup: Double] {
        guard let profile else { return [:] }
        let recoveries = RecoveryEngine.allRecoveries(profile: profile, sessions: sessions, scan: latestScan)
        return Dictionary(uniqueKeysWithValues: recoveries.map { ($0.muscle, $0.percentage) })
    }

    var body: some View {
        ZStack {
            Color.voltBlack.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Your Twin")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Button { showScan = true } label: {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.voltLime)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
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
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 20)
        }
        .fullScreenCover(isPresented: $showScan) {
            BodyScanView()
        }
    }

    // MARK: Overview

    private var overviewTab: some View {
        VStack(spacing: 26) {
            HStack(alignment: .top, spacing: 14) {
                VStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.voltDarkCard)
                        AnatomicalBodyFigureView()
                            .padding(9)
                            .scaleEffect(1.04)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 355)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                    MuscleRecoveryLegend()
                }

                VStack(spacing: 10) {
                    bodyStatRow(title: "Body Type", value: latestScan?.bodyType.rawValue ?? profile?.currentBodyType.rawValue ?? "Athletic")
                    bodyStatRow(title: "Body Fat", value: latestScan.map { String(format: "%.0f%%", $0.bodyFatPercent) } ?? "16%")
                    bodyStatRow(title: "Muscle Mass", value: latestScan.map { String(format: "%.1f kg", $0.muscleMassKg) } ?? "38.6 kg")
                    bodyStatRow(title: "Metabolic Age", value: "\(latestScan?.metabolicAge ?? 22)")
                    bodyStatRow(title: "Symmetry", value: "\(latestScan?.symmetryScore ?? 88)/100")
                }
                .frame(width: 128)
            }

            dreamProgressCard
        }
    }

    private func bodyStatRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.voltDarkCard)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var dreamProgressCard: some View {
        let progress = dreamProgress
        return DarkWorkoutCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Progress")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(Int(progress))%")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.voltLime)
                }
                Text("You're making great progress toward \(profile?.dreamBody.rawValue ?? "Athletic"). Keep it up!")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.5))
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.1))
                        Capsule()
                            .fill(Color.voltLime)
                            .frame(width: geo.size.width * CGFloat(progress / 100))
                    }
                }
                .frame(height: 8)
            }
        }
    }

    private var dreamProgress: Double {
        guard let profile else { return 28 }
        let currentType = scans.first?.bodyType ?? profile.currentBodyType
        if currentType == profile.dreamBody { return 86 }
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
                balanceRow(title: "Needs focus", muscles: scan.weakest, color: .voltGold)
                DarkWorkoutCard {
                    HStack(spacing: 10) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(Color.voltLime)
                        Text("Your plan adds an extra set to \(scan.weakest.map(\.rawValue).joined(separator: " and ")) exercises to close the gap")
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
                                    .fill(score >= 65 ? Color.voltLime : (score >= 50 ? Color.voltGold : Color.voltDanger))
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
                Text("Estimated from your latest scan the AI program adds sets where bars are low")
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

    @State private var figureSide = 0

    private var postureTab: some View {
        VStack(spacing: 14) {
            if let scan = latestScan {
                postureScoreCard(scan: scan)
                postureFigureCard
                if let entry = PostureStore.latest {
                    aiConfidenceCard(entry: entry)
                }
            } else {
                noScanPlaceholder
            }
        }
    }

    private func postureScoreCard(scan: BodyScanResult) -> some View {
        let entries = PostureStore.entries
        let today = entries.last?.score ?? scan.postureScore
        let lastWeek = lastWeekScore(entries: entries)
        let best = max(entries.map(\.score).max() ?? today, today)
        let delta = lastWeek.map { today - $0 }

        return DarkWorkoutCard {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("POSTURE SCORE")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(today)")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(Color.voltLime)
                        Text("/100")
                            .font(.system(size: 15))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    Text(postureBadgeText(for: today))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.voltLime)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.voltLime.opacity(0.14))
                        .clipShape(Capsule())
                    Text(postureAdvice)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 7) {
                    postureStatLine("TODAY", today, highlight: true)
                    if let lastWeek { postureStatLine("LAST WEEK", lastWeek) }
                    postureStatLine("BEST", best)
                    PostureSparkline(entries: entries)
                        .frame(height: 44)
                        .padding(.top, 2)
                    if let delta, delta != 0 {
                        Text("\(delta > 0 ? "↑" : "↓") \(abs(delta)) pts this week")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(delta > 0 ? Color.voltLime : Color.voltGold)
                    }
                }
                .frame(width: 128)
            }
        }
    }

    private func postureStatLine(_ title: String, _ value: Int, highlight: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
            Spacer()
            Text("\(value)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(highlight ? Color.voltLime : .white)
        }
    }

    private func postureBadgeText(for score: Int) -> String {
        score >= 85 ? "Great Posture" : (score >= 70 ? "Good Posture" : "Needs Work")
    }

    private var postureAdvice: String {
        guard let e = PostureStore.latest else {
            return "Run a new body scan to unlock detailed posture measurements"
        }
        if abs(e.shoulderTiltDegrees) >= 2.5, let side = e.lowerShoulder {
            return "\(side) shoulder sits slightly lower. Face pulls and rows will help improve alignment"
        }
        if abs(e.pelvicTiltDegrees) >= 2.5 {
            return "Slight pelvic tilt detected. Core and glute work will help level your hips"
        }
        return "Solid alignment. Keep training your core and upper back"
    }

    private func lastWeekScore(entries: [PostureStore.Entry]) -> Int? {
        guard let latest = entries.last else { return nil }
        let cutoff = latest.date.addingTimeInterval(-5 * 24 * 3600)
        return entries.last(where: { $0.date <= cutoff })?.score
    }

    private var postureFigureCard: some View {
        DarkWorkoutCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 6) {
                    ForEach(Array(["Front", "Back", "Side"].enumerated()), id: \.offset) { index, label in
                        Button {
                            figureSide = index
                        } label: {
                            Text(label)
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(figureSide == index ? Color.voltLime : Color.white.opacity(0.08))
                                .foregroundStyle(figureSide == index ? Color.voltOnLime : .white.opacity(0.7))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }

                HStack(alignment: .top, spacing: 14) {
                    PostureFigure(side: figureSide)
                        .frame(width: 180, height: 420)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("KEY INSIGHTS")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))

                        if let e = PostureStore.latest {
                            insightRow(
                                icon: "person.crop.circle",
                                title: "Head Tilt",
                                sub: (e.headTiltDegrees ?? 0) < 4 ? "Upright" : "Slightly tilted",
                                value: "\(Int((e.headTiltDegrees ?? 0).rounded()))°",
                                flagged: (e.headTiltDegrees ?? 0) >= 4
                            )
                            insightRow(
                                icon: "figure.arms.open",
                                title: "Shoulder Offset",
                                sub: e.lowerShoulder.map { "\($0) shoulder slightly lower" } ?? "Level",
                                value: e.shoulderOffsetCm.map { String(format: "%.1f cm", $0) } ?? "\(Int(abs(e.shoulderTiltDegrees).rounded()))°",
                                flagged: abs(e.shoulderTiltDegrees) >= 2.5
                            )
                            insightRow(
                                icon: "circle.grid.cross",
                                title: "Pelvic Tilt",
                                sub: abs(e.pelvicTiltDegrees) < 2.5 ? "Good Alignment" : "Slight tilt",
                                value: "\(Int(abs(e.pelvicTiltDegrees).rounded()))°",
                                flagged: abs(e.pelvicTiltDegrees) >= 2.5
                            )
                            insightRow(
                                icon: "figure.walk",
                                title: "Knee Alignment",
                                sub: e.kneeAlignmentLabel == "Good" ? "Balanced" : "Check stance",
                                value: e.kneeAlignmentLabel,
                                flagged: e.kneeAlignmentLabel != "Good"
                            )
                            insightRow(
                                icon: "shoeprints.fill",
                                title: "Ankle Alignment",
                                sub: e.ankleAlignmentLabel == "Good" ? "Balanced" : "Uneven stance",
                                value: e.ankleAlignmentLabel,
                                flagged: e.ankleAlignmentLabel != "Good"
                            )
                        } else {
                            Text("Run a new scan to see measured insights here.")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func insightRow(icon: String, title: String, sub: String, value: String, flagged: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(flagged ? Color.voltGold : Color.voltLime)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                Text(sub)
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer(minLength: 4)
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(flagged ? Color.voltGold : Color.voltLime)
        }
        .padding(8)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func aiConfidenceCard(entry: PostureStore.Entry) -> some View {
        DarkWorkoutCard {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.voltLime)
                VStack(alignment: .leading, spacing: 6) {
                    Text("AI CONFIDENCE")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.1))
                            Capsule()
                                .fill(Color.voltLime)
                                .frame(width: geo.size.width * CGFloat(entry.confidence))
                        }
                    }
                    .frame(height: 6)
                }
                Text("\(Int(entry.confidence * 100))%")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
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

// MARK: - Posture components

private struct PostureSparkline: View {
    let entries: [PostureStore.Entry]

    var body: some View {
        let scores = entries.suffix(8).map { Double($0.score) }
        GeometryReader { geo in
            if scores.count >= 2, let minS = scores.min(), let maxS = scores.max() {
                let range = Swift.max(maxS - minS, 1)
                let stepX = geo.size.width / CGFloat(scores.count - 1)
                let points = scores.enumerated().map { i, s in
                    CGPoint(
                        x: CGFloat(i) * stepX,
                        y: 5 + (geo.size.height - 10) * (1 - CGFloat((s - minS) / range))
                    )
                }
                ZStack {
                    Path { p in p.addLines(points) }
                        .stroke(Color.voltLime, lineWidth: 2)
                    ForEach(points.indices, id: \.self) { i in
                        Circle()
                            .fill(Color.voltLime)
                            .frame(width: 5, height: 5)
                            .position(points[i])
                    }
                }
            } else {
                Text("More scans build your trend")
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.35))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

private struct PostureFigure: View {
    let side: Int   // 0 front, 1 back, 2 side

    // All positions measured from the actual asset pixels — do not eyeball-edit.
    private static let pairMarkers: [[(CGFloat, CGFloat)]] = [
        [ // front
            (0.26, 0.185), (0.71, 0.185),    // shoulders
            (0.39, 0.475), (0.59, 0.475),    // hips
            (0.30, 0.705), (0.69, 0.705),    // knees
            (0.27, 0.945), (0.76, 0.945)     // ankles
        ],
        [ // back
            (0.31, 0.185), (0.70, 0.185),
            (0.39, 0.475), (0.59, 0.475),
            (0.30, 0.705), (0.68, 0.705),
            (0.24, 0.945), (0.75, 0.945)
        ]
    ]

    // Side view: single plumb-line markers (ear, shoulder, hip, knee, ankle)
    private static let sideMarkers: [(CGFloat, CGFloat)] = [
        (0.58, 0.08), (0.43, 0.185), (0.48, 0.47), (0.46, 0.70), (0.51, 0.945)
    ]

    private var imageName: String {
        ["PostureBodyFront", "PostureBodyBack", "PostureBodySide"][side]
    }

    var body: some View {
        HStack(spacing: 8) {
            RulerTicks()
                .frame(width: 10)

            GeometryReader { geo in
                ZStack {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width, height: geo.size.height)

                    if side == 2 {
                        // Plumb line through the side profile
                        Path { p in
                            p.move(to: CGPoint(x: 0.47 * geo.size.width, y: 0.05 * geo.size.height))
                            p.addLine(to: CGPoint(x: 0.47 * geo.size.width, y: 0.97 * geo.size.height))
                        }
                        .stroke(Color.voltLime.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))

                        ForEach(Self.sideMarkers.indices, id: \.self) { i in
                            Circle()
                                .fill(Color.voltLime)
                                .frame(width: 9, height: 9)
                                .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 1))
                                .position(x: Self.sideMarkers[i].0 * geo.size.width, y: Self.sideMarkers[i].1 * geo.size.height)
                        }
                    } else {
                        let markers = Self.pairMarkers[side]

                        Path { p in
                            p.move(to: CGPoint(x: 0.49 * geo.size.width, y: 0.06 * geo.size.height))
                            p.addLine(to: CGPoint(x: 0.49 * geo.size.width, y: 0.97 * geo.size.height))
                        }
                        .stroke(Color.voltLime.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))

                        ForEach([0, 2, 4, 6], id: \.self) { i in
                            Path { p in
                                p.move(to: CGPoint(x: markers[i].0 * geo.size.width, y: markers[i].1 * geo.size.height))
                                p.addLine(to: CGPoint(x: markers[i + 1].0 * geo.size.width, y: markers[i + 1].1 * geo.size.height))
                            }
                            .stroke(Color.voltLime.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        }

                        ForEach(markers.indices, id: \.self) { i in
                            Circle()
                                .fill(Color.voltLime)
                                .frame(width: 9, height: 9)
                                .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 1))
                                .position(x: markers[i].0 * geo.size.width, y: markers[i].1 * geo.size.height)
                        }
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: side)
    }
}

private struct RulerTicks: View {
    var body: some View {
        GeometryReader { geo in
            let count = 28
            ForEach(0..<count, id: \.self) { i in
                Rectangle()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: i % 4 == 0 ? 9 : 5, height: 1)
                    .position(x: 5, y: geo.size.height * CGFloat(i) / CGFloat(count - 1))
            }
        }
    }
}

#Preview {
    BodyView()
        .modelContainer(PreviewSupport.container)
}
