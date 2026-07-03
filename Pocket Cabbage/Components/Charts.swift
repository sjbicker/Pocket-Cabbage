//
//  Charts.swift
//  Pocket Cabbage
//
//  Native Swift Charts wrappers for the Money dashboard and learning screens.
//

import SwiftUI
import Charts

/// Vertical bar chart (weekday spend, weekly savings). Highlights one bar in the
/// savings accent to call out the "big shop" day / current week.
struct BarChartView: View {
    struct Bar: Identifiable {
        let id = UUID()
        let label: String
        let value: Double
        var highlighted = false
    }
    let bars: [Bar]
    var valuePrefix = "$"

    var body: some View {
        Chart(bars) { bar in
            BarMark(
                x: .value("Label", bar.label),
                y: .value("Amount", bar.value)
            )
            .foregroundStyle(bar.highlighted ? Color.savings : Color.savings.opacity(0.28))
            .cornerRadius(4)
            .annotation(position: .top, alignment: .center) {
                Text("\(valuePrefix)\(Int(bar.value))")
                    .font(.system(size: 9))
                    .foregroundStyle(bar.highlighted ? Color.savings : .secondary)
            }
        }
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let label = value.as(String.self) {
                        Text(label).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(height: 90)
    }
}

/// Per-store spent-vs-saved paired horizontal bars (4b).
struct StoreBreakdownChart: View {
    let stores: [StoreSpend]
    private var maxValue: Double { max(1, stores.map { $0.spent }.max() ?? 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(stores) { store in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(store.store).font(.subheadline)
                        Spacer()
                        Text("\(moneyString(store.spent)) spent · ")
                            .foregroundStyle(.secondary)
                        + Text("\(moneyString(store.saved)) saved")
                            .foregroundStyle(Color.savings)
                    }
                    .font(.caption)
                    GeometryReader { geo in
                        HStack(spacing: 2) {
                            Capsule().fill(Color.secondary.opacity(0.35))
                                .frame(width: geo.size.width * store.spent / maxValue)
                            Capsule().fill(Color.savings)
                                .frame(width: geo.size.width * store.saved / maxValue)
                        }
                    }
                    .frame(height: 12)
                }
            }
        }
    }
}

/// Rising-dots accuracy trend (5c).
struct AccuracyTrendChart: View {
    let points: [AccuracyPoint]

    var body: some View {
        Chart(Array(points.enumerated()), id: \.offset) { index, point in
            LineMark(x: .value("Month", point.label),
                     y: .value("Accuracy", point.accuracy))
            .foregroundStyle(Color.savings.opacity(0.5))
            PointMark(x: .value("Month", point.label),
                      y: .value("Accuracy", point.accuracy))
            .foregroundStyle(index == points.count - 1 ? Color.savings : Color.secondary)
            .annotation(position: .top) {
                Text("\(Int(point.accuracy * 100))%")
                    .font(.system(size: 9))
                    .foregroundStyle(index == points.count - 1 ? Color.savings : .secondary)
            }
        }
        .chartYAxis(.hidden)
        .chartYScale(domain: 0.7...1.0)
        .frame(height: 90)
    }
}
