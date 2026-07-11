import Foundation

// Analysis engine driven by the body scan + profile data.
// The interface is designed so a real Vision/CoreML pipeline can replace the
// internals later: feed it frames, return the same BodyScanResult shape.
enum BodyAnalysisEngine {

    static func analyze(profile: UserProfile) -> BodyScanResult {
        let heightM = max(profile.heightCm, 100) / 100
        let bmi = profile.weightKg / (heightM * heightM)

        // --- Body fat estimate ---
        var bodyFat: Double
        switch profile.gender {
        case .male: bodyFat = max(8, min(34, bmi * 1.05 - 8))
        case .female: bodyFat = max(14, min(42, bmi * 1.05 + 2))
        case .other: bodyFat = max(10, min(38, bmi * 1.05 - 3))
        }
        switch profile.fitnessLevel {
        case .beginner: bodyFat += 1
        case .intermediate: break
        case .advanced: bodyFat = max(6, bodyFat - 3)
        }

        let highFat = profile.gender == .female ? bodyFat > 32 : bodyFat > 22
        let lowFat = profile.gender == .female ? bodyFat < 22 : bodyFat < 14

        // --- Somatotype / composition classification ---
        let bodyType: BodyType
        switch true {
        case bmi >= 30:
            bodyType = .overweight
        case bmi >= 27 && profile.fitnessLevel == .advanced && !highFat:
            bodyType = .muscular
        case bmi >= 26.5:
            bodyType = .endomorph
        case bmi < 25 && highFat:
            bodyType = .skinnyFat
        case bmi < 19.5:
            bodyType = .ectomorph
        case lowFat && profile.fitnessLevel != .beginner:
            bodyType = bmi >= 23.5 ? .athletic : .lean
        case profile.fitnessLevel == .advanced:
            bodyType = .athletic
        default:
            bodyType = .mesomorph
        }

        // --- Lean mass estimate ---
        var muscleMass = profile.weightKg * (1 - bodyFat / 100) * (profile.gender == .male ? 0.62 : 0.55)
        if profile.fitnessLevel == .advanced { muscleMass *= 1.05 }

        // --- Metabolic age ---
        var metabolicAge = profile.age
        switch profile.fitnessLevel {
        case .beginner: metabolicAge += 2
        case .intermediate: metabolicAge -= 2
        case .advanced: metabolicAge -= 4
        }
        if lowFat { metabolicAge -= 1 } else if highFat { metabolicAge += 3 }
        metabolicAge = max(18, metabolicAge)

        // --- Per-muscle development distribution (0-100) ---
        // Baseline shifts with body type; per muscle noise creates the
        // individual imbalances the program engine trains against.
        let baseline: Int
        switch bodyType {
        case .muscular: baseline = 78
        case .athletic: baseline = 68
        case .mesomorph: baseline = 62
        case .lean: baseline = 56
        case .endomorph: baseline = 52
        case .overweight: baseline = 46
        case .skinnyFat: baseline = 42
        case .ectomorph: baseline = 40
        }

        var distribution: [MuscleGroup: Int] = [:]
        for muscle in MuscleGroup.allCases {
            var score = baseline + Int.random(in: -9...9)
            // Common real-world biases: mirror muscles ahead of posterior chain.
            if muscle == .chest || muscle == .arms { score += Int.random(in: 0...5) }
            if muscle == .legs || muscle == .back { score -= Int.random(in: 0...6) }
            if bodyType == .skinnyFat && muscle == .core { score -= 5 }
            distribution[muscle] = max(20, min(96, score))
        }

        let sorted = distribution.sorted { $0.value < $1.value }
        let weakest = sorted.prefix(2).map(\.key)
        let strongest = sorted.suffix(2).map(\.key).reversed()

        // Big spread between best and worst muscle = imbalance → worse symmetry.
        let spread = (sorted.last?.value ?? 60) - (sorted.first?.value ?? 60)
        let symmetryScore = max(70, min(96, 96 - spread))
        let postureScore = Int.random(in: 80...94)

        return BodyScanResult(
            date: .now,
            bodyType: bodyType,
            bodyFatPercent: (bodyFat * 10).rounded() / 10,
            muscleMassKg: (muscleMass * 10).rounded() / 10,
            metabolicAge: metabolicAge,
            postureScore: postureScore,
            symmetryScore: symmetryScore,
            strongest: Array(strongest),
            weakest: Array(weakest),
            suggestedFocus: Array(weakest),
            muscleDistribution: distribution
        )
    }
}
