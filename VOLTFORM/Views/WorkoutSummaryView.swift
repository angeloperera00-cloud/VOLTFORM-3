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
                            .foregroundStyle(Color.voltOnLime)
                            .clipShape(Capsule())
                    }
                }
                .padding(.top, 14)

                Spacer()

                VStack(spacing: 16) {
                    Image(showBack ? "PostureBodyBack" : "PostureBodyFront")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 420)
                        .id(showBack)
                        .transition(.asymmetric(
                            insertion: .move(edge: showBack ? .trailing : .leading).combined(with: .opacity),
                            removal: .move(edge: showBack ? .leading : .trailing).combined(with: .opacity)
                        ))
                        .gesture(
                            DragGesture(minimumDistance: 30)
                                .onEnded { value in
                                    let horizontal = value.translation.width
                                    let vertical = value.translation.height
                                    guard abs(horizontal) > abs(vertical) else { return }
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        if horizontal < 0 {
                                            showBack = true   // swipe left -> Back
                                        } else {
                                            showBack = false  // swipe right -> Front
                                        }
                                    }
                                }
                        )

                    PillSegmentedControl(options: ["Front", "Back"], selection: Binding(
                        get: { showBack ? 1 : 0 },
                        set: { newValue in
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showBack = newValue == 1
                            }
                        }
                    ), dark: true)
                    .frame(width: 200)
                }

                Spacer()

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
