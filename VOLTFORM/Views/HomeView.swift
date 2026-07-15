import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]
    @Query(sort: \WorkoutSession.startDate, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \DailyRecoveryCheckIn.date, order: .reverse) private var checkIns: [DailyRecoveryCheckIn]
    @Query(sort: \BodyScanResult.date, order: .reverse) private var scans: [BodyScanResult]

    let switchTab: (VoltTab) -> Void

    @State private var activeSession: WorkoutSession?
    @State private var showSleepAdjust = false
    @State private var showHydrationAdjust = false
    @State private var showSorenessAdjust = false

    private var profile: UserProfile? { profiles.first }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<18: return "Good afternoon"
        default: return "Good evening"
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 26) {
                header
                if let profile {
                    todaysPlanCard(profile: profile)
                    overviewGrid(profile: profile)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color.voltOffWhite)
        .fullScreenCover(item: $activeSession) { session in
            WorkoutSessionView(session: session)
        }
        .sheet(isPresented: $showSleepAdjust) {
            SleepAdjustSheet()
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showHydrationAdjust) {
            HydrationAdjustSheet()
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showSorenessAdjust) {
            SorenessAdjustSheet()
                .presentationDetents([.medium])
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(greeting), \(profile?.firstName ?? "there") 👋")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.voltTextDark)
                Text("Let's check your body today.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.voltTextMuted)
            }
            Spacer()
        }
    }

    private func todaysPlan(profile: UserProfile) -> DayPlan {
        let recoveries = RecoveryEngine.allRecoveries(profile: profile, sessions: sessions, scan: scans.first)
        return AIProgramEngine.todaysPlan(profile: profile, scan: scans.first, recoveries: recoveries, sessions: sessions)
    }

    @ViewBuilder
    private func todaysPlanCard(profile: UserProfile) -> some View {
        switch todaysPlan(profile: profile) {
        case .lift(let workout):
            liftCard(workout: workout, label: "Today's Plan")
        case .cardio(let type, let minutes):
            cardioCard(type: type, minutes: minutes, label: "Today's Plan")
        case .rest:
            restCard(label: "Today's Plan")
        }
    }

    private func liftCard(workout: PlannedWorkout, label: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.voltTextMuted)
                Spacer()
                Text(workout.tag)
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.voltLime)
                    .foregroundStyle(Color.voltOnLime)
                    .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(workout.name)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color.voltTextDark)
                Text("\(workout.durationMinutes) min · \(workout.exercises.count) Exercises")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.voltTextMuted)
                Text(workout.muscles.map(\.rawValue).joined(separator: " · "))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.voltLimeDeep)
            }

            Spacer(minLength: 1)

            HStack {
                PrimaryButton(title: "Start Workout", icon: "play.fill", style: .lime) {
                    activeSession = StorageService.startSession(from: workout, context: context)
                }
                .frame(width: 240)

                Spacer()
            }
        }
        .padding(20)
        .frame(height: 205)
        .background(alignment: .bottom) {
            Image("TodaysPlanAthlete")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: 190)
                .scaleEffect(1.46)
                .offset(x: -33, y: -28)
                .clipped()
                .allowsHitTesting(false)
        }
        .background(Color.voltCard)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 6)
    }

    private func cardioCard(type: CardioType, minutes: Int, label: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.voltTextMuted)
                Spacer()
                Text("Cardio")
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.voltLime)
                    .foregroundStyle(Color.voltOnLime)
                    .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(type.rawValue)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color.voltTextDark)
                Text("\(minutes) min · Zone 2 effort")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.voltTextMuted)
                Text("Your AI program scheduled cardio today.Lifting muscles get a chance to recover.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.voltTextDark)
            }

            Spacer(minLength: 1)
        }
        .padding(20)
        .frame(height: 205)
        .background(alignment: .bottom) {
            Image("TodaysPlanAthlete")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: 190)
                .scaleEffect(1.46)
                .offset(x: -33, y: -28)
                .clipped()
                .allowsHitTesting(false)
        }
        .background(Color.voltCard)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 6)
    }

    private func restCard(label: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.voltTextMuted)
                Spacer()
                Text("Rest Day")
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.voltLime)
                    .foregroundStyle(Color.voltOnLime)
                    .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Recovery Day")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color.voltTextDark)
                Text("Muscle grows while you rest. Your AI program planned this on purpose.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.voltTextMuted)
            }

            Spacer(minLength: 1)
        }
        .padding(20)
        .frame(height: 205)
        .background(alignment: .bottom) {
            Image("TodaysPlanAthlete")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: 190)
                .scaleEffect(1.46)
                .offset(x: -33, y: -28)
                .clipped()
                .allowsHitTesting(false)
        }
        .background(Color.voltCard)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 6)
    }

    private func overviewGrid(profile: UserProfile) -> some View {
        let recoveries = RecoveryEngine.allRecoveries(profile: profile, sessions: sessions, scan: scans.first)
        let overall = RecoveryEngine.overallRecovery(recoveries)
        let sleepAvg = RecoveryEngine.sleepThreeDayAverage(checkIns: checkIns, fallback: profile.sleepAverage.hours)

        let sleepImpact = recoveryImpact(profile.sleepAverage.recoveryMultiplier)
        let hydrationImpact = recoveryImpact(profile.hydration.recoveryMultiplier)
        let sorenessImpact = recoveryImpact(profile.soreness.recoveryMultiplier)

        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Overview")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.voltTextDark)
                Spacer()
                Button("See all") { switchTab(.recovery) }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.voltTextMuted)
            }

            HStack(spacing: 14) {
                Button { switchTab(.recovery) } label: {
                    MetricCard(
                        icon: "bolt.heart",
                        title: "Recovery",
                        value: "\(Int(overall.rounded()))%",
                        caption: recoveryLimiterCaption(profile: profile),
                        captionColor: overall >= 70 ? .voltLimeDeep : (overall >= 45 ? .voltWarning : .voltDanger)
                    )
                }
                .buttonStyle(.plain)
                Button { showSleepAdjust = true } label: {
                    MetricCard(icon: "moon.fill", title: "Sleep", value: VoltFormat.hoursMinutes(sleepAvg), caption: sleepImpact.text, captionColor: sleepImpact.color)
                }
                .buttonStyle(.plain)
            }
            HStack(spacing: 14) {
                Button { showSorenessAdjust = true } label: {
                    MetricCard(icon: "waveform.path.ecg", title: "Soreness", value: profile.soreness.rawValue, caption: sorenessImpact.text, captionColor: sorenessImpact.color)
                }
                .buttonStyle(.plain)
                Button { showHydrationAdjust = true } label: {
                    MetricCard(icon: "drop.fill", title: "Hydration", value: profile.hydration.rawValue, caption: hydrationImpact.text, captionColor: hydrationImpact.color)
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// Translates a recovery multiplier (from SleepAverage/HydrationLevel/
    /// SorenessLevel — the same values RecoveryEngine actually multiplies
    /// into every "ready by" calculation) into a plain-language caption, so
    /// what's shown here always matches what's driving the real numbers.
    private func recoveryImpact(_ multiplier: Double) -> (text: String, color: Color) {
        let percent = Int(((multiplier - 1.0) * 100).rounded())
        if percent > 0 { return ("Slows recovery \(percent)%", .voltWarning) }
        if percent < 0 { return ("Speeds recovery \(-percent)%", .voltLimeDeep) }
        return ("Optimal for recovery", .voltLimeDeep)
    }

    /// Names whichever factor is currently doing the most damage to
    /// recovery, so the Recovery card itself explains *why* the percentage
    /// is what it is instead of just restating it.
    private func recoveryLimiterCaption(profile: UserProfile) -> String {
        let factors: [(name: String, multiplier: Double)] = [
            ("Sleep", profile.sleepAverage.recoveryMultiplier),
            ("Hydration", profile.hydration.recoveryMultiplier),
            ("Soreness", profile.soreness.recoveryMultiplier)
        ]
        if let worst = factors.max(by: { $0.multiplier < $1.multiplier }), worst.multiplier > 1.0 {
            return "\(worst.name) is holding you back"
        }
        return "All factors optimal"
    }
}

// MARK: - Sleep adjustment sheet

private struct SleepAdjustSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]
    @Query(sort: \DailyRecoveryCheckIn.date, order: .reverse) private var checkIns: [DailyRecoveryCheckIn]

    @State private var sleepHours: Double = 7.5

    private var profile: UserProfile? { profiles.first }

    /// Maps raw hours to the SleepAverage bucket the recovery engine's
    /// multiplier actually reads from.
    private var derivedSleepAverage: SleepAverage {
        if sleepHours >= 8.25 { return .eightPlus }
        if sleepHours >= 6.5 { return .sevenToEight }
        return .fiveToSix
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Adjust Sleep")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(Color.voltTextDark)
                Text("How many hours did you sleep last night?")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.voltTextMuted)
            }

            VStack(spacing: 10) {
                Text(VoltFormat.hoursMinutes(sleepHours))
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(Color.voltLimeDeep)
                Slider(value: $sleepHours, in: 3...12, step: 0.25)
                    .tint(Color.voltLime)
                Text(sleepHours < 6.5 ? "Below 6.5h slows muscle recovery" : "Good range for recovery")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(sleepHours < 6.5 ? Color.voltWarning : Color.voltLimeDeep)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(Color.voltCard)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            PrimaryButton(title: "Save", style: .lime) {
                let checkIn = DailyRecoveryCheckIn(
                    date: .now,
                    sleepHours: sleepHours,
                    hydration: profile?.hydration ?? .good,
                    soreness: profile?.soreness ?? .low,
                    waterGlasses: checkIns.first?.waterGlasses ?? 6
                )
                context.insert(checkIn)
                profile?.sleepAverage = derivedSleepAverage
                try? context.save()
                dismiss()
            }
        }
        .padding(24)
        .presentationBackground(Color.voltOffWhite)
        .onAppear {
            if let latest = checkIns.first {
                sleepHours = latest.sleepHours
            }
        }
    }
}

// MARK: - Hydration adjustment sheet

private struct HydrationAdjustSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]
    @Query(sort: \DailyRecoveryCheckIn.date, order: .reverse) private var checkIns: [DailyRecoveryCheckIn]

    @State private var glasses: Int = 6

    private var profile: UserProfile? { profiles.first }

    /// Maps a glasses-of-water count to the app's HydrationLevel bucket,
    /// which is what the recovery engine actually uses in its calculations.
    private var derivedLevel: HydrationLevel {
        if glasses >= 8 { return .good }
        if glasses >= 4 { return .moderate }
        return .low
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Adjust Hydration")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(Color.voltTextDark)
                Text("How many glasses of water have you had today?")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.voltTextMuted)
            }

            VStack(spacing: 16) {
                HStack(spacing: 24) {
                    Button {
                        if glasses > 0 { glasses -= 1 }
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.voltTextDark)
                            .frame(width: 44, height: 44)
                            .background(Color.voltSoftGray)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    VStack(spacing: 2) {
                        Text("\(glasses)")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(Color.voltLimeDeep)
                        Text(glasses == 1 ? "glass" : "glasses")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.voltTextMuted)
                    }
                    .frame(minWidth: 90)

                    Button {
                        if glasses < 20 { glasses += 1 }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.voltTextDark)
                            .frame(width: 44, height: 44)
                            .background(Color.voltSoftGray)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                Text("\(derivedLevel.rawValue) hydration")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.voltLimeDeep)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(Color.voltCard)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            PrimaryButton(title: "Save", style: .lime) {
                let checkIn = DailyRecoveryCheckIn(
                    date: .now,
                    sleepHours: checkIns.first?.sleepHours ?? profile?.sleepAverage.hours ?? 7.5,
                    hydration: derivedLevel,
                    soreness: profile?.soreness ?? .low,
                    waterGlasses: glasses
                )
                context.insert(checkIn)
                profile?.hydration = derivedLevel
                try? context.save()
                dismiss()
            }
        }
        .padding(24)
        .presentationBackground(Color.voltOffWhite)
        .onAppear {
            if let latest = checkIns.first {
                glasses = latest.waterGlasses
            }
        }
    }
}

// MARK: - Soreness adjustment sheet

private struct SorenessAdjustSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]
    @Query(sort: \DailyRecoveryCheckIn.date, order: .reverse) private var checkIns: [DailyRecoveryCheckIn]

    @State private var soreness: SorenessLevel = .low

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Adjust Soreness")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(Color.voltTextDark)
                Text("How sore are your muscles feeling right now?")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.voltTextMuted)
            }

            VStack(spacing: 12) {
                ForEach(SorenessLevel.allCases, id: \.self) { level in
                    Button {
                        soreness = level
                    } label: {
                        HStack {
                            Text(level.rawValue)
                                .font(.system(size: 15, weight: .semibold))
                            Spacer()
                            if soreness == level {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                            }
                        }
                        .padding(16)
                        .background(soreness == level ? Color.voltLime : Color.voltCard)
                        .foregroundStyle(soreness == level ? Color.voltOnLime : Color.voltTextDark)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            PrimaryButton(title: "Save", style: .lime) {
                let checkIn = DailyRecoveryCheckIn(
                    date: .now,
                    sleepHours: checkIns.first?.sleepHours ?? profile?.sleepAverage.hours ?? 7.5,
                    hydration: profile?.hydration ?? .good,
                    soreness: soreness,
                    waterGlasses: checkIns.first?.waterGlasses ?? 6
                )
                context.insert(checkIn)
                profile?.soreness = soreness
                try? context.save()
                dismiss()
            }
        }
        .padding(24)
        .presentationBackground(Color.voltOffWhite)
        .onAppear {
            soreness = profile?.soreness ?? .low
        }
    }
}

#Preview {
    HomeView(switchTab: { _ in })
        .modelContainer(PreviewSupport.container)
}
