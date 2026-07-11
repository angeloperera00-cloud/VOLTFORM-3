import SwiftUI
import SwiftData

@main
struct VOLTFORMApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [
            UserProfile.self,
            WorkoutPlan.self,
            WorkoutSession.self,
            ExerciseLog.self,
            SetLog.self,
            BodyScanResult.self,
            RecoverySnapshot.self,
            DailyRecoveryCheckIn.self
        ])
    }
}
