import Foundation

// MARK: - Value types

struct TrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct MuscleRecovery: Identifiable {
    let muscle: MuscleGroup
    let percentage: Double
    let readyBy: Date?
    let neededHours: Double
    let trend: [TrendPoint]
    let chip: String
    let warning: Bool

    var id: String { muscle.rawValue }

    var status: String {
        if percentage >= 95 { return "Ready" }
        if percentage >= 75 { return "Almost Ready" }
        return "Recovering"
    }
}

// MARK: - RecoveryEngine
//
// Recovery is personal. The needed recovery window for each muscle is derived
// from: base muscle recovery hours, fitness level, soreness, sleep average,
// hydration, completed training volume, and the relationship between the
// user's current body type and their goal body type.

enum RecoveryEngine {

    /// Personalized hours needed for a muscle to fully recover after a session.
    static func neededHours(for muscle: MuscleGroup, profile: UserProfile, session: WorkoutSession?) -> Double {
        var hours = muscle.baseRecoveryHours

        hours *= profile.fitnessLevel.recoveryMultiplier      // Beginner +15%, Advanced -10%
        hours *= profile.soreness.recoveryMultiplier          // High soreness +20%
        hours *= profile.sleepAverage.recoveryMultiplier      // Low sleep +15%
        hours *= profile.hydration.recoveryMultiplier         // Good -3%, Low +6%
        hours *= bodyGoalModifier(current: profile.currentBodyType, goal: profile.dreamBody, muscle: muscle)

        // Completed volume for this muscle in the session: +10% to +25%.
        if let session {
            let volume = session.exercises
                .filter { $0.muscleGroupRaw == muscle.rawValue }
                .reduce(0) { $0 + $1.completedSets }
            if volume >= 14 { hours *= 1.25 }
            else if volume >= 10 { hours *= 1.18 }
            else if volume >= 7 { hours *= 1.10 }
        }
        return hours
    }

    /// Current body vs goal body shifts recovery load between muscle groups.
    static func bodyGoalModifier(current: BodyType, goal: BodyType, muscle: MuscleGroup) -> Double {
        // Under-muscled physiques chasing size: heavy hypertrophy volume lands
        // on legs and back, so those recover slower.
        if current.isMuscleDeficient && goal == .muscular {
            return (muscle == .legs || muscle == .back) ? 1.10 : 1.03
        }
        // Fat-dominant physiques cutting toward athletic/lean: conditioning work
        // keeps legs and core under constant load.
        if current.isFatDominant && (goal == .athletic || goal == .lean) {
            return (muscle == .legs || muscle == .core) ? 1.08 : 1.0
        }
        // Well-trained bodies maintaining or leaning out turn over slightly faster.
        if (current == .athletic || current == .muscular || current == .mesomorph) && goal == .lean {
            return 0.97
        }
        return 1.0
    }

    static func latestSession(for muscle: MuscleGroup, in sessions: [WorkoutSession], before date: Date) -> WorkoutSession? {
        sessions
            .filter { $0.isCompleted && $0.muscles.contains(muscle) && ($0.endDate ?? $0.startDate) <= date }
            .max(by: { ($0.endDate ?? $0.startDate) < ($1.endDate ?? $1.startDate) })
    }

    static func snapshot(for muscle: MuscleGroup, profile: UserProfile, sessions: [WorkoutSession], at date: Date) -> (value: Double, readyBy: Date?, needed: Double) {
        guard let session = latestSession(for: muscle, in: sessions, before: date) else {
            return (100, nil, muscle.baseRecoveryHours)
        }
        let workoutEnd = session.endDate ?? session.startDate
        let needed = neededHours(for: muscle, profile: profile, session: session)
        let hoursSinceWorkout = date.timeIntervalSince(workoutEnd) / 3600
        let percentage = min(100, max(0, hoursSinceWorkout / needed * 100))
        let readyByDate = workoutEnd.addingTimeInterval(needed * 3600)
        return (percentage, percentage >= 100 ? nil : readyByDate, needed)
    }

    /// Last N days of recovery values, sampled once per day (and "now" for today).
    static func trend(for muscle: MuscleGroup, profile: UserProfile, sessions: [WorkoutSession], days: Int = 7, endingAt now: Date = .now) -> [TrendPoint] {
        var points: [TrendPoint] = []
        let calendar = Calendar.current
        for offset in stride(from: days - 1, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: now) else { continue }
            let sampleDate: Date
            if offset == 0 {
                sampleDate = now
            } else {
                sampleDate = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: day) ?? day
            }
            let result = snapshot(for: muscle, profile: profile, sessions: sessions, at: sampleDate)
            points.append(TrendPoint(date: sampleDate, value: result.value))
        }
        return points
    }

    static func recovery(for muscle: MuscleGroup, profile: UserProfile, sessions: [WorkoutSession], at now: Date = .now) -> MuscleRecovery {
        let result = snapshot(for: muscle, profile: profile, sessions: sessions, at: now)
        let trendPoints = trend(for: muscle, profile: profile, sessions: sessions, endingAt: now)

        // If a muscle stays below 60% for 5+ days, warn about chronic under-recovery.
        let lastFive = Array(trendPoints.suffix(5))
        let warning = lastFive.count >= 5 && lastFive.allSatisfy { $0.value < 60 }

        let chip: String
        if warning {
            chip = "Hasn't hit 60%"
        } else if result.value >= 90 {
            chip = "Great"
        } else if let first = trendPoints.first, let last = trendPoints.last, last.value - first.value > 10 {
            chip = "Good trend"
        } else {
            chip = "Average"
        }

        return MuscleRecovery(
            muscle: muscle,
            percentage: result.value,
            readyBy: result.readyBy,
            neededHours: result.needed,
            trend: trendPoints,
            chip: chip,
            warning: warning
        )
    }

    static func allRecoveries(profile: UserProfile, sessions: [WorkoutSession], at now: Date = .now) -> [MuscleRecovery] {
        MuscleGroup.allCases.map { recovery(for: $0, profile: profile, sessions: sessions, at: now) }
    }

    static func overallRecovery(_ recoveries: [MuscleRecovery]) -> Double {
        guard !recoveries.isEmpty else { return 100 }
        return recoveries.map(\.percentage).reduce(0, +) / Double(recoveries.count)
    }

    static func sleepThreeDayAverage(checkIns: [DailyRecoveryCheckIn], fallback: Double = 7.4) -> Double {
        let recent = checkIns.sorted { $0.date > $1.date }.prefix(3)
        guard !recent.isEmpty else { return fallback }
        return recent.map(\.sleepHours).reduce(0, +) / Double(recent.count)
    }
}
