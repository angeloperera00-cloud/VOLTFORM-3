import Foundation
import SwiftData

enum StorageService {

    /// Turns a planned workout into a live SwiftData session with exercise logs.
    static func startSession(from planned: PlannedWorkout, context: ModelContext) -> WorkoutSession {
        let session = WorkoutSession(name: planned.name, startDate: .now, intensity: .moderate, muscles: planned.muscles)
        context.insert(session)
        for (index, exercise) in planned.exercises.enumerated() {
            let log = ExerciseLog(name: exercise.name, muscle: exercise.muscle, plannedSets: exercise.sets, repRange: exercise.repRange, orderIndex: index)
            context.insert(log)
            log.session = session
        }
        try? context.save()
        return session
    }

    /// Seeds a believable last-7-days training history so the recovery forecast
    /// feels alive on first launch. Real workouts blend in on top of this.
    static func seedSampleDataIfNeeded(context: ModelContext, profile: UserProfile) {
        guard !profile.hasSeededSampleData else { return }
        profile.hasSeededSampleData = true
        let now = Date()

        func seedSession(name: String, hoursAgo: Double, duration: Int, exercises: [(name: String, muscle: MuscleGroup, sets: Int, weight: Double)]) {
            let end = now.addingTimeInterval(-hoursAgo * 3600)
            let start = end.addingTimeInterval(-Double(duration) * 60)
            let muscles = Array(Set(exercises.map(\.muscle)))
            let session = WorkoutSession(name: name, startDate: start, intensity: .moderate, muscles: muscles)
            session.endDate = end
            session.durationMinutes = duration
            session.isCompleted = true
            context.insert(session)

            for (index, exercise) in exercises.enumerated() {
                let log = ExerciseLog(name: exercise.name, muscle: exercise.muscle, plannedSets: exercise.sets, repRange: "8-10 reps", orderIndex: index)
                log.completedSets = exercise.sets
                context.insert(log)
                log.session = session
                for setIndex in 0..<exercise.sets {
                    let set = SetLog(index: setIndex + 1, reps: 9, weight: exercise.weight, timestamp: end.addingTimeInterval(Double(-(exercise.sets - setIndex)) * 180))
                    context.insert(set)
                    set.exercise = log
                }
            }
        }

        // Older history for realistic 7-day trends.
        seedSession(name: "Push Day", hoursAgo: 150, duration: 46, exercises: [
            ("Barbell Bench Press", .chest, 4, 75),
            ("Cable Fly", .chest, 3, 20),
            ("Dumbbell Shoulder Press", .shoulders, 3, 22)
        ])
        seedSession(name: "Leg Day", hoursAgo: 144, duration: 55, exercises: [
            ("Back Squat", .legs, 4, 90),
            ("Leg Press", .legs, 4, 160),
            ("Romanian Deadlift", .legs, 3, 70)
        ])
        seedSession(name: "Pull Day", hoursAgo: 122, duration: 48, exercises: [
            ("Deadlift", .back, 4, 110),
            ("Lat Pulldown", .back, 3, 55),
            ("Biceps Curl", .arms, 3, 14)
        ])
        seedSession(name: "Lower Body", hoursAgo: 84, duration: 45, exercises: [
            ("Front Squat", .legs, 4, 70),
            ("Walking Lunges", .legs, 4, 24)
        ])
        // Recent sessions driving today's forecast.
        seedSession(name: "Pull Day", hoursAgo: 46, duration: 50, exercises: [
            ("Deadlift", .back, 4, 115),
            ("Lat Pulldown", .back, 3, 60),
            ("Seated Cable Row", .back, 3, 55)
        ])
        seedSession(name: "Push Day", hoursAgo: 42, duration: 48, exercises: [
            ("Barbell Bench Press", .chest, 4, 80),
            ("Cable Fly", .chest, 3, 22),
            ("Dumbbell Shoulder Press", .shoulders, 3, 24)
        ])
        seedSession(name: "Arms & Core", hoursAgo: 33, duration: 35, exercises: [
            ("Triceps Pushdown", .arms, 3, 28),
            ("Hanging Leg Raise", .core, 3, 0)
        ])
        seedSession(name: "Leg Day", hoursAgo: 28, duration: 52, exercises: [
            ("Back Squat", .legs, 4, 95),
            ("Leg Press", .legs, 4, 170),
            ("Romanian Deadlift", .legs, 3, 75)
        ])

        // Sleep check-ins for the 3day average (~7h 23m).
        let calendar = Calendar.current
        let sleepValues: [Double] = [7.2, 7.5, 7.45]
        for (index, value) in sleepValues.enumerated() {
            if let day = calendar.date(byAdding: .day, value: -index, to: now) {
                let checkIn = DailyRecoveryCheckIn(date: day, sleepHours: value, hydration: profile.hydration, soreness: profile.soreness)
                context.insert(checkIn)
            }
        }

        try? context.save()
    }
}
