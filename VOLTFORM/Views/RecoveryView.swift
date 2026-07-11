import SwiftUI
import SwiftData

struct RecoveryView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]
    @Query(sort: \WorkoutSession.startDate, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \DailyRecoveryCheckIn.date, order: .reverse) private var checkIns: [DailyRecoveryCheckIn]

    @State private var now = Date()
    @State private var showCheckIn = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("Recovery")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Color.voltTextDark)
                    Spacer()
                    Button { showCheckIn = true } label: {
                        Label("Check in", systemImage: "plus")
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.voltLime)
                            .foregroundStyle(Color.voltTextDark)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                if let profile {
                    let recoveries = RecoveryEngine.allRecoveries(profile: profile, sessions: sessions, at: now)

                    overviewCard(profile: profile, recoveries: recoveries)

                    Text("Muscle Recovery Forecast")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.voltTextDark)
                        .padding(.top, 4)

                    VStack(spacing: 12) {
                        ForEach(recoveries) { recovery in
                            MuscleRecoveryCard(recovery: recovery)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Color.voltOffWhite)
        .onAppear { now = Date() }
        .sheet(isPresented: $showCheckIn) {
            RecoveryCheckInSheet {
                now = Date()
            }
            .presentationDetents([.medium])
        }
    }

    private func overviewCard(profile: UserProfile, recoveries: [MuscleRecovery]) -> some View {
        let overall = RecoveryEngine.overallRecovery(recoveries)
        let sleepAvg = RecoveryEngine.sleepThreeDayAverage(checkIns: checkIns, fallback: profile.sleepAverage.hours)

        return VStack(spacing: 16) {
            HStack(spacing: 20) {
                RecoveryRing(percentage: overall, size: 104, caption: overall >= 70 ? "Good" : (overall >= 45 ? "Average" : "Low"))
                VStack(alignment: .leading, spacing: 12) {
                    overviewRow(icon: "moon.fill", label: "Sleep", value: VoltFormat.hoursMinutes(sleepAvg), delta: "3day avg", deltaColor: .voltTextMuted)
                    overviewRow(icon: "drop.fill", label: "Hydration", value: profile.hydration.rawValue, delta: profile.hydration == .good ? "+3%" : (profile.hydration == .low ? "+6% slower" : "—"), deltaColor: profile.hydration == .good ? .voltLimeDeep : .voltWarning)
                    overviewRow(icon: "waveform.path.ecg", label: "Soreness", value: profile.soreness.rawValue, delta: profile.soreness == .low ? "-2%" : (profile.soreness == .high ? "+20% slower" : "+5%"), deltaColor: profile.soreness == .low ? .voltLimeDeep : .voltWarning)
                }
            }
        }
        .voltCard()
    }

    private func overviewRow(icon: String, label: String, value: String, delta: String, deltaColor: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.voltTextDark)
                .frame(width: 24, height: 24)
                .background(Color.voltSoftGray)
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(Color.voltTextMuted)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.voltTextDark)
            Text(delta)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(deltaColor)
        }
    }
}

// MARK: - Daily check-in sheet

struct RecoveryCheckInSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]

    let onSave: () -> Void

    @State private var sleepHours: Double = 7.5
    @State private var soreness: SorenessLevel = .low
    @State private var hydration: HydrationLevel = .good

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Daily Check-in")
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(Color.voltTextDark)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Sleep last night")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.voltTextDark)
                    Spacer()
                    Text(VoltFormat.hoursMinutes(sleepHours))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.voltLimeDeep)
                }
                Slider(value: $sleepHours, in: 4...11, step: 0.25)
                    .tint(Color.voltLime)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Soreness")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.voltTextDark)
                PillSegmentedControl(
                    options: SorenessLevel.allCases.map(\.rawValue),
                    selection: Binding(
                        get: { SorenessLevel.allCases.firstIndex(of: soreness) ?? 0 },
                        set: { soreness = SorenessLevel.allCases[$0] }
                    )
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Hydration")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.voltTextDark)
                PillSegmentedControl(
                    options: HydrationLevel.allCases.map(\.rawValue),
                    selection: Binding(
                        get: { HydrationLevel.allCases.firstIndex(of: hydration) ?? 2 },
                        set: { hydration = HydrationLevel.allCases[$0] }
                    )
                )
            }

            PrimaryButton(title: "Save Check in") {
                let checkIn = DailyRecoveryCheckIn(date: .now, sleepHours: sleepHours, hydration: hydration, soreness: soreness)
                context.insert(checkIn)
                if let profile = profiles.first {
                    profile.soreness = soreness
                    profile.hydration = hydration
                }
                try? context.save()
                onSave()
                dismiss()
            }
        }
        .padding(24)
        .presentationBackground(Color.voltOffWhite)
    }
}
