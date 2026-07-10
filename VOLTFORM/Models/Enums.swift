import Foundation

enum FitnessGoal: String, Codable, CaseIterable, Identifiable {
    case buildMuscle = "Build Muscle"
    case loseFat = "Lose Fat"
    case getLean = "Get Lean"
    case improveStrength = "Improve Strength"
    case stayFit = "Stay Fit"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .buildMuscle: return "figure.strengthtraining.traditional"
        case .loseFat: return "flame"
        case .getLean: return "figure.core.training"
        case .improveStrength: return "dumbbell"
        case .stayFit: return "heart"
        }
    }

    var subtitle: String {
        switch self {
        case .buildMuscle: return "Grow size and strength"
        case .loseFat: return "Drop body fat, keep muscle"
        case .getLean: return "Tight, defined physique"
        case .improveStrength: return "Lift heavier over time"
        case .stayFit: return "Balanced, sustainable training"
        }
    }
}

enum FitnessLevel: String, Codable, CaseIterable, Identifiable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .beginner: return "figure.walk"
        case .intermediate: return "figure.run"
        case .advanced: return "figure.strengthtraining.traditional"
        }
    }

    var subtitle: String {
        switch self {
        case .beginner: return "New or returning after a break"
        case .intermediate: return "Training consistently for 1+ year"
        case .advanced: return "Several years of serious training"
        }
    }

    /// Beginner recovers slower (+15%), advanced recovers faster (-10%).
    var recoveryMultiplier: Double {
        switch self {
        case .beginner: return 1.15
        case .intermediate: return 1.0
        case .advanced: return 0.90
        }
    }

    /// Weekly hard sets per muscle the lifter can productively recover from.
    var weeklySetsPerMuscle: Int {
        switch self {
        case .beginner: return 10
        case .intermediate: return 14
        case .advanced: return 18
        }
    }
}

enum Gender: String, Codable, CaseIterable, Identifiable {
    case male = "Male"
    case female = "Female"
    case other = "Other"
    var id: String { rawValue }
}

// MARK: - BodyType (somatotype + composition classes)

enum BodyType: String, Codable, CaseIterable, Identifiable {
    case ectomorph = "Ectomorph"
    case mesomorph = "Mesomorph"
    case endomorph = "Endomorph"
    case skinnyFat = "Skinny Fat"
    case overweight = "Overweight"
    case lean = "Lean"
    case athletic = "Athletic"
    case muscular = "Muscular"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .ectomorph, .lean: return "figure.walk"
        case .mesomorph, .athletic: return "figure.run"
        case .muscular: return "figure.strengthtraining.traditional"
        case .skinnyFat: return "figure.cooldown"
        case .endomorph, .overweight: return "figure.stand"
        }
    }

    var subtitle: String {
        switch self {
        case .ectomorph: return "Naturally thin, fast metabolism, hard gainer"
        case .mesomorph: return "Builds muscle easily, responsive to training"
        case .endomorph: return "Gains easily, slower metabolism"
        case .skinnyFat: return "Low muscle with higher fat on a light frame"
        case .overweight: return "Higher body fat to work from"
        case .lean: return "Low body fat, light frame"
        case .athletic: return "Balanced muscle and definition"
        case .muscular: return "Maximum size and mass"
        }
    }

    /// Options selectable as a dream body.
    static var dreamOptions: [BodyType] { [.lean, .athletic, .muscular] }

    /// Does this physique carry excess fat that training should prioritize?
    var isFatDominant: Bool {
        self == .endomorph || self == .overweight || self == .skinnyFat
    }

    /// Is this physique under-muscled relative to frame?
    var isMuscleDeficient: Bool {
        self == .ectomorph || self == .skinnyFat || self == .lean
    }
}

enum SleepAverage: String, Codable, CaseIterable, Identifiable {
    case fiveToSix = "5-6 hours"
    case sevenToEight = "7-8 hours"
    case eightPlus = "8+ hours"

    var id: String { rawValue }

    var hours: Double {
        switch self {
        case .fiveToSix: return 5.5
        case .sevenToEight: return 7.5
        case .eightPlus: return 8.5
        }
    }

    /// Low sleep slows recovery (+15%).
    var recoveryMultiplier: Double {
        switch self {
        case .fiveToSix: return 1.15
        case .sevenToEight: return 1.0
        case .eightPlus: return 0.98
        }
    }
}

enum SorenessLevel: String, Codable, CaseIterable, Identifiable {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"

    var id: String { rawValue }

    /// High soreness slows recovery (+20%).
    var recoveryMultiplier: Double {
        switch self {
        case .low: return 1.0
        case .moderate: return 1.05
        case .high: return 1.20
        }
    }
}

enum HydrationLevel: String, Codable, CaseIterable, Identifiable {
    case low = "Low"
    case moderate = "Moderate"
    case good = "Good"

    var id: String { rawValue }

    /// Good hydration speeds recovery (-3%), low hydration slows it (+6%).
    var recoveryMultiplier: Double {
        switch self {
        case .low: return 1.06
        case .moderate: return 1.0
        case .good: return 0.97
        }
    }
}

enum MuscleGroup: String, Codable, CaseIterable, Identifiable, Hashable {
    case chest = "Chest"
    case shoulders = "Shoulders"
    case arms = "Arms"
    case core = "Core"
    case back = "Back"
    case legs = "Legs"

    var id: String { rawValue }

    /// Base full-recovery window in hours before any modifiers.
    var baseRecoveryHours: Double {
        switch self {
        case .chest: return 48
        case .shoulders: return 48
        case .arms: return 48
        case .core: return 36
        case .back: return 72
        case .legs: return 72
        }
    }

    var icon: String {
        switch self {
        case .chest: return "figure.arms.open"
        case .shoulders: return "figure.mixed.cardio"
        case .arms: return "dumbbell"
        case .core: return "figure.core.training"
        case .back: return "figure.climbing"
        case .legs: return "figure.run"
        }
    }
}

enum WorkoutIntensity: String, Codable, CaseIterable, Identifiable {
    case light = "Light"
    case moderate = "Moderate"
    case intense = "Intense"

    var id: String { rawValue }

    /// Approximate completed sets per muscle for manually logged workouts.
    var estimatedSetsPerMuscle: Int {
        switch self {
        case .light: return 3
        case .moderate: return 4
        case .intense: return 6
        }
    }
}

// MARK: - Training program vocabulary

enum SplitType: String, Codable, CaseIterable {
    case fullBody = "Full Body"
    case upperLower = "Upper / Lower"
    case ppl = "Push / Pull / Legs"
    case pplUpper = "PPL + Upper"
    case pplDouble = "PPL × 2"
    case arnold = "Arnold Split"
    case broSplit = "Bro Split"

    /// Why the engine picks this split — surfaced in the UI as coach reasoning.
    var rationale: String {
        switch self {
        case .fullBody: return "Hits every muscle 3× per week the fastest way to build a base and burn calories."
        case .upperLower: return "Trains each muscle 2× per week with enough recovery between sessions."
        case .ppl: return "Groups muscles that work together, so nothing interferes with recovery."
        case .pplUpper: return "PPL base plus an extra upper day to bring up your weaker upper-body muscles."
        case .pplDouble: return "Every muscle trained twice per week maximum growth stimulus for experienced lifters."
        case .arnold: return "Chest/back supersets and a dedicated shoulder-arm day a physique focused split."
        case .broSplit: return "One muscle per day with very high volume each muscle gets a full week to recover."
        }
    }
}

enum CardioType: String, Codable, CaseIterable {
    case walking = "Incline Walking"
    case cycling = "Cycling"
    case running = "Running"
    case hiit = "HIIT"

    var icon: String {
        switch self {
        case .walking: return "figure.walk"
        case .cycling: return "figure.outdoor.cycle"
        case .running: return "figure.run"
        case .hiit: return "bolt.fill"
        }
    }
}
