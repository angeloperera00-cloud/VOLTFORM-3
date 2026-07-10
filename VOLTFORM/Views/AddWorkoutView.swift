import SwiftUI
import SwiftData

struct AddWorkoutView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]

    @State private var name = ""
    @State private var selectedMuscles: Set<MuscleGroup> = []
    @State private var intensity: WorkoutIntensity = .moderate
    @State private var durationMinutes = 45
    @State private var hoursAgo = 0

    var body: some View {
        ZStack {
            Color.voltBlack.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Log a Workout")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 4)

                Text("Manual workouts feed your recovery forecast too.")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.bottom, 18)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Name
                        DarkWorkoutCard {
                            TextField("", text: $name, prompt: Text("Workout name (e.g. Push Day)").foregroundStyle(.white.opacity(0.35)))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.white)
                        }

                        // Muscles
                        section("Muscles trained") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(MuscleGroup.allCases) { muscle in
                                    let selected = selectedMuscles.contains(muscle)
                                    Button {
                                        if selected { selectedMuscles.remove(muscle) } else { selectedMuscles.insert(muscle) }
                                    } label: {
                                        VStack(spacing: 6) {
                                            Image(systemName: muscle.icon)
                                                .font(.system(size: 17))
                                            Text(muscle.rawValue)
                                                .font(.system(size: 11, weight: .semibold))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 68)
                                        .background(selected ? Color.voltLime : Color.voltDarkCard)
                                        .foregroundStyle(selected ? Color.voltTextDark : .white.opacity(0.75))
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Intensity
                        section("Intensity") {
                            PillSegmentedControl(
                                options: WorkoutIntensity.allCases.map(\.rawValue),
                                selection: Binding(
                                    get: { WorkoutIntensity.allCases.firstIndex(of: intensity) ?? 1 },
                                    set: { intensity = WorkoutIntensity.allCases[$0] }
                                ),
                                dark: true
                            )
                        }

                        // Duration
                        section("Duration") {
                            DarkWorkoutCard {
                                HStack {
                                    Text("\(durationMinutes) min")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Stepper("", value: $durationMinutes, in: 10...180, step: 5)
                                        .labelsHidden()
                                        .colorScheme(.dark)
                                }
                            }
                        }

                        // When
                        section("When") {
                            DarkWorkoutCard {
                                HStack {
                                    Text(hoursAgo == 0 ? "Just now" : "\(hoursAgo)h ago")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Stepper("", value: $hoursAgo, in: 0...72)
                                        .labelsHidden()
                                        .colorScheme(.dark)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }

                PrimaryButton(title: "Save Workout", icon: "checkmark", style: .lime, isDisabled: name.trimmingCharacters(in: .whitespaces).isEmpty || selectedMuscles.isEmpty) {
                    save()
                }
            }
            .padding(20)
        }
        .presentationDetents([.large])
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
            content()
        }
    }

    private func save() {
        let end = Date.now.addingTimeInterval(Double(-hoursAgo) * 3600)
        let start = end.addingTimeInterval(Double(-durationMinutes) * 60)
        let muscles = Array(selectedMuscles)

        let session = WorkoutSession(name: name.trimmingCharacters(in: .whitespaces), startDate: start, intensity: intensity, muscles: muscles)
        session.endDate = end
        session.durationMinutes = durationMinutes
        session.isCompleted = true
        context.insert(session)

        // Per-muscle logs sized by intensity so RecoveryEngine's volume modifier works.
        for (index, muscle) in muscles.enumerated() {
            let log = ExerciseLog(name: "\(muscle.rawValue) work", muscle: muscle, plannedSets: intensity.estimatedSetsPerMuscle, repRange: "—", orderIndex: index)
            log.completedSets = intensity.estimatedSetsPerMuscle
            context.insert(log)
            log.session = session
        }

        if let profile = profiles.first {
            profile.xp += 40
            profile.level = 1 + profile.xp / 2500
            for muscle in muscles {
                let needed = RecoveryEngine.neededHours(for: muscle, profile: profile, session: session)
                NotificationService.scheduleMuscleReadyReminder(muscle: muscle, readyBy: end.addingTimeInterval(needed * 3600))
            }
        }

        try? context.save()
        dismiss()
    }
}
