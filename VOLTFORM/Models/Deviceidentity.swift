import UIKit

/// Pulls a friendly display name straight from the device itself, so the
/// app doesn't need to ask "what's your name?" during onboarding.
enum DeviceIdentity {

    /// Best-effort real name derived from the device's own name.
    /// "Angelo's iPhone" → "Angelo". "Angelo's Phone" → "Angelo".
    /// Falls back to the raw device name, then to a neutral placeholder.
    static var suggestedUserName: String {
        let deviceName = UIDevice.current.name.trimmingCharacters(in: .whitespacesAndNewlines)

        for marker in ["’s ", "'s "] {
            if let range = deviceName.range(of: marker) {
                let possessive = String(deviceName[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                if !possessive.isEmpty { return possessive }
            }
        }

        return deviceName.isEmpty ? "Athlete" : deviceName
    }
}
