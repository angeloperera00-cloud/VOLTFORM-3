import SwiftUI
import SwiftData
import Combine

struct WorkoutSessionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]
    @Query(sort: \WorkoutSession.startDate, order: .reverse) private var allSessions: [WorkoutSession]
    @Query(sort: \BodyScanResult.date, order: .reverse) private var scans: [BodyScanResult]

    let session: WorkoutSession

    @State private var exerciseIndex = 0
    @State private var weight: Double = 40
    @State private var reps: Int = 10
    @State private var suggestionApplied = false
    @State private var overloadHint: String? = nil
    @State private var restSecondsRemaining = 0
    @State private var isResting = false
    @State private var showCompleted = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var orderedExercises: [ExerciseLog] {
        session.exercises.sorted { $0.orderIndex < $1.orderIndex }
    }

    private var currentExercise: ExerciseLog? {
        guard exerciseIndex < orderedExercises.count else { return nil }
        return orderedExercises[exerciseIndex]
    }

    /// Personalized rest window from the AI engine's goal-based prescription
    /// (e.g. ~150s for strength, ~90s for hypertrophy, ~60s for fat loss),
    /// instead of one fixed value for every user.
    private var baseRestSeconds: Int {
        AIProgramEngine.restSeconds(for: profiles.first?.goal ?? .buildMuscle)
    }

    /// Between-exercise transitions get a slightly longer breather than
    /// between-set rest within the same exercise.
    private var betweenExerciseRestSeconds: Int {
        baseRestSeconds + 15
    }

    var body: some View {
        ZStack {
            Color.voltBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if let exercise = currentExercise {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 18) {
                            exerciseCard(exercise)
                            if isResting {
                                restCard
                            } else {
                                selectors
                                if let overloadHint {
                                    Text(overloadHint)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                            }
                        }
                        .padding(20)
                    }

                    footer(exercise)
                } else {
                    Spacer()
                }
            }
        }
        .onAppear { applySuggestedWeight() }
        .onChange(of: exerciseIndex) { _, _ in applySuggestedWeight() }
        .onReceive(timer) { _ in
            guard isResting else { return }
            if restSecondsRemaining > 1 {
                restSecondsRemaining -= 1
            } else {
                isResting = false
            }
        }
        .fullScreenCover(isPresented: $showCompleted) {
            WorkoutCompletedView(session: session) {
                dismiss()
            }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Button {
                // Abandoning an untouched session shouldn't pollute history or recovery.
                if session.totalCompletedSets == 0 {
                    context.delete(session)
                    try? context.save()
                }
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 2) {
                Text(session.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                Text("Exercise \(min(exerciseIndex + 1, orderedExercises.count)) of \(orderedExercises.count)")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Button {
                finishSession()
            } label: {
                Text("Finish")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.voltLime)
            }
            .buttonStyle(.plain)
            .frame(width: 48)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: Exercise card

    private func exerciseCard(_ exercise: ExerciseLog) -> some View {
        DarkWorkoutCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.name)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                        Text("\(exercise.muscle.rawValue) · \(exercise.repRange)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.voltLime)
                    }
                    Spacer()
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 160)
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 56))
                        .foregroundStyle(Color.voltLime.opacity(0.7))
                }

                HStack(spacing: 8) {
                    ForEach(0..<exercise.plannedSets, id: \.self) { setIndex in
                        Capsule()
                            .fill(setIndex < exercise.completedSets ? Color.voltLime : Color.white.opacity(0.12))
                            .frame(height: 6)
                    }
                }

                Text("Set \(min(exercise.completedSets + 1, exercise.plannedSets)) of \(exercise.plannedSets)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    // MARK: Selectors

    private var selectors: some View {
        HStack(spacing: 14) {
            stepper(title: "Weight", value: String(format: weight.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f kg" : "%.1f kg", weight)) {
                weight = max(0, weight - 2.5)
            } up: {
                weight += 2.5
            }
            stepper(title: "Reps", value: "\(reps)") {
                reps = max(1, reps - 1)
            } up: {
                reps += 1
            }
        }
    }

    private func stepper(title: String, value: String, down: @escaping () -> Void, up: @escaping () -> Void) -> some View {
        DarkWorkoutCard {
            VStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                Text(value)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                HStack(spacing: 10) {
                    roundButton("minus", action: down)
                    roundButton("plus", action: up)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func roundButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Rest

    private var restCard: some View {
        DarkWorkoutCard {
            VStack(spacing: 12) {
                Text("Rest")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.voltLime)
                Text("0:\(String(format: "%02d", restSecondsRemaining))")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                Button("Skip Rest") {
                    isResting = false
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: Footer

    private func footer(_ exercise: ExerciseLog) -> some View {
        VStack(spacing: 0) {
            PrimaryButton(
                title: primaryTitle(exercise),
                icon: exercise.isDone ? "arrow.right" : "checkmark",
                style: .lime,
                isDisabled: isResting
            ) {
                primaryAction(exercise)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }

    private func primaryTitle(_ exercise: ExerciseLog) -> String {
        if exercise.isDone {
            return exerciseIndex == orderedExercises.count - 1 ? "Finish Workout" : "Next Exercise"
        }
        return "Mark Set Complete"
    }

    private func primaryAction(_ exercise: ExerciseLog) {
        if exercise.isDone {
            if exerciseIndex == orderedExercises.count - 1 {
                finishSession()
            } else {
                exerciseIndex += 1
                startRest(seconds: betweenExerciseRestSeconds)
            }
            return
        }

        let set = SetLog(index: exercise.completedSets + 1, reps: reps, weight: weight)
        context.insert(set)
        set.exercise = exercise
        exercise.completedSets += 1
        try? context.save()

        if exercise.isDone {
            if exerciseIndex == orderedExercises.count - 1 {
                finishSession()
            } else {
                exerciseIndex += 1
                startRest(seconds: betweenExerciseRestSeconds)
            }
        } else {
            startRest(seconds: baseRestSeconds)
        }
    }

    private func startRest(seconds: Int) {
        restSecondsRemaining = seconds
        isResting = true
    }

    /// Progressive overload: prefill the working weight from the user's own
    /// history (+2.5 kg on compounds when the last session hit every set).
    private func applySuggestedWeight() {
        guard let exercise = currentExercise else { return }
        if let suggested = AIProgramEngine.suggestedWeight(for: exercise.name, in: allSessions.filter { $0 !== session }) {
            weight = suggested
            overloadHint = "AI suggests \(String(format: suggested.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", suggested)) kg based on your last session"
        } else {
            overloadHint = nil
        }
    }

    private func finishSession() {
        guard session.totalCompletedSets > 0 else {
            context.delete(session)
            try? context.save()
            dismiss()
            return
        }

        session.endDate = .now
        session.durationMinutes = max(1, Int(Date.now.timeIntervalSince(session.startDate) / 60))
        session.isCompleted = true

        if let profile = profiles.first {
            let gained = 50 + Int(session.totalVolumeKg / 10)
            profile.xp += gained
            profile.level = 1 + profile.xp / 2500

            // Schedule "muscle ready" notifications from the personalized forecast.
            for muscle in session.muscles {
                let needed = RecoveryEngine.neededHours(for: muscle, profile: profile, session: session, scan: scans.first)
                let readyBy = (session.endDate ?? .now).addingTimeInterval(needed * 3600)
                NotificationService.scheduleMuscleReadyReminder(muscle: muscle, readyBy: readyBy)
                context.insert(RecoverySnapshot(date: .now, muscle: muscle, percentage: 0))
            }
        }

        try? context.save()
        showCompleted = true
    }
}

#Preview {
    WorkoutSessionView(session: PreviewSupport.sampleSession)
        .modelContainer(PreviewSupport.container)
}
