//
//  WeekPlanView.swift
//  Pocket Cabbage
//
//  The pre-populated weekly plan (wireframe 2a): a day × meal grid where every
//  slot is filled. Tapping a cell opens a bottom swap sheet with the two AI
//  alternates, a chat field and a reroll. "Optimize" opens the cost optimizer.
//

import SwiftUI

struct WeekPlanView: View {
    @Environment(PlanStore.self) private var planStore
    @Environment(ProfileStore.self) private var profileStore

    @State private var selectedSlot: MealSlot?
    @State private var showOptimizer = false
    @State private var detailRecipe: Recipe?

    private var plan: WeekPlan { planStore.plan }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    grid
                    optimizeCard
                    if let error = planStore.errorMessage {
                        Label(error, systemImage: "wifi.exclamationmark")
                            .font(.caption).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Weekly Plan")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await planStore.generate(profile: profileStore.profile) }
                    } label: {
                        if planStore.isLoading { ProgressView() }
                        else { Image(systemName: "sparkles") }
                    }
                }
            }
            .sheet(item: $selectedSlot) { slot in
                SwapSheet(slot: slot, onViewRecipe: { detailRecipe = $0 })
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showOptimizer) {
                CostOptimizerView()
            }
            .sheet(item: $detailRecipe) { recipe in
                NavigationStack { RecipeDetailView(recipe: recipe) }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(plan.weekLabel).font(.title3.weight(.semibold))
                Text("· ready ✨").foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 8) {
                Text("+\(moneyString(plan.estimatedTotalCost)) to buy")
                    .foregroundStyle(Color.savings)
                Text("· saves \(moneyString(plan.totalSavings))")
                    .foregroundStyle(.secondary)
                if plan.optimized {
                    Chip(text: "optimized 💰", tint: .savings)
                }
            }
            .font(.subheadline)
        }
    }

    // MARK: - Grid

    private var grid: some View {
        Grid(horizontalSpacing: 5, verticalSpacing: 5) {
            GridRow {
                Text("").frame(width: 34)
                ForEach(MealType.allCases) { meal in
                    Text(meal.shortLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            ForEach(plan.days, id: \.self) { day in
                GridRow {
                    Text(WeekPlan.dayNames[(day - 1) % 7])
                        .font(.caption.weight(.medium))
                        .frame(width: 34, alignment: .leading)
                    ForEach(MealType.allCases) { meal in
                        if let slot = plan.slot(day: day, meal: meal) {
                            MealCell(slot: slot) { selectedSlot = slot }
                        } else {
                            Color.clear.frame(height: 52)
                        }
                    }
                }
            }
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var optimizeCard: some View {
        Button { showOptimizer = true } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("💰 Cost optimizer").font(.headline)
                    Text("Compare every ingredient across your ads + Kroger")
                        .font(.caption).foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.savingsFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// A single tappable meal in the week grid.
struct MealCell: View {
    let slot: MealSlot
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text(slot.chosen.title)
                    .font(.caption2)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)
                HStack(spacing: 2) {
                    if slot.chosen.hasDeal { Text(Badge.deal).font(.system(size: 8)) }
                    Text(slot.incrementalCost == 0 ? "$0" : "+\(moneyString(slot.incrementalCost))")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Color.savings)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(4)
            .background(slot.chosen.isKeeper ? Color.savingsFill : Color(.tertiarySystemFill),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    WeekPlanView().withPreviewStores()
}
