import SwiftUI

extension Color {
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: 1.0
        )
    }

    static let voltLime = Color(hex: 0xC8FF3D)
    static let voltLimeDeep = Color(hex: 0x86B818)
    static let voltViolet = Color(hex: 0x2D1B69)
    static let voltBlack = Color(hex: 0x050505)
    static let voltOffWhite = Color(hex: 0x0A0A09)       // screen background (was off-white)
    static let voltCard = Color(hex: 0x161614)           // card surface (was white)
    static let voltSoftGray = Color(hex: 0x1E1E1B)       // muted chip/icon backgrounds (was pale gray)
    static let voltTextDark = Color(hex: 0xF7F6F0)       // primary text/icons on the new dark surfaces (was near-black)
    static let voltTextMuted = Color(hex: 0x9C9C95)      // secondary text, lightened for legibility on black
    static let voltDarkCard = Color(hex: 0x151513)
    static let voltWarning = Color(hex: 0xE8A13C)
    static let voltDanger = Color(hex: 0xE84545)
    /// Warm gold used for "moderate/developing" states — sits between lime
    /// and red in hue rather than a flat system-amber, so it reads as part
    /// of the app's own palette instead of a generic warning color.
    static let voltGold = Color(hex: 0xD9B34F)
    /// Dedicated dark ink for content placed directly on a lime-colored fill
    /// (buttons, tag pills, selected chips) — kept dark even though
    /// voltTextDark itself is now light, so lime surfaces stay readable.
    static let voltOnLime = Color(hex: 0x121212)
}

extension View {
    /// Standard VOLTFORM rounded card with soft shadow.
    func voltCard(dark: Bool = false, radius: CGFloat = 24, padding: CGFloat = 18) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(dark ? Color.voltDarkCard : Color.voltCard)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(dark ? Color.white.opacity(0.07) : Color.clear, lineWidth: 1)
            )
            .shadow(color: .black.opacity(dark ? 0 : 0.05), radius: 12, x: 0, y: 6)
    }
}

enum VoltFormat {
    static func readyBy(_ date: Date) -> String {
        let calendar = Calendar.current
        let time = date.formatted(date: .omitted, time: .shortened)
        if calendar.isDateInToday(date) { return "Today, \(time)" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow, \(time)" }
        let day = date.formatted(.dateTime.weekday(.abbreviated))
        return "\(day), \(time)"
    }

    static func hoursMinutes(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int(((hours - Double(h)) * 60).rounded())
        return "\(h)h \(m)m"
    }
}
