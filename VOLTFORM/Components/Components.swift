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
    case recovery = "Recovery"
    case profile = "Profile"

    var icon: String {
        switch self {
        case .home: return "house"
        case .workout: return "dumbbell"
        case .recovery: return "bolt.heart"
        case .profile: return "person"
        }
    }
}

struct BottomTabBar: View {
    @Binding var selected: VoltTab
    let onBodyScan: () -> Void

    var body: some View {
        HStack(alignment: .bottom) {
            tabButton(.home)
            tabButton(.workout)
            scanButton
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
                Image(systemName: selected == tab ? "\(tab.icon).fill" : tab.icon)
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

    /// Same icon+label+underline layout and sizing as the other tabs, but
    /// always lime-tinted since this is an action button, not a navigable
    /// tab with a selected/unselected state.
    private var scanButton: some View {
        Button(action: onBodyScan) {
            VStack(spacing: 4) {
                Image(systemName: "figure.stand")
                    .font(.system(size: 20, weight: .medium))
                Text("Scan")
                    .font(.system(size: 10, weight: .medium))
                Capsule()
                    .fill(Color.clear)
                    .frame(width: 16, height: 3)
            }
            .foregroundStyle(Color.voltTextMuted)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
