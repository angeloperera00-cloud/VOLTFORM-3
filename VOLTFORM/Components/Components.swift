import SwiftUI

// MARK: - PrimaryButton

struct PrimaryButton: View {
    enum Style { case black, lime }

    let title: String
    var icon: String? = nil
    var style: Style = .black
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(style == .black ? Color.voltBlack : Color.voltLime)
            .foregroundStyle(style == .black ? Color.white : Color.voltOnLime)
            .clipShape(Capsule())
            .opacity(isDisabled ? 0.4 : 1)
        }
        .disabled(isDisabled)
        .buttonStyle(.plain)
    }
}

// MARK: - OptionCard

struct OptionCard: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(isSelected ? Color.voltOnLime : Color.voltTextDark)
                        .frame(width: 40, height: 40)
                        .background(isSelected ? Color.voltOnLime.opacity(0.08) : Color.voltSoftGray)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.voltOnLime : Color.voltTextDark)
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.voltTextMuted)
                    }
                }
                Spacer()
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.voltOnLime : Color.voltTextMuted.opacity(0.35), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(Color.voltOnLime)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(16)
            .background(isSelected ? Color.voltLime : Color.voltCard)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(isSelected ? 0.07 : 0.04), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - MetricCard

struct MetricCard: View {
    let icon: String
    let title: String
    let value: String
    var caption: String? = nil
    var captionColor: Color = .voltLimeDeep
    var dark: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.voltOnLime)
                    .frame(width: 28, height: 28)
                    .background(Color.voltLime.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(dark ? Color.white.opacity(0.6) : Color.voltTextMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(dark ? .white : Color.voltTextDark)
            if let caption {
                Text(caption)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(captionColor)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(dark ? Color.voltDarkCard : Color.voltCard)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(dark ? 0 : 0.04), radius: 10, x: 0, y: 5)
    }
}

// MARK: - RecoveryRing

struct RecoveryRing: View {
    let percentage: Double
    var size: CGFloat = 96
    var lineWidth: CGFloat = 10
    var showLabel: Bool = true
    var caption: String? = nil
    var tint: Color = .voltLime
    var track: Color = .voltSoftGray
    var labelColor: Color = .voltTextDark

    var body: some View {
        ZStack {
            Circle()
                .stroke(track, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: CGFloat(min(1, percentage / 100)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.8), value: percentage)
            if showLabel {
                VStack(spacing: 0) {
                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text("\(Int(percentage.rounded()))")
                            .font(.system(size: size * 0.26, weight: .bold))
                        Text("%")
                            .font(.system(size: size * 0.13, weight: .semibold))
                    }
                    .foregroundStyle(labelColor)
                    if let caption {
                        Text(caption)
                            .font(.system(size: size * 0.10, weight: .medium))
                            .foregroundStyle(Color.voltTextMuted)
                    }
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - ScanCorners

struct ScanCorners: Shape {
    var length: CGFloat = 32
    var radius: CGFloat = 18

    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Top-left
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + length))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(to: CGPoint(x: rect.minX + radius, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + length, y: rect.minY))
        // Top-right
        path.move(to: CGPoint(x: rect.maxX - length, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + radius), control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + length))
        // Bottom-right
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - length))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - radius, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - length, y: rect.maxY))
        // Bottom-left
        path.move(to: CGPoint(x: rect.minX + length, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - radius), control: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - length))
        return path
    }
}

// MARK: - BodyFigurePlaceholder

struct BodyFigurePlaceholder: View {
    var dark: Bool = false
    var highlighted: Bool = true
    var symbol: String = "figure.arms.open"

    var body: some View {
        Image(systemName: symbol)
            .resizable()
            .scaledToFit()
            .foregroundStyle(
                highlighted
                ? AnyShapeStyle(
                    LinearGradient(
                        colors: [Color.voltLime, dark ? Color.white.opacity(0.30) : Color.voltTextDark.opacity(0.30)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                : AnyShapeStyle(dark ? Color.white.opacity(0.25) : Color.voltTextMuted.opacity(0.4))
            )
    }
}

// MARK: - WorkoutExerciseRow

struct WorkoutExerciseRow: View {
    let index: Int
    let name: String
    let detail: String
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text("\(index).")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.voltTextMuted)
                .frame(width: 22, alignment: .leading)
            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.voltTextDark)
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.voltTextMuted)
            }
            Spacer()
            ZStack {
                Circle()
                    .strokeBorder(isCompleted ? Color.voltLimeDeep : Color.voltTextMuted.opacity(0.3), lineWidth: 1.5)
                    .background(Circle().fill(isCompleted ? Color.voltLime : Color.clear))
                    .frame(width: 26, height: 26)
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.voltOnLime)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - DarkWorkoutCard

struct DarkWorkoutCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.voltDarkCard)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
            )
    }
}

// MARK: - PillSegmentedControl

struct PillSegmentedControl: View {
    let options: [String]
    @Binding var selection: Int
    var dark: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options.indices, id: \.self) { index in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selection = index }
                } label: {
                    Text(options[index])
                        .font(.system(size: 14, weight: selection == index ? .semibold : .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(selection == index ? (dark ? Color.voltLime : Color.voltCard) : Color.clear)
                        .foregroundStyle(selection == index ? (dark ? Color.voltOnLime : Color.voltTextDark) : (dark ? Color.white.opacity(0.6) : Color.voltTextMuted))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(dark ? Color.white.opacity(0.08) : Color.voltSoftGray)
        .clipShape(Capsule())
    }
}

// MARK: - BottomTabBar

enum VoltTab: String, CaseIterable {
    case home = "Home"
    case workout = "Workout"
    case body = "Twin"
    case recovery = "Recovery"
    case profile = "Profile"

    var icon: String {
        switch self {
        case .home: return "house"
        case .workout: return "dumbbell"
        case .body: return "person.2"
        case .recovery: return "bolt.heart"
        case .profile: return "person"
        }
    }

    /// Icon shown when this tab is selected. All icons here have a proper
    /// ".fill" counterpart.
    var selectedIcon: String {
        "\(icon).fill"
    }
}

struct BottomTabBar: View {
    @Binding var selected: VoltTab

    var body: some View {
        HStack(alignment: .bottom) {
            tabButton(.home)
            tabButton(.workout)
            tabButton(.body)
            tabButton(.recovery)
            tabButton(.profile)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 6)
        .background(
            Color.voltOffWhite
                .overlay(alignment: .top) {
                    Rectangle().fill(Color.black.opacity(0.06)).frame(height: 0.5)
                }
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabButton(_ tab: VoltTab) -> some View {
        Button {
            selected = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: selected == tab ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 20, weight: .medium))
                Text(tab.rawValue)
                    .font(.system(size: 10, weight: .medium))
                Capsule()
                    .fill(selected == tab ? Color.voltLime : Color.clear)
                    .frame(width: 16, height: 3)
            }
            .foregroundStyle(selected == tab ? Color.voltTextDark : Color.voltTextMuted)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - MuscleRecoveryFigure

/// A simplified front-view body diagram built from basic shapes (no external
/// art asset available), where each region is colored by that muscle
/// group's actual current recovery percentage — so it visually answers
/// "where am I recovered, where am I still recovering, where do I need to
/// rest" at a glance, using the same color thresholds as the Recovery tab.
/// A vertical shape that tapers between a top width and bottom width (as
/// fractions of the available width), with rounded ends — gives limbs and
/// the torso a more natural silhouette than a uniform capsule or rectangle.
private struct TaperedCapsule: Shape {
    var topWidth: CGFloat
    var bottomWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        let topW = rect.width * topWidth
        let bottomW = rect.width * bottomWidth
        let topInset = (rect.width - topW) / 2
        let bottomInset = (rect.width - bottomW) / 2
        let radius = min(topW, bottomW, rect.height) / 2

        var path = Path()
        path.move(to: CGPoint(x: rect.minX + topInset + radius, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - topInset - radius, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - topInset - radius, y: rect.minY + radius),
                    radius: radius, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX - bottomInset, y: rect.maxY - radius))
        path.addArc(center: CGPoint(x: rect.maxX - bottomInset - radius, y: rect.maxY - radius),
                    radius: radius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX + bottomInset + radius, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.minX + bottomInset + radius, y: rect.maxY - radius),
                    radius: radius, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX + topInset, y: rect.minY + radius))
        path.addArc(center: CGPoint(x: rect.minX + topInset + radius, y: rect.minY + radius),
                    radius: radius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        path.closeSubpath()
        return path
    }
}

struct MuscleRecoveryFigure: View {
    let recoveries: [MuscleGroup: Double]
    var unknownColor: Color = .white.opacity(0.15)

    private func color(for muscle: MuscleGroup) -> Color {
        guard let percentage = recoveries[muscle] else { return unknownColor }
        if percentage < 45 { return .voltDanger }
        if percentage < 75 { return .voltWarning }
        return .voltLimeDeep
    }

    private var shadow: Color { .black.opacity(0.25) }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Legs — tapered thigh-to-ankle, angled slightly outward
                HStack(spacing: w * 0.05) {
                    TaperedCapsule(topWidth: 1.0, bottomWidth: 0.6)
                        .fill(color(for: .legs))
                        .frame(width: w * 0.17, height: h * 0.38)
                        .rotationEffect(.degrees(-4), anchor: .top)
                    TaperedCapsule(topWidth: 1.0, bottomWidth: 0.6)
                        .fill(color(for: .legs))
                        .frame(width: w * 0.17, height: h * 0.38)
                        .rotationEffect(.degrees(4), anchor: .top)
                }
                .shadow(color: shadow, radius: 3, x: 0, y: 2)
                .position(x: w * 0.5, y: h * 0.79)

                // Arms — tapered bicep-to-wrist, angled outward from the shoulders
                HStack(spacing: w * 0.48) {
                    TaperedCapsule(topWidth: 0.9, bottomWidth: 0.55)
                        .fill(color(for: .arms))
                        .frame(width: w * 0.14, height: h * 0.36)
                        .rotationEffect(.degrees(-7), anchor: .top)
                    TaperedCapsule(topWidth: 0.9, bottomWidth: 0.55)
                        .fill(color(for: .arms))
                        .frame(width: w * 0.14, height: h * 0.36)
                        .rotationEffect(.degrees(7), anchor: .top)
                }
                .shadow(color: shadow, radius: 3, x: 0, y: 2)
                .position(x: w * 0.5, y: h * 0.42)

                // Chest / back (combined torso — a flat front-view diagram
                // can't separate front vs. back, so this represents both),
                // tapered wider at the shoulders than the waist
                TaperedCapsule(topWidth: 1.0, bottomWidth: 0.72)
                    .fill(color(for: .chest))
                    .frame(width: w * 0.42, height: h * 0.24)
                    .shadow(color: shadow, radius: 3, x: 0, y: 2)
                    .position(x: w * 0.5, y: h * 0.31)

                // Core, continuing the taper down toward the hips
                TaperedCapsule(topWidth: 0.8, bottomWidth: 0.68)
                    .fill(color(for: .core))
                    .frame(width: w * 0.30, height: h * 0.15)
                    .shadow(color: shadow, radius: 2, x: 0, y: 2)
                    .position(x: w * 0.5, y: h * 0.48)

                // Shoulders
                HStack(spacing: w * 0.40) {
                    Circle().fill(color(for: .shoulders)).frame(width: w * 0.15, height: w * 0.15)
                    Circle().fill(color(for: .shoulders)).frame(width: w * 0.15, height: w * 0.15)
                }
                .shadow(color: shadow, radius: 2, x: 0, y: 2)
                .position(x: w * 0.5, y: h * 0.21)

                // Neck
                RoundedRectangle(cornerRadius: w * 0.02, style: .continuous)
                    .fill(Color.white.opacity(0.55))
                    .frame(width: w * 0.10, height: h * 0.045)
                    .position(x: w * 0.5, y: h * 0.115)

                // Head (decorative, not tied to a muscle group)
                Circle()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: w * 0.19, height: w * 0.19)
                    .shadow(color: shadow, radius: 2, x: 0, y: 2)
                    .position(x: w * 0.5, y: h * 0.07)
            }
        }
    }
}

/// Small legend explaining the color coding used by MuscleRecoveryFigure.
struct MuscleRecoveryLegend: View {
    var body: some View {
        HStack(spacing: 14) {
            legendItem(color: .voltLimeDeep, label: "Ready")
            legendItem(color: .voltWarning, label: "Recovering")
            legendItem(color: .voltDanger, label: "Needs rest")
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
                .lineLimit(1)
                .fixedSize()
        }
    }
}

// MARK: - AnatomicalBodyFigureView

/// Displays the provided anatomical reference illustration. Unlike
/// MuscleRecoveryFigure, this is a single flattened image (not separated
/// per-muscle layers), so its colors are fixed at the asset level rather
/// than driven by live recovery data.
struct AnatomicalBodyFigureView: View {
    var body: some View {
        Image("AnatomicalBodyFigure")
            .resizable()
            .scaledToFit()
    }
}
