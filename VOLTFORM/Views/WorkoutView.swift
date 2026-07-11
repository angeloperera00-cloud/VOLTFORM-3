import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]
    @Query(sort: \WorkoutSession.startDate, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \BodyScanResult.date, order: .reverse) private var scans: [BodyScanResult]

    @State private var segment = 0
    @State private var activeSession: WorkoutSession?

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Workout")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Color.voltTextDark)
                .padding(.horizontal, 20)
                .padding(.top, 12)

            PillSegmentedControl(options: ["Today", "Program", "History"], selection: $segment)
                .padding(.horizontal, 20)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    if let profile {
                        switch segment {
                        case 0: todaySection(profile: profile)
                        case 1: programSection(profile: profile)
                        default: historySection
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.voltOffWhite)
        .fullScreenCover(item: $activeSession) { session in
            WorkoutSessionView(session: session)
        }
    }

    // MARK: Today

    private func todaysWorkout(profile: UserProfile) -> PlannedWorkout {
        let recoveries = RecoveryEngine.allRecoveries(profile: profile, sessions: sessions, scan: scans.first)
        return AIProgramEngine.todaysWorkout(profile: profile, scan: scans.first, recoveries: recoveries, sessions: sessions)
    }

    /// Today's live/completed session matching the plan, if one exists.
    private func todaysSession(named name: String) -> WorkoutSession? {
        sessions.first { $0.name == name && Calendar.current.isDateInToday($0.startDate) }
    }

    private func todaySection(profile: UserProfile) -> some View {
        let workout = todaysWorkout(profile: profile)
        let session = todaysSession(named: workout.name)

        return VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.name)
                            .font(.system(size: 21, weight: .bold))
                            .foregroundStyle(Color.voltTextDark)
                        Text("\(workout.durationMinutes) min · \(workout.exercises.count) Exercises · \(workout.muscles.map(\.rawValue).joined(separator: " · "))")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.voltTextMuted)
                    }
                    Spacer()
                    if session?.isCompleted == true {
                        Text("Done")
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.voltLime)
                            .foregroundStyle(Color.voltOnLime)
                            .clipShape(Capsule())
                    }
                }

                Divider()

                VStack(spacing: 0) {
                    ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, exercise in
                        let done = isExerciseDone(exercise.name, in: session)
                        Button {
                            guard session?.isCompleted != true else { return }
                            beginOrContinue(workout: workout, session: session)
                        } label: {
                            WorkoutExerciseRow(
                                index: index + 1,
                                name: exercise.name,
                                detail: "\(exercise.sets) sets × \(exercise.repRange)",
                                isCompleted: done
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(session?.isCompleted == true)
                    }
                }

                if workout.cardioFinisherMinutes > 0, let cardioType = workout.cardioType {
                    HStack(spacing: 8) {
                        Image(systemName: cardioType.icon)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.voltLimeDeep)
                        Text("Finisher: \(workout.cardioFinisherMinutes) min \(cardioType.rawValue.lowercased())")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.voltTextMuted)
                    }
                    .padding(.top, 2)
                }

                if session?.isCompleted != true {
                    PrimaryButton(title: session == nil ? "Start Workout" : "Continue Workout", icon: "play.fill") {
                        beginOrContinue(workout: workout, session: session)
                    }
                }
            }
            .voltCard()
        }
    }

    private func beginOrContinue(workout: PlannedWorkout, session: WorkoutSession?) {
        if let session, !session.isCompleted {
            activeSession = session
        } else {
            activeSession = StorageService.startSession(from: workout, context: context)
        }
    }

    private func isExerciseDone(_ name: String, in session: WorkoutSession?) -> Bool {
        guard let session else { return false }
        return session.exercises.first(where: { $0.name == name })?.isDone ?? false
    }

    // MARK: AI Program

    private func programSection(profile: UserProfile) -> some View {
        let recoveries = RecoveryEngine.allRecoveries(profile: profile, sessions: sessions, scan: scans.first)
        let program = AIProgramEngine.program(profile: profile, scan: scans.first, sessions: sessions, recoveries: recoveries)

        return VStack(spacing: 14) {
            // Split header
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.voltLime)
                        .frame(width: 30, height: 30)
                        .background(Color.voltBlack)
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AI Program · \(program.split.rawValue)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.voltTextDark)
                        Text("Built for your \(scans.first?.bodyType.rawValue ?? profile.currentBodyType.rawValue) body → \(profile.dreamBody.rawValue) goal")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.voltTextMuted)
                    }
                }
                Text(program.split.rationale)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.voltTextMuted)
            }
            .voltCard()

            // Weekly schedule
            VStack(spacing: 0) {
                ForEach(Array(program.week.enumerated()), id: \.offset) { _, entry in
                    weekRow(day: entry.day, plan: entry.plan)
                    if entry.day != "Sun" { Divider().padding(.leading, 56) }
                }
            }
            .background(Color.voltCard)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 5)

            // Cardio & core prescriptions
            HStack(spacing: 12) {
                prescriptionCard(icon: program.cardio.type.icon, title: "Cardio", value: "\(program.cardio.sessionsPerWeek)× / week", detail: "\(program.cardio.minutes) min \(program.cardio.type.rawValue)")
                prescriptionCard(icon: "figure.core.training", title: "Core", value: "\(program.core.sessionsPerWeek)× / week", detail: "Built into lift days")
            }

            // Coach notes
            VStack(alignment: .leading, spacing: 12) {
                Text("Coach Notes")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.voltTextDark)
                ForEach(Array(program.coachNotes.enumerated()), id: \.offset) { _, note in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.voltLimeDeep)
                            .padding(.top, 2)
                        Text(note)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.voltTextMuted)
                    }
                }
            }
            .voltCard()
        }
    }

    private func weekRow(day: String, plan: DayPlan) -> some View {
        HStack(spacing: 14) {
            Text(day)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.voltTextMuted)
                .frame(width: 42, alignment: .leading)

            switch plan {
            case .lift(let workout):
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.voltOnLime)
                    .frame(width: 30, height: 30)
                    .background(Color.voltLime)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(workout.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.voltTextDark)
                    Text(workout.muscles.map(\.rawValue).joined(separator: " · "))
                        .font(.system(size: 11))
                        .foregroundStyle(Color.voltTextMuted)
                }
                Spacer()
                Text("\(workout.durationMinutes) min")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.voltTextMuted)
            case .cardio(let type, let minutes):
                Image(systemName: type.icon)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.voltTextDark)
                    .frame(width: 30, height: 30)
                    .background(Color.voltSoftGray)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.voltTextDark)
                    Text("Cardio")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.voltTextMuted)
                }
                Spacer()
                Text("\(minutes) min")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.voltTextMuted)
            case .rest:
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.voltTextMuted)
                    .frame(width: 30, height: 30)
                    .background(Color.voltSoftGray)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                Text("Rest & Recovery")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.voltTextMuted)
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    private func prescriptionCard(icon: String, title: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.voltOnLime)
                    .frame(width: 26, height: 26)
                    .background(Color.voltLime.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.voltTextMuted)
            }
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.voltTextDark)
            Text(detail)
                .font(.system(size: 11))
                .foregroundStyle(Color.voltTextMuted)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.voltCard)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 5)
    }

    // MARK: History

    private var historySection: some View {
        let completed = sessions.filter(\.isCompleted)
        return VStack(spacing: 12) {
            if completed.isEmpty {
                Text("No workouts logged yet.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.voltTextMuted)
                    .padding(.top, 32)
            }
            ForEach(completed) { session in
                HStack(spacing: 14) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.voltLimeDeep)
                        .frame(width: 44, height: 44)
                        .background(Color.voltLime.opacity(0.25))
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(session.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.voltTextDark)
                        Text("\(session.startDate.formatted(.dateTime.weekday(.wide).day().month())) · \(session.durationMinutes) min · \(session.totalCompletedSets) sets")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.voltTextMuted)
                    }
                    Spacer()
                    Text(session.muscles.map(\.rawValue).joined(separator: ", "))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.voltTextMuted)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 90, alignment: .trailing)
                }
                .voltCard()
            }
        }
    }
}

#Preview {
    WorkoutView()
        .modelContainer(PreviewSupport.container)
}
