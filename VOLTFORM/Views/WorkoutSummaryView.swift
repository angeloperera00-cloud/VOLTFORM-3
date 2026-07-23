import SwiftUI

struct WorkoutSummaryView: View {
    @Environment(\.dismiss) private var dismiss

    let session: WorkoutSession
    let onDone: () -> Void

    /// Trained muscles render green (>=75 maps to voltLimeDeep in
    /// MuscleRecoveryFigure); everything else falls through to unknownColor.
    private var trainedHighlight: [MuscleGroup: Double] {
        Dictionary(uniqueKeysWithValues: session.muscles.map { ($0, 100.0) })
    }

    var body: some View {
        ZStack {
            Color.voltBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                Text("Muscles Trained")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.top, 24)

                // Muscle chips
                HStack(spacing: 8) {
                    ForEach(session.muscles) { muscle in
                        Text(muscle.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.voltLime)
                            .foregroundStyle(Color.voltOnLime)
                            .clipShape(Capsule())
                    }
                }
                .padding(.top, 14)

                Spacer()

                MuscleRecoveryFigure(recoveries: trainedHighlight, unknownColor: .white.opacity(0.12))
                    .frame(height: 280)

                Spacer()

                DarkWorkoutCard {
                    Text("Great workout! You hit all your target muscles.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(.bottom, 16)

                PrimaryButton(title: "Done", style: .lime) {
                    dismiss()
                    onDone()
                }
            }
            .padding(24)
        }
    }
}

#Preview {
    WorkoutSummaryView(session: PreviewSupport.sampleSession, onDone: {})
        .modelContainer(PreviewSupport.container)
}
