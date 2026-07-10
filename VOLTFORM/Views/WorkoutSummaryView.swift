import SwiftUI

struct WorkoutSummaryView: View {
    @Environment(\.dismiss) private var dismiss

    let session: WorkoutSession
    let onDone: () -> Void

    @State private var showBack = false

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
                            .foregroundStyle(Color.voltTextDark)
                            .clipShape(Capsule())
                    }
                }
                .padding(.top, 14)

                Spacer()

                VStack(spacing: 16) {
                    BodyFigurePlaceholder(dark: true, symbol: showBack ? "figure.stand" : "figure.arms.open")
                        .frame(height: 260)

                    PillSegmentedControl(options: ["Front", "Back"], selection: Binding(
                        get: { showBack ? 1 : 0 },
                        set: { showBack = $0 == 1 }
                    ), dark: true)
                    .frame(width: 200)
                }

                Spacer()

                DarkWorkoutCard {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.voltLime)
                        Text("Great workout! You hit all your target muscles.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                    }
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
