import SwiftUI

struct WorkoutCompletedView: View {
    let session: WorkoutSession
    let onDone: () -> Void

    @State private var showSummary = false

    var body: some View {
        ZStack {
            Color.voltBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.voltLime.opacity(0.18))
                        .frame(width: 150, height: 150)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(Color.voltTextDark)
                        .frame(width: 100, height: 100)
                        .background(Color.voltLime)
                        .clipShape(Circle())
                }

                Text("Workout Complete")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.top, 26)

                Text(session.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.voltLime)
                    .padding(.top, 6)

                HStack(spacing: 12) {
                    statCard(icon: "clock", value: "\(session.durationMinutes) min", label: "Duration")
                    statCard(icon: "dumbbell", value: "\(session.exercises.count)", label: "Exercises")
                }
                .padding(.top, 30)
                HStack(spacing: 12) {
                    statCard(icon: "scalemass", value: "\(Int(session.totalVolumeKg)) kg", label: "Volume")
                    statCard(icon: "flame", value: "~\(session.durationMinutes * 7) kcal", label: "Est. burned")
                }
                .padding(.top, 12)

                Spacer()

                PrimaryButton(title: "View Summary", icon: "chart.bar.fill", style: .lime) {
                    showSummary = true
                }
            }
            .padding(24)
        }
        .fullScreenCover(isPresented: $showSummary) {
            WorkoutSummaryView(session: session, onDone: onDone)
        }
    }

    private func statCard(icon: String, value: String, label: String) -> some View {
        DarkWorkoutCard {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.voltLime)
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
