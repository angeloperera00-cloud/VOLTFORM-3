import Foundation

// MARK: - Program value types

struct PlannedExercise: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let muscle: MuscleGroup
    let sets: Int
    let repRange: String
}

struct PlannedWorkout: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let muscles: [MuscleGroup]
    let durationMinutes: Int
    let exercises: [PlannedExercise]
    let tag: String
    var restSeconds: Int = 90
    var cardioFinisherMinutes: Int = 0
    var cardioType: CardioType? = nil
}

struct CardioPlan: Hashable {
    let type: CardioType
    let sessionsPerWeek: Int
    let minutes: Int
    let note: String
}

struct CorePlan: Hashable {
    let sessionsPerWeek: Int
    let note: String
}

enum DayPlan: Identifiable, Hashable {
    case lift(PlannedWorkout)
    case cardio(CardioType, minutes: Int)
    case rest

    var id: String {
        switch self {
        case .lift(let workout): return "lift-\(workout.id)"
        case .cardio(let type, let minutes): return "cardio-\(type.rawValue)-\(minutes)"
        case .rest: return "rest-\(UUID())"
        }
    }
}

struct TrainingProgram {
    let split: SplitType
    let week: [(day: String, plan: DayPlan)]
    let cardio: CardioPlan
    let core: CorePlan
    let liftingDays: [PlannedWorkout]
    let coachNotes: [String]
}

// MARK: - AIProgramEngine
//
// Generates a complete individualized program from: current body type,
// body-fat and lean-mass estimates, per-muscle development distribution,
// fitness level, training frequency, and the goal physique. It then keeps
// adapting using workout history, recovery state and new scans — no two
// users get the same plan.

enum AIProgramEngine {

    // MARK: Split selection

    static func chooseSplit(profile: UserProfile, scan: BodyScanResult?) -> SplitType {
        let bodyType = scan?.bodyType ?? profile.currentBodyType
        let days = profile.trainingDaysPerWeek

        // Fat-dominant physiques respond best to high-frequency, high-calorie-burn
        // sessions; hard gainers need fewer, harder sessions with more rest.
        switch profile.fitnessLevel {
        case .beginner:
            return days <= 3 ? .fullBody : .upperLower
        case .intermediate:
            if bodyType.isFatDominant && days <= 4 {
                return days == 3 ? .fullBody : .upperLower
            }
            switch days {
            case 3: return .ppl
            case 4: return .upperLower
            case 5: return .pplUpper
            default: return .pplDouble
            }
        case .advanced:
            if profile.dreamBody == .muscular && !bodyType.isFatDominant {
                return days >= 6 ? .broSplit : (days == 5 ? .arnold : .ppl)
            }
            switch days {
            case 3: return .ppl
            case 4: return .upperLower
            case 5: return .arnold
            default: return .pplDouble
            }
        }
    }

    // MARK: Cardio prescription

    static func cardioPlan(profile: UserProfile, scan: BodyScanResult?) -> CardioPlan {
        let bodyType = scan?.bodyType ?? profile.currentBodyType

        switch bodyType {
        case .overweight:
            return CardioPlan(type: .walking, sessionsPerWeek: 5, minutes: 40,
                              note: "Low-impact steady cardio protects your joints while creating a big calorie burn.")
        case .endomorph:
            return CardioPlan(type: .cycling, sessionsPerWeek: 3, minutes: 30,
                              note: "Steady cycling plus one weekly HIIT finisher keeps your metabolism high.")
        case .skinnyFat:
            return CardioPlan(type: .hiit, sessionsPerWeek: 2, minutes: 20,
                              note: "Short HIIT burns fat without eating into the muscle you need to build.")
        case .ectomorph:
            return CardioPlan(type: .walking, sessionsPerWeek: 1, minutes: 20,
                              note: "Minimal cardio every extra calorie goes toward building muscle.")
        case .lean, .athletic, .mesomorph:
            if profile.goal == .loseFat || profile.goal == .getLean {
                return CardioPlan(type: .hiit, sessionsPerWeek: 3, minutes: 20,
                                  note: "HIIT sharpens definition while preserving your muscle.")
            }
            return CardioPlan(type: .running, sessionsPerWeek: 2, minutes: 25,
                              note: "Two conditioning runs keep your heart and work capacity strong.")
        case .muscular:
            return CardioPlan(type: .walking, sessionsPerWeek: 2, minutes: 25,
                              note: "Easy incline walks aid recovery without compromising size.")
        }
    }

    // MARK: Core prescription

    static func corePlan(profile: UserProfile, scan: BodyScanResult?) -> CorePlan {
        let bodyFat = scan?.bodyFatPercent ?? 18
        let highFat = profile.gender == .female ? bodyFat > 30 : bodyFat > 20

        if highFat {
            return CorePlan(sessionsPerWeek: 2,
                            note: "Abs are built in the gym but revealed by fat loss cardio does the heavy lifting for now.")
        }
        if profile.dreamBody == .lean || profile.goal == .getLean {
            return CorePlan(sessionsPerWeek: 3,
                            note: "You're lean enough for direct ab work to show training core 3× per week.")
        }
        return CorePlan(sessionsPerWeek: 2,
                        note: "Weighted core work twice a week builds thickness and supports your big lifts.")
    }

    // MARK: Volume & intensity

    static func repRanges(for goal: FitnessGoal) -> (compound: String, isolation: String) {
        switch goal {
        case .buildMuscle: return ("8-10 reps", "12-15 reps")
        case .improveStrength: return ("4-6 reps", "8-10 reps")
        case .loseFat, .getLean: return ("12-15 reps", "15-20 reps")
        case .stayFit: return ("10-12 reps", "12-15 reps")
        }
    }

    static func restSeconds(for goal: FitnessGoal) -> Int {
        switch goal {
        case .improveStrength: return 150
        case .buildMuscle, .stayFit: return 90
        case .loseFat, .getLean: return 60
        }
    }

    /// Extra sets for lagging muscles, one less for dominant ones — driven by
    /// the scan's per-muscle distribution.
    static func setAdjustment(for muscle: MuscleGroup, scan: BodyScanResult?) -> Int {
        guard let distribution = scan?.muscleDistribution, !distribution.isEmpty else { return 0 }
        guard let score = distribution[muscle] else { return 0 }
        let average = distribution.values.reduce(0, +) / distribution.count
        if score <= average - 8 { return 1 }
        if score >= average + 12 { return -1 }
        return 0
    }

    // MARK: Exercise pools

    private static func exercises(for focus: String, goal: FitnessGoal, scan: BodyScanResult?, level: FitnessLevel) -> [PlannedExercise] {
        let r = repRanges(for: goal)
        func e(_ name: String, _ muscle: MuscleGroup, _ baseSets: Int, _ reps: String) -> PlannedExercise {
            let sets = max(2, baseSets + setAdjustment(for: muscle, scan: scan) + (level == .advanced ? 1 : 0))
            return PlannedExercise(name: name, muscle: muscle, sets: min(sets, 5), repRange: reps)
        }

        switch focus {
        case "push":
            return [
                e("Barbell Bench Press", .chest, 4, r.compound),
                e("Incline Dumbbell Press", .chest, 3, r.compound),
                e("Dumbbell Shoulder Press", .shoulders, 3, "10-12 reps"),
                e("Cable Fly", .chest, 3, r.isolation),
                e("Triceps Pushdown", .arms, 3, r.isolation),
                e("Overhead Triceps Extension", .arms, 3, r.isolation)
            ]
        case "pull":
            return [
                e("Deadlift", .back, 4, r.compound),
                e("Lat Pulldown", .back, 3, r.compound),
                e("Seated Cable Row", .back, 3, "10-12 reps"),
                e("Face Pull", .shoulders, 3, r.isolation),
                e("Biceps Curl", .arms, 3, r.isolation),
                e("Hammer Curl", .arms, 2, r.isolation)
            ]
        case "legs":
            return [
                e("Back Squat", .legs, 4, r.compound),
                e("Leg Press", .legs, 3, "10-12 reps"),
                e("Romanian Deadlift", .legs, 3, r.compound),
                e("Walking Lunges", .legs, 3, r.isolation),
                e("Standing Calf Raise", .legs, 3, r.isolation)
            ]
        case "upper":
            return [
                e("Incline Barbell Press", .chest, 3, r.compound),
                e("Pull-Up", .back, 3, r.compound),
                e("Arnold Press", .shoulders, 3, "10-12 reps"),
                e("Cable Row", .back, 3, "10-12 reps"),
                e("EZ-Bar Curl", .arms, 2, r.isolation),
                e("Triceps Pushdown", .arms, 2, r.isolation)
            ]
        case "lower":
            return [
                e("Front Squat", .legs, 4, r.compound),
                e("Hip Thrust", .legs, 3, "10-12 reps"),
                e("Leg Curl", .legs, 3, r.isolation),
                e("Leg Extension", .legs, 3, r.isolation),
                e("Seated Calf Raise", .legs, 3, r.isolation)
            ]
        case "fullBody":
            return [
                e("Goblet Squat", .legs, 3, r.compound),
                e("Flat Dumbbell Press", .chest, 3, r.compound),
                e("One-Arm Dumbbell Row", .back, 3, "10-12 reps"),
                e("Lateral Raise", .shoulders, 3, r.isolation),
                e("Biceps Curl", .arms, 2, r.isolation)
            ]
        case "chestBack":
            return [
                e("Barbell Bench Press", .chest, 4, r.compound),
                e("Bent-Over Row", .back, 4, r.compound),
                e("Incline Dumbbell Press", .chest, 3, r.compound),
                e("Lat Pulldown", .back, 3, "10-12 reps"),
                e("Cable Fly", .chest, 2, r.isolation)
            ]
        case "shouldersArms":
            return [
                e("Overhead Press", .shoulders, 4, r.compound),
                e("Lateral Raise", .shoulders, 3, r.isolation),
                e("EZ-Bar Curl", .arms, 3, r.isolation),
                e("Skull Crusher", .arms, 3, r.isolation),
                e("Hammer Curl", .arms, 2, r.isolation),
                e("Rear Delt Fly", .shoulders, 2, r.isolation)
            ]
        case "chest":
            return [
                e("Barbell Bench Press", .chest, 4, r.compound),
                e("Incline Dumbbell Press", .chest, 4, r.compound),
                e("Weighted Dip", .chest, 3, "8-12 reps"),
                e("Cable Fly", .chest, 3, r.isolation),
                e("Push-Up Burnout", .chest, 2, "max reps")
            ]
        case "back":
            return [
                e("Deadlift", .back, 4, r.compound),
                e("Pull Up", .back, 4, r.compound),
                e("Barbell Row", .back, 3, "8-10 reps"),
                e("Seated Cable Row", .back, 3, "10-12 reps"),
                e("Straight Arm Pulldown", .back, 2, r.isolation)
            ]
        case "shoulders":
            return [
                e("Overhead Press", .shoulders, 4, r.compound),
                e("Arnold Press", .shoulders, 3, "10-12 reps"),
                e("Lateral Raise", .shoulders, 4, r.isolation),
                e("Rear Delt Fly", .shoulders, 3, r.isolation),
                e("Face Pull", .shoulders, 3, r.isolation)
            ]
        case "arms":
            return [
                e("Close Grip Bench Press", .arms, 4, r.compound),
                e("EZ Bar Curl", .arms, 4, "8-12 reps"),
                e("Skull Crusher", .arms, 3, r.isolation),
                e("Incline Dumbbell Curl", .arms, 3, r.isolation),
                e("Rope Pushdown", .arms, 3, r.isolation),
                e("Hammer Curl", .arms, 2, r.isolation)
            ]
        default:
            return []
        }
    }

    private static let coreExercises: [(String, String)] = [
        ("Hanging Leg Raise", "12-15 reps"),
        ("Cable Crunch", "12-15 reps"),
        ("Plank", "45-60 sec"),
        ("Russian Twist", "15-20 reps")
    ]

    private static func workout(name: String, focus: String, muscles: [MuscleGroup], profile: UserProfile, scan: BodyScanResult?, tag: String, withCore: Bool) -> PlannedWorkout {
        var list = exercises(for: focus, goal: profile.goal, scan: scan, level: profile.fitnessLevel)
        if withCore {
            for core in coreExercises.prefix(2) {
                list.append(PlannedExercise(name: core.0, muscle: .core, sets: 3, repRange: core.1))
            }
        }
        let totalSets = list.reduce(0) { $0 + $1.sets }
        let duration = min(80, 12 + totalSets * 3)
        var muscleList = muscles
        if withCore && !muscleList.contains(.core) { muscleList.append(.core) }
        return PlannedWorkout(
            name: name,
            muscles: muscleList,
            durationMinutes: duration,
            exercises: list,
            tag: tag,
            restSeconds: restSeconds(for: profile.goal)
        )
    }

    // MARK: Lifting day construction per split

    static func liftingDays(profile: UserProfile, scan: BodyScanResult?) -> [PlannedWorkout] {
        let split = chooseSplit(profile: profile, scan: scan)
        let core = corePlan(profile: profile, scan: scan)
        let days = profile.trainingDaysPerWeek

        // Distribute the prescribed core sessions across lifting days.
        func coreFlags(count: Int) -> [Bool] {
            var flags = [Bool](repeating: false, count: count)
            var remaining = min(core.sessionsPerWeek, count)
            var index = count > 1 ? 1 : 0
            while remaining > 0 && index < count {
                flags[index] = true
                remaining -= 1
                index += 2
            }
            var fill = 0
            while remaining > 0 && fill < count {
                if !flags[fill] { flags[fill] = true; remaining -= 1 }
                fill += 1
            }
            return flags
        }

        func build(_ specs: [(String, String, [MuscleGroup])]) -> [PlannedWorkout] {
            let flags = coreFlags(count: specs.count)
            return specs.enumerated().map { index, spec in
                workout(name: spec.0, focus: spec.1, muscles: spec.2, profile: profile, scan: scan, tag: "Warm up", withCore: flags[index])
            }
        }

        switch split {
        case .fullBody:
            let labels = ["A", "B", "C"]
            let specs: [(String, String, [MuscleGroup])] = (0..<min(days, 3)).map { index in
                ("Full Body \(labels[index])", "fullBody", [.legs, .chest, .back, .shoulders, .arms])
            }
            return build(specs)
        case .upperLower:
            let base: [(String, String, [MuscleGroup])] = [
                ("Upper Body A", "upper", [.chest, .back, .shoulders, .arms]),
                ("Lower Body A", "lower", [.legs]),
                ("Upper Body B", "upper", [.chest, .back, .shoulders, .arms]),
                ("Lower Body B", "lower", [.legs])
            ]
            return build(Array(base.prefix(days)))
        case .ppl:
            return build([
                ("Push Day", "push", [.chest, .shoulders, .arms]),
                ("Pull Day", "pull", [.back, .shoulders, .arms]),
                ("Leg Day", "legs", [.legs])
            ])
        case .pplUpper:
            return build([
                ("Push Day", "push", [.chest, .shoulders, .arms]),
                ("Pull Day", "pull", [.back, .shoulders, .arms]),
                ("Leg Day", "legs", [.legs]),
                ("Upper Body", "upper", [.chest, .back, .shoulders, .arms]),
                ("Leg Day B", "lower", [.legs])
            ])
        case .pplDouble:
            return build([
                ("Push Day A", "push", [.chest, .shoulders, .arms]),
                ("Pull Day A", "pull", [.back, .shoulders, .arms]),
                ("Leg Day A", "legs", [.legs]),
                ("Push Day B", "push", [.chest, .shoulders, .arms]),
                ("Pull Day B", "pull", [.back, .shoulders, .arms]),
                ("Leg Day B", "lower", [.legs])
            ])
        case .arnold:
            let specs: [(String, String, [MuscleGroup])] = [
                ("Chest & Back", "chestBack", [.chest, .back]),
                ("Shoulders & Arms", "shouldersArms", [.shoulders, .arms]),
                ("Leg Day", "legs", [.legs]),
                ("Chest & Back B", "chestBack", [.chest, .back]),
                ("Shoulders & Arms B", "shouldersArms", [.shoulders, .arms]),
                ("Leg Day B", "lower", [.legs])
            ]
            return build(Array(specs.prefix(max(days, 3))))
        case .broSplit:
            let specs: [(String, String, [MuscleGroup])] = [
                ("Chest Day", "chest", [.chest]),
                ("Back Day", "back", [.back]),
                ("Shoulder Day", "shoulders", [.shoulders]),
                ("Leg Day", "legs", [.legs]),
                ("Arm Day", "arms", [.arms]),
                ("Leg Day B", "lower", [.legs])
            ]
            return build(Array(specs.prefix(days)))
        }
    }

    // MARK: Weekly schedule

    static let weekdayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    private static func liftDayIndices(count: Int) -> [Int] {
        switch count {
        case 3: return [0, 2, 4]
        case 4: return [0, 1, 3, 4]
        case 5: return [0, 1, 2, 4, 5]
        default: return [0, 1, 2, 3, 4, 5]
        }
    }

    static func program(profile: UserProfile, scan: BodyScanResult?, sessions: [WorkoutSession] = [], recoveries: [MuscleRecovery] = []) -> TrainingProgram {
        let split = chooseSplit(profile: profile, scan: scan)
        let cardio = cardioPlan(profile: profile, scan: scan)
        let core = corePlan(profile: profile, scan: scan)
        var lifts = adapt(liftingDays(profile: profile, scan: scan), recoveries: recoveries, sessions: sessions)

        // Fat-dominant physiques get short cardio finishers after lifting too.
        if (scan?.bodyType ?? profile.currentBodyType).isFatDominant {
            lifts = lifts.map { lift in
                var copy = lift
                copy.cardioFinisherMinutes = 10
                copy.cardioType = cardio.type
                return copy
            }
        }

        let liftIndices = liftDayIndices(count: lifts.count)
        var week: [(day: String, plan: DayPlan)] = []
        let hasFinishers = (lifts.first?.cardioFinisherMinutes ?? 0) > 0
        var cardioRemaining = max(0, cardio.sessionsPerWeek - (hasFinishers ? 2 : 0))

        var liftIterator = lifts.makeIterator()
        for dayIndex in 0..<7 {
            if liftIndices.contains(dayIndex), let lift = liftIterator.next() {
                week.append((weekdayNames[dayIndex], .lift(lift)))
            } else if cardioRemaining > 0 {
                week.append((weekdayNames[dayIndex], .cardio(cardio.type, minutes: cardio.minutes)))
                cardioRemaining -= 1
            } else {
                week.append((weekdayNames[dayIndex], .rest))
            }
        }

        var notes: [String] = [split.rationale, cardio.note, core.note]
        if let scan {
            let weak = scan.weakest.map(\.rawValue).joined(separator: " and ")
            notes.append("Your scan shows \(weak) lagging the plan adds extra sets there until the gap closes.")
        }
        notes.append(contentsOf: adaptationNotes(recoveries: recoveries, sessions: sessions))

        return TrainingProgram(split: split, week: week, cardio: cardio, core: core, liftingDays: lifts, coachNotes: notes)
    }

    // MARK: Adaptation — learns from history, recovery and new scans

    /// Deloads chronically under-recovered muscles; the scan-driven set
    /// adjustments already re-target weak points every time a new scan lands.
    static func adapt(_ lifts: [PlannedWorkout], recoveries: [MuscleRecovery], sessions: [WorkoutSession]) -> [PlannedWorkout] {
        let overtrained = Set(recoveries.filter(\.warning).map(\.muscle))
        guard !overtrained.isEmpty else { return lifts }

        return lifts.map { lift in
            let adjusted = lift.exercises.map { exercise -> PlannedExercise in
                guard overtrained.contains(exercise.muscle) else { return exercise }
                return PlannedExercise(name: exercise.name, muscle: exercise.muscle, sets: max(2, exercise.sets - 1), repRange: exercise.repRange)
            }
            return PlannedWorkout(
                name: lift.name, muscles: lift.muscles, durationMinutes: lift.durationMinutes,
                exercises: adjusted, tag: lift.tag, restSeconds: lift.restSeconds,
                cardioFinisherMinutes: lift.cardioFinisherMinutes, cardioType: lift.cardioType
            )
        }
    }

    static func adaptationNotes(recoveries: [MuscleRecovery], sessions: [WorkoutSession]) -> [String] {
        var notes: [String] = []
        let overtrained = recoveries.filter(\.warning).map(\.muscle.rawValue)
        if !overtrained.isEmpty {
            notes.append("\(overtrained.joined(separator: ", ")) has been under 60% recovery for 5+ days volume reduced this week to let it rebuild.")
        }
        let thisWeek = sessions.filter { $0.isCompleted && $0.startDate > Date.now.addingTimeInterval(-7 * 86400) }
        if thisWeek.count >= 4 {
            notes.append("You've completed \(thisWeek.count) sessions in 7 days great consistency. Progressive overload will nudge your weights up.")
        }
        return notes
    }

    /// Progressive overload: suggests the next working weight for an exercise
    /// from the user's own history. All planned sets completed last time →
    /// small increase; otherwise repeat the load.
    static func suggestedWeight(for exerciseName: String, in sessions: [WorkoutSession]) -> Double? {
        let logs = sessions
            .filter(\.isCompleted)
            .sorted { ($0.endDate ?? $0.startDate) > ($1.endDate ?? $1.startDate) }
            .flatMap(\.exercises)
            .filter { $0.name == exerciseName && !$0.sets.isEmpty }

        guard let last = logs.first else { return nil }
        let topWeight = last.sets.map(\.weight).max() ?? 0
        guard topWeight > 0 else { return nil }

        let isCompound = ["Squat", "Deadlift", "Bench", "Press", "Row", "Pull Up", "Dip", "Thrust"]
            .contains { exerciseName.contains($0) }
        let increment: Double = isCompound ? 2.5 : 1.0
        return last.isDone ? topWeight + increment : topWeight
    }

    /// Recovery-aware pick for today: takes today's scheduled day, but if the
    /// scheduled muscles are poorly recovered, swaps in the best-recovered
    /// lifting day instead.
    static func todaysWorkout(profile: UserProfile, scan: BodyScanResult?, recoveries: [MuscleRecovery], sessions: [WorkoutSession] = []) -> PlannedWorkout {
        let prog = program(profile: profile, scan: scan, sessions: sessions, recoveries: recoveries)
        let lifts = prog.liftingDays
        guard !lifts.isEmpty else {
            return PlannedWorkout(name: "Full Body", muscles: MuscleGroup.allCases, durationMinutes: 40, exercises: [], tag: "Warm up")
        }

        func score(_ workout: PlannedWorkout) -> Double {
            let values = workout.muscles.compactMap { muscle in
                recoveries.first(where: { $0.muscle == muscle })?.percentage
            }
            guard !values.isEmpty else { return 100 }
            return values.reduce(0, +) / Double(values.count)
        }

        // Scheduled lift for today's weekday, if any.
        let weekdayIndex = (Calendar.current.component(.weekday, from: .now) + 5) % 7 // Mon = 0
        var scheduled: PlannedWorkout? = nil
        if weekdayIndex < prog.week.count, case .lift(let workout) = prog.week[weekdayIndex].plan {
            scheduled = workout
        }

        if let scheduled, score(scheduled) >= 55 {
            return scheduled
        }
        return lifts.max(by: { score($0) < score($1) }) ?? lifts[0]
    }

    /// Today's full plan entry (lift / cardio / rest) for the Home screen.
    static func todaysPlan(profile: UserProfile, scan: BodyScanResult?, recoveries: [MuscleRecovery], sessions: [WorkoutSession] = []) -> DayPlan {
        let prog = program(profile: profile, scan: scan, sessions: sessions, recoveries: recoveries)
        let weekdayIndex = (Calendar.current.component(.weekday, from: .now) + 5) % 7
        guard weekdayIndex < prog.week.count else { return .rest }

        switch prog.week[weekdayIndex].plan {
        case .lift:
            return .lift(todaysWorkout(profile: profile, scan: scan, recoveries: recoveries, sessions: sessions))
        case .cardio(let type, let minutes):
            return .cardio(type, minutes: minutes)
        case .rest:
            return .rest
        }
    }

    static func splitSummary(for days: Int) -> String {
        switch days {
        case 3: return "Push / Pull / Legs"
        case 4: return "Upper / Lower"
        case 5: return "PPL + Upper"
        default: return "PPL × 2"
        }
    }
}
