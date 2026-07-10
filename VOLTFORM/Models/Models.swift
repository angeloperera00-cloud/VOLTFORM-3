import Foundation
import SwiftData
import UIKit

// MARK: - UserProfile

@Model
final class UserProfile {
    var name: String
    var age: Int
    var heightCm: Double
    var weightKg: Double
    var genderRaw: String
    var goalRaw: String
    var fitnessLevelRaw: String
    var trainingDaysPerWeek: Int
    var dreamBodyRaw: String
    var sleepAverageRaw: String
    var sorenessRaw: String
    var hydrationRaw: String
    var currentBodyTypeRaw: String
    var onboardingComplete: Bool
    var hasSeededSampleData: Bool
    var xp: Int
    var level: Int
    var createdAt: Date

    init(
        name: String = DeviceIdentity.suggestedUserName,
        age: Int = 24,
        heightCm: Double = 180,
        weightKg: Double = 82,
        gender: Gender = .male,
        goal: FitnessGoal = .buildMuscle,
        fitnessLevel: FitnessLevel = .intermediate,
        trainingDaysPerWeek: Int = 4,
        dreamBody: BodyType = .athletic,
        sleepAverage: SleepAverage = .sevenToEight,
        soreness: SorenessLevel = .low,
        hydration: HydrationLevel = .good,
        currentBodyType: BodyType = .athletic
    ) {
        self.name = name
        self.age = age
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.genderRaw = gender.rawValue
        self.goalRaw = goal.rawValue
        self.fitnessLevelRaw = fitnessLevel.rawValue
        self.trainingDaysPerWeek = trainingDaysPerWeek
        self.dreamBodyRaw = dreamBody.rawValue
        self.sleepAverageRaw = sleepAverage.rawValue
        self.sorenessRaw = soreness.rawValue
        self.hydrationRaw = hydration.rawValue
        self.currentBodyTypeRaw = currentBodyType.rawValue
        self.onboardingComplete = false
        self.hasSeededSampleData = false
        self.xp = 28450
        self.level = 12
        self.createdAt = .now
    }

    var gender: Gender {
        get { Gender(rawValue: genderRaw) ?? .male }
        set { genderRaw = newValue.rawValue }
    }
    var goal: FitnessGoal {
        get { FitnessGoal(rawValue: goalRaw) ?? .buildMuscle }
        set { goalRaw = newValue.rawValue }
    }
    var fitnessLevel: FitnessLevel {
        get { FitnessLevel(rawValue: fitnessLevelRaw) ?? .intermediate }
        set { fitnessLevelRaw = newValue.rawValue }
    }
    var dreamBody: BodyType {
        get { BodyType(rawValue: dreamBodyRaw) ?? .athletic }
        set { dreamBodyRaw = newValue.rawValue }
    }
    var sleepAverage: SleepAverage {
        get { SleepAverage(rawValue: sleepAverageRaw) ?? .sevenToEight }
        set { sleepAverageRaw = newValue.rawValue }
    }
    var soreness: SorenessLevel {
        get { SorenessLevel(rawValue: sorenessRaw) ?? .low }
        set { sorenessRaw = newValue.rawValue }
    }
    var hydration: HydrationLevel {
        get { HydrationLevel(rawValue: hydrationRaw) ?? .good }
        set { hydrationRaw = newValue.rawValue }
    }
    var currentBodyType: BodyType {
        get { BodyType(rawValue: currentBodyTypeRaw) ?? .athletic }
        set { currentBodyTypeRaw = newValue.rawValue }
    }

    var firstName: String {
        name.split(separator: " ").first.map(String.init) ?? name
    }
}

// MARK: - WorkoutPlan

@Model
final class WorkoutPlan {
    var name: String
    var goalRaw: String
    var daysPerWeek: Int
    var splitSummary: String
    var createdAt: Date

    init(name: String, goal: FitnessGoal, daysPerWeek: Int, splitSummary: String) {
        self.name = name
        self.goalRaw = goal.rawValue
        self.daysPerWeek = daysPerWeek
        self.splitSummary = splitSummary
        self.createdAt = .now
    }

    var goal: FitnessGoal {
        get { FitnessGoal(rawValue: goalRaw) ?? .buildMuscle }
        set { goalRaw = newValue.rawValue }
    }
}

// MARK: - WorkoutSession

@Model
final class WorkoutSession {
    var name: String
    var startDate: Date
    var endDate: Date?
    var durationMinutes: Int
    var intensityRaw: String
    var muscleGroupsRaw: String
    var notes: String
    var isCompleted: Bool

    @Relationship(deleteRule: .cascade, inverse: \ExerciseLog.session)
    var exercises: [ExerciseLog]

    init(
        name: String,
        startDate: Date = .now,
        intensity: WorkoutIntensity = .moderate,
        muscles: [MuscleGroup] = [],
        notes: String = ""
    ) {
        self.name = name
        self.startDate = startDate
        self.endDate = nil
        self.durationMinutes = 0
        self.intensityRaw = intensity.rawValue
        self.muscleGroupsRaw = muscles.map(\.rawValue).joined(separator: ",")
        self.notes = notes
        self.isCompleted = false
        self.exercises = []
    }

    var muscles: [MuscleGroup] {
        muscleGroupsRaw
            .split(separator: ",")
            .compactMap { MuscleGroup(rawValue: String($0)) }
    }

    var intensity: WorkoutIntensity {
        get { WorkoutIntensity(rawValue: intensityRaw) ?? .moderate }
        set { intensityRaw = newValue.rawValue }
    }

    var totalCompletedSets: Int {
        exercises.reduce(0) { $0 + $1.completedSets }
    }

    var totalVolumeKg: Double {
        exercises.flatMap(\.sets).reduce(0) { $0 + Double($1.reps) * $1.weight }
    }
}

// MARK: - ExerciseLog

@Model
final class ExerciseLog {
    var name: String
    var muscleGroupRaw: String
    var plannedSets: Int
    var completedSets: Int
    var repRange: String
    var orderIndex: Int
    var session: WorkoutSession?

    @Relationship(deleteRule: .cascade, inverse: \SetLog.exercise)
    var sets: [SetLog]

    init(name: String, muscle: MuscleGroup, plannedSets: Int, repRange: String, orderIndex: Int = 0) {
        self.name = name
        self.muscleGroupRaw = muscle.rawValue
        self.plannedSets = plannedSets
        self.completedSets = 0
        self.repRange = repRange
        self.orderIndex = orderIndex
        self.session = nil
        self.sets = []
    }

    var muscle: MuscleGroup {
        MuscleGroup(rawValue: muscleGroupRaw) ?? .chest
    }

    var isDone: Bool { completedSets >= plannedSets }
}

// MARK: - SetLog

@Model
final class SetLog {
    var index: Int
    var reps: Int
    var weight: Double
    var timestamp: Date
    var exercise: ExerciseLog?

    init(index: Int, reps: Int, weight: Double, timestamp: Date = .now) {
        self.index = index
        self.reps = reps
        self.weight = weight
        self.timestamp = timestamp
        self.exercise = nil
    }
}

// MARK: - BodyScanResult

@Model
final class BodyScanResult {
    var date: Date
    var bodyTypeRaw: String
    var bodyFatPercent: Double
    var muscleMassKg: Double
    var metabolicAge: Int
    var postureScore: Int
    var symmetryScore: Int
    var strongestRaw: String
    var weakestRaw: String
    var suggestedFocusRaw: String
    var muscleDistributionRaw: String = ""

    init(
        date: Date,
        bodyType: BodyType,
        bodyFatPercent: Double,
        muscleMassKg: Double,
        metabolicAge: Int,
        postureScore: Int,
        symmetryScore: Int,
        strongest: [MuscleGroup],
        weakest: [MuscleGroup],
        suggestedFocus: [MuscleGroup],
        muscleDistribution: [MuscleGroup: Int] = [:]
    ) {
        self.date = date
        self.bodyTypeRaw = bodyType.rawValue
        self.bodyFatPercent = bodyFatPercent
        self.muscleMassKg = muscleMassKg
        self.metabolicAge = metabolicAge
        self.postureScore = postureScore
        self.symmetryScore = symmetryScore
        self.strongestRaw = strongest.map(\.rawValue).joined(separator: ",")
        self.weakestRaw = weakest.map(\.rawValue).joined(separator: ",")
        self.suggestedFocusRaw = suggestedFocus.map(\.rawValue).joined(separator: ",")
        self.muscleDistributionRaw = muscleDistribution
            .map { "\($0.key.rawValue):\($0.value)" }
            .joined(separator: ",")
    }

    var bodyType: BodyType { BodyType(rawValue: bodyTypeRaw) ?? .athletic }
    var strongest: [MuscleGroup] { Self.decode(strongestRaw) }
    var weakest: [MuscleGroup] { Self.decode(weakestRaw) }
    var suggestedFocus: [MuscleGroup] { Self.decode(suggestedFocusRaw) }

    /// Per-muscle development score (0-100) estimated by the analysis engine.
    var muscleDistribution: [MuscleGroup: Int] {
        var result: [MuscleGroup: Int] = [:]
        for pair in muscleDistributionRaw.split(separator: ",") {
            let parts = pair.split(separator: ":")
            guard parts.count == 2,
                  let muscle = MuscleGroup(rawValue: String(parts[0])),
                  let score = Int(parts[1]) else { continue }
            result[muscle] = score
        }
        return result
    }

    private static func decode(_ raw: String) -> [MuscleGroup] {
        raw.split(separator: ",").compactMap { MuscleGroup(rawValue: String($0)) }
    }
}

// MARK: - RecoverySnapshot

@Model
final class RecoverySnapshot {
    var date: Date
    var muscleGroupRaw: String
    var percentage: Double

    init(date: Date, muscle: MuscleGroup, percentage: Double) {
        self.date = date
        self.muscleGroupRaw = muscle.rawValue
        self.percentage = percentage
    }

    var muscle: MuscleGroup { MuscleGroup(rawValue: muscleGroupRaw) ?? .chest }
}

// MARK: - DailyRecoveryCheckIn

@Model
final class DailyRecoveryCheckIn {
    var date: Date
    var sleepHours: Double
    var hydrationRaw: String
    var sorenessRaw: String

    init(date: Date, sleepHours: Double, hydration: HydrationLevel, soreness: SorenessLevel) {
        self.date = date
        self.sleepHours = sleepHours
        self.hydrationRaw = hydration.rawValue
        self.sorenessRaw = soreness.rawValue
    }

    var hydration: HydrationLevel { HydrationLevel(rawValue: hydrationRaw) ?? .good }
    var soreness: SorenessLevel { SorenessLevel(rawValue: sorenessRaw) ?? .low }
}
