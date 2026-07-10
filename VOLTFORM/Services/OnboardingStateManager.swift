import SwiftUI
import Observation

@Observable
final class OnboardingStateManager {
    var step: Int = 1

    var goal: FitnessGoal? = nil
    var level: FitnessLevel? = nil
    var trainingDays: Int? = nil

    var age: String = "24"
    var height: String = "180"
    var weight: String = "82"
    var gender: Gender = .male

    var dreamBody: BodyType? = nil

    var sleep: SleepAverage = .sevenToEight
    var soreness: SorenessLevel = .low
    var hydration: HydrationLevel = .good

    var didScan = false

    func next() {
        withAnimation(.easeInOut(duration: 0.35)) { step += 1 }
    }

    func back() {
        guard step > 1 else { return }
        withAnimation(.easeInOut(duration: 0.35)) { step -= 1 }
    }

    func buildProfile() -> UserProfile {
        UserProfile(
            name: DeviceIdentity.suggestedUserName,
            age: Int(age) ?? 24,
            heightCm: Double(height) ?? 180,
            weightKg: Double(weight) ?? 82,
            gender: gender,
            goal: goal ?? .buildMuscle,
            fitnessLevel: level ?? .intermediate,
            trainingDaysPerWeek: trainingDays ?? 4,
            dreamBody: dreamBody ?? .athletic,
            sleepAverage: sleep,
            soreness: soreness,
            hydration: hydration,
            currentBodyType: .athletic
        )
    }
}
