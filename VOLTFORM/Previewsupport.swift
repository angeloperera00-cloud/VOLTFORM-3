import SwiftUI
import SwiftData

/// Shared in-memory SwiftData stack + seeded sample data for Xcode Previews.
/// Every #Preview block in the app pulls from this so the canvas always has
/// a realistic profile, workout history, and body scan to render against.
enum PreviewSupport {

    @MainActor
    static var container: ModelContainer = {
        let schema = Schema([
            UserProfile.self, WorkoutPlan.self, WorkoutSession.self, ExerciseLog.self,
            SetLog.self, BodyScanResult.self, RecoverySnapshot.self, DailyRecoveryCheckIn.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        seed(into: container.mainContext)
        return container
    }()

    @MainActor
    private static func seed(into context: ModelContext) {
        let profile = UserProfile(
            name: "",
            age: 24, heightCm: 180, weightKg: 82, gender: .male,
            goal: .buildMuscle, fitnessLevel: .intermediate, trainingDaysPerWeek: 4,
            dreamBody: .athletic, sleepAverage: .sevenToEight, soreness: .low,
            hydration: .good, currentBodyType: .mesomorph
        )
        profile.onboardingComplete = true
        profile.xp = 28450
        profile.level = 12
        context.insert(profile)

        let scan = BodyAnalysisEngine.analyze(profile: profile)
        context.insert(scan)
        profile.currentBodyType = scan.bodyType

        StorageService.seedSampleDataIfNeeded(context: context, profile: profile)

        try? context.save()
    }

    /// A single completed session pulled from the seeded data, for views that
    /// need one directly (session detail, summary, completed screens).
    @MainActor
    static var sampleSession: WorkoutSession {
        let descriptor = FetchDescriptor<WorkoutSession>(sortBy: [SortDescriptor(\.startDate, order: .reverse)])
        let sessions = (try? container.mainContext.fetch(descriptor)) ?? []
        return sessions.first ?? WorkoutSession(name: "Push Day")
    }

    @MainActor
    static var sampleScan: BodyScanResult {
        let descriptor = FetchDescriptor<BodyScanResult>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let scans = (try? container.mainContext.fetch(descriptor)) ?? []
        return scans.first ?? BodyAnalysisEngine.analyze(profile: UserProfile())
    }
}
