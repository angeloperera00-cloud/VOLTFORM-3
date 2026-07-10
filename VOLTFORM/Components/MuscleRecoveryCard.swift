import SwiftUI

struct MuscleRecoveryCard: View {
    let recovery: MuscleRecovery

    private var statusColor: Color {
        if recovery.warning || recovery.percentage < 45 { return .voltDanger }
        if recovery.percentage < 75 { return .voltWarning }
        return .voltLimeDeep
    }

    private var chipBackground: Color {
        if recovery.warning { return Color.voltDanger.opacity(0.12) }
        if recovery.chip == "Great" || recovery.chip == "Good trend" { return Color.voltLime.opacity(0.45) }
        return Color.voltSoftGray
    }

    private var chipForeground: Color {
        if recovery.warning { return .voltDanger }
        return .voltTextDark
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: recovery.muscle.icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color.voltTextDark)
                .frame(width: 48, height: 48)
                .background(Color.voltSoftGray)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(recovery.muscle.rawValue)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.voltTextDark)
                HStack(spacing: 4) {
                    Text("\(Int(recovery.percentage.rounded()))%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(statusColor)
                    Text("· \(recovery.status)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.voltTextMuted)
                }
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                    Text(recovery.readyBy.map { "Ready \(VoltFormat.readyBy($0))" } ?? "Ready now")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(Color.voltTextMuted)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 6) {
                Text(recovery.chip)
                    .font(.system(size: 10, weight: .semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(chipBackground)
                    .foregroundStyle(chipForeground)
                    .clipShape(Capsule())

                SparklineChart(points: recovery.trend, tint: statusColor)
                    .frame(width: 96, height: 30)

                HStack(spacing: 0) {
                    ForEach(recovery.trend) { point in
                        Text(point.date.formatted(.dateTime.weekday(.narrow)))
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(Color.voltTextMuted)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(width: 96)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.voltCard)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 5)
    }
}
