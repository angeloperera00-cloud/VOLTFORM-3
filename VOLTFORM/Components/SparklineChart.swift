import SwiftUI
import Charts

struct SparklineChart: View {
    let points: [TrendPoint]
    var tint: Color = .voltLime

    var body: some View {
        Chart(points) { point in
            LineMark(
                x: .value("Day", point.date),
                y: .value("Recovery", point.value)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(tint)
            .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))

            AreaMark(
                x: .value("Day", point.date),
                y: .value("Recovery", point.value)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(
                LinearGradient(colors: [tint.opacity(0.25), tint.opacity(0.0)], startPoint: .top, endPoint: .bottom)
            )
        }
        .chartYScale(domain: 0...100)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
    }
}
