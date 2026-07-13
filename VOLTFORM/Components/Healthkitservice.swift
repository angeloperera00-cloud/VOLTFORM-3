import Foundation
import HealthKit

/// Reads age, height, weight, and biological sex from Apple Health, with the
/// user's permission, so onboarding can be pre-filled instead of typed in by
/// hand. Every value is still shown as editable — this only saves time, it
/// never silently overrides what the person enters.
enum HealthKitService {

    struct ImportedProfile {
        var age: Int?
        var heightCm: Double?
        var weightKg: Double?
        var gender: Gender?
    }

    static var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    private static let store = HKHealthStore()

    private static var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = [
            HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!,
            HKObjectType.characteristicType(forIdentifier: .biologicalSex)!
        ]
        if let height = HKObjectType.quantityType(forIdentifier: .height) {
            types.insert(height)
        }
        if let mass = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            types.insert(mass)
        }
        return types
    }

    /// Requests read access, then fetches whatever is available. Any value
    /// the user hasn't logged in Health (or denied access to) comes back nil
    /// rather than failing the whole import.
    static func importProfile() async -> ImportedProfile {
        guard isAvailable else { return ImportedProfile() }

        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
        } catch {
            return ImportedProfile()
        }

        var result = ImportedProfile()
        result.age = fetchAge()
        result.gender = fetchGender()
        result.heightCm = await fetchLatestQuantity(.height, unit: .meterUnit(with: .centi))
        result.weightKg = await fetchLatestQuantity(.bodyMass, unit: .gramUnit(with: .kilo))
        return result
    }

    private static func fetchAge() -> Int? {
        guard let birthday = try? store.dateOfBirthComponents().date else { return nil }
        return Calendar.current.dateComponents([.year], from: birthday, to: .now).year
    }

    private static func fetchGender() -> Gender? {
        guard let sex = try? store.biologicalSex().biologicalSex else { return nil }
        switch sex {
        case .male: return .male
        case .female: return .female
        default: return .other
        }
    }

    private static func fetchLatestQuantity(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double? {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else { return nil }

        return await withCheckedContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: quantityType, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: sample.quantity.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }
}
