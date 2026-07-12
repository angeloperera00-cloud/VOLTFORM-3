import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    Text("Profile")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Color.voltTextDark)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let profile {
                        headerCard(profile)

                        VStack(spacing: 0) {
                            row("Personal Information", icon: "person") { PersonalInfoView(profile: profile) }
                            row("Goals & Plan", icon: "target") { GoalsPlanView(profile: profile) }
                            row("Training Schedule", icon: "calendar") { TrainingScheduleView(profile: profile) }
                            row("Recovery Settings", icon: "bolt.heart") { RecoverySettingsView(profile: profile) }
                            row("Sleep & Hydration", icon: "moon") { SleepHydrationView(profile: profile) }
                        }
                        .background(Color.voltCard)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 5)

                        VStack(spacing: 0) {
                            row("App Preferences", icon: "gearshape") { AppPreferencesView() }
                            row("Help & Support", icon: "questionmark.circle") { HelpSupportView() }
                            row("About VOLTFORM", icon: "bolt") { AboutView() }
                        }
                        .background(Color.voltCard)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 5)

                        VStack(spacing: 0) {
                            row("Screen Gallery", icon: "square.grid.2x2") { DevGalleryView() }
                        }
                        .background(Color.voltCard)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 5)
                        .overlay(alignment: .topLeading) {
                            Text("DEVELOPER")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.voltTextMuted)
                                .padding(.leading, 4)
                                .offset(y: -18)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 100)
            }
            .background(Color.voltOffWhite)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func headerCard(_ profile: UserProfile) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(Color.voltLime)
                Text(String(profile.firstName.prefix(1)))
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color.voltOnLime)
            }
            .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 4) {
                Text(profile.name)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(Color.voltTextDark)
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.voltLimeDeep)
                    Text("Level \(profile.level) · \(profile.xp.formatted()) XP")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.voltTextMuted)
                }
            }
            Spacer()
        }
        .voltCard()
    }

    private func row<Destination: View>(_ title: String, icon: String, @ViewBuilder destination: @escaping () -> Destination) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.voltTextDark)
                    .frame(width: 36, height: 36)
                    .background(Color.voltSoftGray)
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.voltTextDark)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.voltTextMuted.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shared detail-screen building blocks

/// Custom back button + title, replacing the native navigation bar so text
/// color is always explicit rather than dependent on system appearance
/// resolution (which doesn't reliably inherit dark mode in every context).
private struct DetailHeader: View {
    @Environment(\.dismiss) private var dismiss
    let title: String

    var body: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.voltTextDark)
                    .frame(width: 36, height: 36)
                    .background(Color.voltCard)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            Spacer()
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color.voltTextDark)
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}

private struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.voltTextMuted)
                .padding(.leading, 4)
            VStack(spacing: 0) {
                content
            }
            .background(Color.voltCard)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}

/// One tappable option inside a DetailSection, with a checkmark when selected.
private struct SelectableRow: View {
    let title: String
    let isSelected: Bool
    let showDivider: Bool
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: action) {
                HStack {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.voltTextDark)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.voltLimeDeep)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            if showDivider {
                Divider().padding(.leading, 16).background(Color.voltTextMuted.opacity(0.15))
            }
        }
    }
}

private struct StepperRow: View {
    let label: String
    let value: String
    let onDecrement: () -> Void
    let onIncrement: () -> Void
    var showDivider: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.voltTextDark)
                Spacer()
                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.voltTextMuted)
                HStack(spacing: 12) {
                    Button(action: onDecrement) {
                        Image(systemName: "minus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.voltTextDark)
                            .frame(width: 28, height: 28)
                            .background(Color.voltSoftGray)
                            .clipShape(Circle())
                    }
                    Button(action: onIncrement) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.voltTextDark)
                            .frame(width: 28, height: 28)
                            .background(Color.voltSoftGray)
                            .clipShape(Circle())
                    }
                }
                .buttonStyle(.plain)
                .padding(.leading, 10)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            if showDivider {
                Divider().padding(.leading, 16).background(Color.voltTextMuted.opacity(0.15))
            }
        }
    }
}

private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.voltTextDark)
            Spacer()
            Text(value)
                .font(.system(size: 15))
                .foregroundStyle(Color.voltTextMuted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

private struct ToggleRow: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.voltTextDark)
        }
        .tint(Color.voltLime)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct NoteText: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundStyle(Color.voltTextMuted)
            .padding(.horizontal, 4)
    }
}

// MARK: - Detail views

struct PersonalInfoView: View {
    @Bindable var profile: UserProfile

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                DetailSection(title: "Basics") {
                    HStack {
                        Text("Name")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.voltTextDark)
                        Spacer()
                        TextField("Name", text: $profile.name)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(Color.voltTextDark)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    Divider().padding(.leading, 16).background(Color.voltTextMuted.opacity(0.15))
                    StepperRow(
                        label: "Age", value: "\(profile.age)",
                        onDecrement: { if profile.age > 14 { profile.age -= 1 } },
                        onIncrement: { if profile.age < 90 { profile.age += 1 } }
                    )
                }
                DetailSection(title: "Body") {
                    StepperRow(
                        label: "Height", value: "\(Int(profile.heightCm)) cm",
                        onDecrement: { if profile.heightCm > 120 { profile.heightCm -= 1 } },
                        onIncrement: { if profile.heightCm < 220 { profile.heightCm += 1 } },
                        showDivider: true
                    )
                    StepperRow(
                        label: "Weight", value: String(format: "%.1f kg", profile.weightKg),
                        onDecrement: { if profile.weightKg > 35 { profile.weightKg -= 0.5 } },
                        onIncrement: { if profile.weightKg < 200 { profile.weightKg += 0.5 } },
                        showDivider: true
                    )
                    HStack(spacing: 10) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            Button {
                                profile.gender = gender
                            } label: {
                                Text(gender.rawValue)
                                    .font(.system(size: 13, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 40)
                                    .background(profile.gender == gender ? Color.voltLime : Color.voltSoftGray)
                                    .foregroundStyle(profile.gender == gender ? Color.voltOnLime : Color.voltTextDark)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Color.voltOffWhite)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top) { DetailHeader(title: "Personal Information").background(Color.voltOffWhite) }
    }
}

struct GoalsPlanView: View {
    @Bindable var profile: UserProfile

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                DetailSection(title: "Goal") {
                    ForEach(Array(FitnessGoal.allCases.enumerated()), id: \.element) { index, goal in
                        SelectableRow(title: goal.rawValue, isSelected: profile.goal == goal, showDivider: index != FitnessGoal.allCases.count - 1) {
                            profile.goal = goal
                        }
                    }
                }
                DetailSection(title: "Dream Body") {
                    ForEach(Array(BodyType.dreamOptions.enumerated()), id: \.element) { index, body in
                        SelectableRow(title: body.rawValue, isSelected: profile.dreamBody == body, showDivider: index != BodyType.dreamOptions.count - 1) {
                            profile.dreamBody = body
                        }
                    }
                }
                DetailSection(title: "Level") {
                    ForEach(Array(FitnessLevel.allCases.enumerated()), id: \.element) { index, level in
                        SelectableRow(title: level.rawValue, isSelected: profile.fitnessLevel == level, showDivider: index != FitnessLevel.allCases.count - 1) {
                            profile.fitnessLevel = level
                        }
                    }
                }
                NoteText(text: "Changing these regenerates your weekly plan and recovery windows automatically.")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Color.voltOffWhite)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top) { DetailHeader(title: "Goals & Plan").background(Color.voltOffWhite) }
    }
}

struct TrainingScheduleView: View {
    @Bindable var profile: UserProfile

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                DetailSection(title: "Weekly Frequency") {
                    StepperRow(
                        label: "Days a week", value: "\(profile.trainingDaysPerWeek)",
                        onDecrement: { if profile.trainingDaysPerWeek > 3 { profile.trainingDaysPerWeek -= 1 } },
                        onIncrement: { if profile.trainingDaysPerWeek < 6 { profile.trainingDaysPerWeek += 1 } },
                        showDivider: true
                    )
                    InfoRow(label: "Split", value: AIProgramEngine.splitSummary(for: profile.trainingDaysPerWeek))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Color.voltOffWhite)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top) { DetailHeader(title: "Training Schedule").background(Color.voltOffWhite) }
    }
}

struct RecoverySettingsView: View {
    @Bindable var profile: UserProfile

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                DetailSection(title: "Current State") {
                    ForEach(Array(SorenessLevel.allCases.enumerated()), id: \.element) { index, level in
                        SelectableRow(title: level.rawValue, isSelected: profile.soreness == level, showDivider: index != SorenessLevel.allCases.count - 1) {
                            profile.soreness = level
                        }
                    }
                }
                NoteText(text: "High soreness extends every muscle's recovery window by 20%. Update this whenever your body feels different.")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Color.voltOffWhite)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top) { DetailHeader(title: "Recovery Settings").background(Color.voltOffWhite) }
    }
}

struct SleepHydrationView: View {
    @Bindable var profile: UserProfile

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                DetailSection(title: "Sleep") {
                    ForEach(Array(SleepAverage.allCases.enumerated()), id: \.element) { index, sleep in
                        SelectableRow(title: sleep.rawValue, isSelected: profile.sleepAverage == sleep, showDivider: index != SleepAverage.allCases.count - 1) {
                            profile.sleepAverage = sleep
                        }
                    }
                }
                DetailSection(title: "Hydration") {
                    ForEach(Array(HydrationLevel.allCases.enumerated()), id: \.element) { index, hydration in
                        SelectableRow(title: hydration.rawValue, isSelected: profile.hydration == hydration, showDivider: index != HydrationLevel.allCases.count - 1) {
                            profile.hydration = hydration
                        }
                    }
                }
                NoteText(text: "Sleeping under 7 hours slows recovery by 15%. Good hydration speeds it up by 3%.")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Color.voltOffWhite)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top) { DetailHeader(title: "Sleep & Hydration").background(Color.voltOffWhite) }
    }
}

struct AppPreferencesView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("useMetric") private var useMetric = true

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                DetailSection(title: "Notifications") {
                    ToggleRow(label: "Muscle-ready reminders", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, enabled in
                            if enabled { NotificationService.requestAuthorization() }
                            else { NotificationService.cancelAll() }
                        }
                }
                DetailSection(title: "Units") {
                    ToggleRow(label: "Use metric (kg / cm)", isOn: $useMetric)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Color.voltOffWhite)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top) { DetailHeader(title: "App Preferences").background(Color.voltOffWhite) }
    }
}

struct HelpSupportView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                DetailSection(title: "How Recovery Works") {
                    Text("Every muscle has a base recovery window (36–72 hours). VOLTFORM adjusts it with your fitness level, sleep, soreness, hydration, training volume, and the gap between your current and dream body so your forecast is yours alone.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.voltTextDark)
                        .padding(16)
                }
                DetailSection(title: "Contact") {
                    InfoRow(label: "Email", value: "support@voltform.app")
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Color.voltOffWhite)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top) { DetailHeader(title: "Help & Support").background(Color.voltOffWhite) }
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "bolt.fill")
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(Color.voltLime)
            HStack(spacing: 0) {
                Text("VOLT").foregroundStyle(Color.voltTextDark)
                Text("FORM").foregroundStyle(Color.voltLimeDeep)
            }
            .font(.system(size: 26, weight: .heavy))
            Text("Your body. Your recovery. Your plan.")
                .font(.system(size: 14))
                .foregroundStyle(Color.voltTextMuted)
            Text("Version 1.0 · Built with SwiftUI & SwiftData")
                .font(.system(size: 12))
                .foregroundStyle(Color.voltTextMuted.opacity(0.7))
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.voltOffWhite)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top) { DetailHeader(title: "About").background(Color.voltOffWhite) }
    }
}

// MARK: - Developer Screen Gallery

/// Developer-only screen catalog — every screen in the app, reachable from
/// one place, like flipping through a simulator's view hierarchy. Not part
/// of the real user flow; wire it up from a hidden or admin-only entry point.
enum GalleryDestination: String, Identifiable, CaseIterable {
    case workoutSession = "Workout Session"
    case workoutCompleted = "Workout Completed"
    case workoutSummary = "Workout Summary"
    case bodyScan = "Body Scan (camera)"
    case scanResult = "Scan Result"
    case addWorkout = "Add Workout"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .workoutSession: return "figure.strengthtraining.traditional"
        case .workoutCompleted: return "checkmark.seal"
        case .workoutSummary: return "chart.bar"
        case .bodyScan: return "camera.viewfinder"
        case .scanResult: return "doc.text.magnifyingglass"
        case .addWorkout: return "plus.circle"
        }
    }

    var section: String {
        switch self {
        case .workoutSession, .workoutCompleted, .workoutSummary: return "Workout Flow"
        case .bodyScan, .scanResult: return "Body Scan Flow"
        case .addWorkout: return "Sheets"
        }
    }
}

struct DevGalleryView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorkoutSession.startDate, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \BodyScanResult.date, order: .reverse) private var scans: [BodyScanResult]
    @Query private var profiles: [UserProfile]

    @State private var destination: GalleryDestination?

    private var sampleSession: WorkoutSession {
        sessions.first ?? WorkoutSession(name: "Push Day")
    }

    private var sampleScan: BodyScanResult {
        scans.first ?? BodyAnalysisEngine.analyze(profile: profiles.first ?? UserProfile())
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(Array(Dictionary(grouping: GalleryDestination.allCases, by: \.section).sorted(by: { $0.key < $1.key })), id: \.key) { section, items in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(section.uppercased())
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.voltTextMuted)
                            .padding(.leading, 4)

                        VStack(spacing: 0) {
                            ForEach(items) { item in
                                Button {
                                    destination = item
                                } label: {
                                    HStack(spacing: 14) {
                                        Image(systemName: item.icon)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(Color.voltLime)
                                            .frame(width: 32, height: 32)
                                            .background(Color.voltBlack)
                                            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                                        Text(item.rawValue)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundStyle(Color.voltTextDark)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(Color.voltTextMuted.opacity(0.6))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                }
                                .buttonStyle(.plain)
                                if item.id != items.last?.id {
                                    Divider().padding(.leading, 62).background(Color.voltTextMuted.opacity(0.15))
                                }
                            }
                        }
                        .background(Color.voltCard)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .background(Color.voltOffWhite)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.voltTextDark)
                        .frame(width: 36, height: 36)
                        .background(Color.voltCard)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                Spacer()
                Text("Screen Gallery")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.voltTextDark)
                Spacer()
                Color.clear.frame(width: 36, height: 36)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .background(Color.voltOffWhite)
        }
        .fullScreenCover(item: $destination) { item in
            galleryDestinationView(item)
        }
    }

    @ViewBuilder
    private func galleryDestinationView(_ item: GalleryDestination) -> some View {
        switch item {
        case .workoutSession:
            WorkoutSessionView(session: sampleSession)
        case .workoutCompleted:
            WorkoutCompletedView(session: sampleSession, onDone: { destination = nil })
        case .workoutSummary:
            WorkoutSummaryView(session: sampleSession, onDone: { destination = nil })
        case .bodyScan:
            BodyScanView()
        case .scanResult:
            ScanResultView(scan: sampleScan, onDone: { destination = nil })
        case .addWorkout:
            AddWorkoutView()
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(PreviewSupport.container)
}
