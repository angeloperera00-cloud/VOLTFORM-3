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
                .padding(.bottom, 24)
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

// MARK: - Detail views

struct PersonalInfoView: View {
    @Bindable var profile: UserProfile

    var body: some View {
        Form {
            Section("Basics") {
                TextField("Name", text: $profile.name)
                Stepper("Age: \(profile.age)", value: $profile.age, in: 14...90)
            }
            Section("Body") {
                Stepper("Height: \(Int(profile.heightCm)) cm", value: $profile.heightCm, in: 120...220, step: 1)
                Stepper("Weight: \(String(format: "%.1f", profile.weightKg)) kg", value: $profile.weightKg, in: 35...200, step: 0.5)
                Picker("Gender", selection: $profile.gender) {
                    ForEach(Gender.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
            }
        }
        .navigationTitle("Personal Information")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(Color.voltOffWhite)
    }
}

struct GoalsPlanView: View {
    @Bindable var profile: UserProfile

    var body: some View {
        Form {
            Section("Goal") {
                Picker("Main goal", selection: $profile.goal) {
                    ForEach(FitnessGoal.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                Picker("Dream body", selection: $profile.dreamBody) {
                    ForEach(BodyType.dreamOptions, id: \.self) { Text($0.rawValue).tag($0) }
                }
            }
            Section("Level") {
                Picker("Fitness level", selection: $profile.fitnessLevel) {
                    ForEach(FitnessLevel.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
            }
            Section {
                Text("Changing these regenerates your weekly plan and recovery windows automatically.")
                    .font(.footnote)
                    .foregroundStyle(Color.voltTextMuted)
            }
        }
        .navigationTitle("Goals & Plan")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(Color.voltOffWhite)
    }
}

struct TrainingScheduleView: View {
    @Bindable var profile: UserProfile

    var body: some View {
        Form {
            Section("Weekly frequency") {
                Stepper("\(profile.trainingDaysPerWeek) days a week", value: $profile.trainingDaysPerWeek, in: 3...6)
                LabeledContent("Split", value: AIProgramEngine.splitSummary(for: profile.trainingDaysPerWeek))
            }
        }
        .navigationTitle("Training Schedule")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(Color.voltOffWhite)
    }
}

struct RecoverySettingsView: View {
    @Bindable var profile: UserProfile

    var body: some View {
        Form {
            Section("Current state") {
                Picker("Typical soreness", selection: $profile.soreness) {
                    ForEach(SorenessLevel.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
            }
            Section {
                Text("High soreness extends every muscle's recovery window by 20%. Update this whenever your body feels different.")
                    .font(.footnote)
                    .foregroundStyle(Color.voltTextMuted)
            }
        }
        .navigationTitle("Recovery Settings")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(Color.voltOffWhite)
    }
}

struct SleepHydrationView: View {
    @Bindable var profile: UserProfile

    var body: some View {
        Form {
            Section("Sleep") {
                Picker("Average sleep", selection: $profile.sleepAverage) {
                    ForEach(SleepAverage.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
            }
            Section("Hydration") {
                Picker("Daily hydration", selection: $profile.hydration) {
                    ForEach(HydrationLevel.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
            }
            Section {
                Text("Sleeping under 7 hours slows recovery by 15%. Good hydration speeds it up by 3%.")
                    .font(.footnote)
                    .foregroundStyle(Color.voltTextMuted)
            }
        }
        .navigationTitle("Sleep & Hydration")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(Color.voltOffWhite)
    }
}

struct AppPreferencesView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("useMetric") private var useMetric = true

    var body: some View {
        Form {
            Section("Notifications") {
                Toggle("Muscle-ready reminders", isOn: $notificationsEnabled)
                    .onChange(of: notificationsEnabled) { _, enabled in
                        if enabled { NotificationService.requestAuthorization() }
                        else { NotificationService.cancelAll() }
                    }
            }
            Section("Units") {
                Toggle("Use metric (kg / cm)", isOn: $useMetric)
            }
        }
        .navigationTitle("App Preferences")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(Color.voltOffWhite)
    }
}

struct HelpSupportView: View {
    var body: some View {
        Form {
            Section("How recovery works") {
                Text("Every muscle has a base recovery window (36–72 hours). VOLTFORM adjusts it with your fitness level, sleep, soreness, hydration, training volume, and the gap between your current and dream body — so your forecast is yours alone.")
                    .font(.footnote)
            }
            Section("Contact") {
                LabeledContent("Email", value: "support@voltform.app")
            }
        }
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(Color.voltOffWhite)
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
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Developer Screen Gallery

/// Developer-only screen catalog — every screen in the app, reachable from
/// one place, like flipping through a simulator's view hierarchy. Not part
/// of the real user flow; wire it up from a hidden or admin-only entry point.
enum GalleryDestination: String, Identifiable, CaseIterable {
    case splash = "Splash"
    case home = "Home"
    case workout = "Workout"
    case recovery = "Recovery"
    case body = "Body"
    case profile = "Profile"
    case workoutSession = "Workout Session"
    case workoutCompleted = "Workout Completed"
    case workoutSummary = "Workout Summary"
    case bodyScan = "Body Scan (camera)"
    case scanResult = "Scan Result"
    case addWorkout = "Add Workout"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .splash: return "bolt.fill"
        case .home: return "house"
        case .workout: return "dumbbell"
        case .recovery: return "bolt.heart"
        case .body: return "person.fill.viewfinder"
        case .profile: return "person"
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
        case .splash: return "Onboarding"
        case .home, .workout, .recovery, .body, .profile: return "Main Tabs"
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
        case .splash:
            SplashView()
        case .home:
            HomeView(switchTab: { _ in })
        case .workout:
            WorkoutView()
        case .recovery:
            RecoveryView()
        case .body:
            BodyView()
        case .profile:
            ProfileView()
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
