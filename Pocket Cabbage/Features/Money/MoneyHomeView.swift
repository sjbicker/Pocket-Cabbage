//
//  MoneyHomeView.swift
//  Pocket Cabbage
//
//  The home tab (wireframes 5a + 4b): at-a-glance budget health — spent/saved/
//  per-meal stats, spend-by-weekday chart, receipt-scan CTA, projection-accuracy
//  chip, per-store breakdown and weekly savings.
//

import SwiftUI

struct MoneyHomeView: View {
    @Environment(DashboardStore.self) private var dashboardStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if dashboardStore.daysSinceLastSync() > 13 {
                        syncBanner
                    }
                    statCards
                    weekdayCard
                    receiptCTA
                    accuracyChip
                    storeBreakdownCard
                    weeklySavingsCard
                    NavigationLink { SavingsReceiptView() } label: {
                        Label("This month's savings receipt", systemImage: "scroll")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground),
                                        in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("🥬 PocketCabbage")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Text(Date.now, format: .dateTime.month(.wide)).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var syncBanner: some View {
        Label("Pantry sync due — last scan over 13 days ago.", systemImage: "clock.badge.exclamationmark")
            .font(.caption).foregroundStyle(Color.overBudget)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.overBudgetFill, in: RoundedRectangle(cornerRadius: 12))
    }

    private var statCards: some View {
        HStack(spacing: 8) {
            StatCard(label: "Spent", value: moneyString(dashboardStore.spent))
            StatCard(label: "Saved", value: moneyString(dashboardStore.saved), highlighted: true)
            StatCard(label: "Per meal", value: moneyString(dashboardStore.costPerMeal))
        }
    }

    private var weekdayCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Grocery spend by weekday").font(.subheadline).foregroundStyle(.secondary)
                Spacer()
                Text("avg, this month").font(.caption2).foregroundStyle(.tertiary)
            }
            BarChartView(bars: dashboardStore.weekdaySpend.map {
                .init(label: $0.weekday, value: $0.amount, highlighted: $0.isBigShop)
            })
            Text("Saturday = big shop day · midweek top-ups $4–12")
                .font(.caption).foregroundStyle(.secondary)
        }
        .card()
    }

    private var receiptCTA: some View {
        NavigationLink { ReceiptReconcileView() } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("🧾 Snap your receipt").font(.subheadline.weight(.semibold))
                    Text("reconcile planned vs actual spend")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "camera.circle.fill").font(.largeTitle).foregroundStyle(Color.savings)
            }
            .padding()
            .background(Color.savingsFill, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var accuracyChip: some View {
        NavigationLink { LearningView() } label: {
            HStack {
                Text("📊 Projection accuracy: ")
                    + Text("\(Int(dashboardStore.projectionAccuracy * 100))%").foregroundColor(.savings).bold()
                Spacer()
                Text("how? →").foregroundStyle(.secondary)
            }
            .font(.subheadline)
            .padding()
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private var storeBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("By store · spent vs saved").font(.subheadline).foregroundStyle(.secondary)
            StoreBreakdownChart(stores: dashboardStore.storeSpend)
        }
        .card()
    }

    private var weeklySavingsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Savings per week").font(.subheadline).foregroundStyle(.secondary)
            BarChartView(bars: dashboardStore.weeklySavings.map {
                .init(label: $0.label, value: $0.amount, highlighted: $0.isCurrent)
            })
        }
        .card()
    }
}

#Preview {
    MoneyHomeView().withPreviewStores()
}
