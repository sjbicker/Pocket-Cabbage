//
//  LearningView.swift
//  Pocket Cabbage
//
//  Wireframe 5c: shows the payoff of receipt data — a rising projection-accuracy
//  trend and cheaper-swap suggestions grounded in real paid prices + ratings.
//

import SwiftUI

struct LearningView: View {
    @Environment(DashboardStore.self) private var dashboardStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Your numbers, getting sharper 🧠").font(.title3.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Projection accuracy").font(.subheadline).foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(dashboardStore.projectionAccuracy * 100))%")
                            .font(.headline).foregroundStyle(Color.savings)
                    }
                    AccuracyTrendChart(points: dashboardStore.accuracyTrend)
                    Text("Every receipt you snap tightens the estimates.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .card()

                Text("Cheaper swaps found from your real prices:").font(.subheadline)
                ForEach(dashboardStore.learningSwaps) { swap in
                    swapCard(swap)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Insights")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func swapCard(_ swap: LearningSwap) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(swap.from) → ").foregroundStyle(.secondary)
                    + Text(swap.to).fontWeight(.semibold)
                Spacer()
                Text("−\(moneyString(swap.savings))\(swap.cadence)")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(Color.savings)
            }
            Text(swap.rationale).font(.caption).foregroundStyle(.secondary)
        }
        .padding()
        .background(swap.highlighted ? Color.savingsFill : Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12)
            .strokeBorder(swap.highlighted ? Color.savings.opacity(0.4) : Color.primary.opacity(0.06)))
    }
}

#Preview {
    NavigationStack { LearningView() }.withPreviewStores()
}
