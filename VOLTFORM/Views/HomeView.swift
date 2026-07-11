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
    @State private var selectedExerciseIndex: Int = 0

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
            VStack(alignment: .leading, spacing: 20) {
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
            Button { switchTab(.profile) } label: {
                ZStack {
                    Circle().fill(Color.voltLime)
                    Text(String(profile?.firstName.prefix(1) ?? "A"))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.voltOnLime)
                }
                .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
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
        VStack(alignment: .leading, spacing: 14) {
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

            HStack(alignment: .top, spacing: 14) {
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
                Spacer()
                BodyFigurePlaceholder(dark: false)
                    .frame(width: 74, height: 100)
            }

            exercisePager(exercises: workout.exercises)

            PrimaryButton(title: "Start Workout", icon: "play.fill", style: .lime) {
                activeSession = StorageService.startSession(from: workout, context: context)
            }
        }
        .padding(20)
        .background(Color.voltCard)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 6)
    }

    private func exercisePager(exercises: [PlannedExercise]) -> some View {
        VStack(spacing: 8) {
            TabView(selection: $selectedExerciseIndex) {
                ForEach(Array(exercises.enumerated()), id: \.offset) { index, exercise in
                    exerciseMiniCard(exercise: exercise)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 62)

            exercisePageDots(count: exercises.count)
        }
        .onAppear {
            if selectedExerciseIndex >= exercises.count {
                selectedExerciseIndex = 0
            }
        }
    }

    private func exerciseMiniCard(exercise: PlannedExercise) -> some View {
        HStack(spacing: 12) {
            Image(systemName: exercise.muscle.icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.voltTextDark)
                .frame(width: 36, height: 36)
                .background(Color.voltSoftGray)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.voltTextDark)
                Text("\(exercise.sets) sets × \(exercise.repRange)")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.voltTextMuted)
            }
            Spacer()
        }
        .padding(10)
        .background(Color.voltSoftGray.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func exercisePageDots(count: Int) -> some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                let isActive: Bool = index == selectedExerciseIndex
                exercisePageDot(isActive: isActive)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func exercisePageDot(isActive: Bool) -> some View {
        let dotWidth: CGFloat = isActive ? 16 : 6
        let dotColor: Color = isActive ? Color.voltLimeDeep : Color.voltTextMuted.opacity(0.25)
        return Capsule()
            .fill(dotColor)
            .frame(width: dotWidth, height: 6)
            .animation(.easeInOut(duration: 0.2), value: isActive)
    }

    private func cardioCard(type: CardioType, minutes: Int, label: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
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
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(type.rawValue)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Color.voltTextDark)
                    Text("\(minutes) min · Zone 2 effort")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.voltTextMuted)
                    Text("Your AI program scheduled cardio today lifting muscles get a chance to recover.")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.voltTextDark)
                }
                Spacer()
                Image(systemName: type.icon)
                    .font(.system(size: 44))
                    .foregroundStyle(Color.voltLimeDeep)
                    .frame(width: 74, height: 100)
            }
        }
        .padding(20)
        .background(Color.voltCard)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 6)
    }

    private func restCard(label: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
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
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recovery Day")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Color.voltTextDark)
                    Text("Muscle grows while you rest — your AI program planned this on purpose.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.voltTextMuted)
                }
                Spacer()
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.voltLimeDeep)
                    .frame(width: 74, height: 100)
            }
        }
        .padding(20)
        .background(Color.voltCard)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 6)
    }

    private func overviewGrid(profile: UserProfile) -> some View {
        let recoveries = RecoveryEngine.allRecoveries(profile: profile, sessions: sessions, scan: scans.first)
        let overall = RecoveryEngine.overallRecovery(recoveries)
        let sleepAvg = RecoveryEngine.sleepThreeDayAverage(checkIns: checkIns, fallback: profile.sleepAverage.hours)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Overview")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.voltTextDark)
                Spacer()
                Button("See all") { switchTab(.recovery) }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.voltTextMuted)
            }

            HStack(spacing: 12) {
                Button { switchTab(.recovery) } label: {
                    MetricCard(
                        icon: "bolt.heart",
                        title: "Recovery",
                        value: "\(Int(overall.rounded()))%",
                        caption: overall >= 70 ? "Good" : (overall >= 45 ? "Average" : "Low"),
                        captionColor: overall >= 70 ? .voltLimeDeep : (overall >= 45 ? .voltWarning : .voltDanger)
                    )
                }
                .buttonStyle(.plain)
                MetricCard(icon: "moon.fill", title: "Sleep", value: VoltFormat.hoursMinutes(sleepAvg), caption: "3-day average")
            }
            HStack(spacing: 12) {
                MetricCard(icon: "waveform.path.ecg", title: "Soreness", value: profile.soreness.rawValue, caption: profile.soreness == .low ? "Feeling fresh" : "Take it easy", captionColor: profile.soreness == .high ? .voltDanger : .voltLimeDeep)
                MetricCard(icon: "drop.fill", title: "Hydration", value: profile.hydration.rawValue, caption: profile.hydration == .good ? "Keep it up" : "Drink more", captionColor: profile.hydration == .low ? .voltWarning : .voltLimeDeep)
            }
        }
    }
}

#Preview {
    HomeView(switchTab: { _ in })
        .modelContainer(PreviewSupport.container)
}
