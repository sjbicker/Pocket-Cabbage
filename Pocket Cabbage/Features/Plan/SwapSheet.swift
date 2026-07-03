//
//  SwapSheet.swift
//  Pocket Cabbage
//
//  The bottom swap sheet from wireframe 2a: shows the two AI alternates for a
//  slot, a chat field to ask Cabbage for something else, and a 🎲 reroll.
//

import SwiftUI

struct SwapSheet: View {
    let slot: MealSlot
    var onViewRecipe: (Recipe) -> Void = { _ in }

    @Environment(PlanStore.self) private var planStore
    @Environment(ProfileStore.self) private var profileStore
    @Environment(\.dismiss) private var dismiss

    @State private var chatText = ""

    private var dayName: String { WeekPlan.dayNames[(slot.day - 1) % 7] }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Capsule().fill(.secondary.opacity(0.3)).frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)

            HStack {
                Text("\(dayName) \(slot.mealType.title) — swap \(slot.chosen.title)?")
                    .font(.headline)
                Spacer()
                Button { dismiss() } label: { Image(systemName: "xmark.circle.fill") }
                    .foregroundStyle(.secondary)
            }

            currentRow

            if slot.alternates.isEmpty {
                Text("Tap 🎲 to get fresh options for this slot.")
                    .font(.subheadline).foregroundStyle(.secondary)
            } else {
                Text("Or swap to:").font(.subheadline).foregroundStyle(.secondary)
                ForEach(slot.alternates) { alternate in
                    alternateRow(alternate)
                }
            }

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                HStack {
                    Image(systemName: "bubble.left")
                    TextField("ask Cabbage for something else…", text: $chatText)
                        .onSubmit { rerollWithHint() }
                }
                .font(.subheadline)
                .padding(.horizontal, 12).padding(.vertical, 10)
                .background(Color(.secondarySystemFill), in: Capsule())

                Button { reroll() } label: {
                    Text("🎲").font(.title3)
                        .padding(10)
                        .background(Color(.secondarySystemFill), in: Circle())
                }
                .disabled(planStore.isLoading)
            }
        }
        .padding()
        .overlay { if planStore.isLoading { ProgressView().controlSize(.large) } }
    }

    private var currentRow: some View {
        Button { onViewRecipe(slot.chosen); dismiss() } label: {
            recipeRow(slot.chosen, highlighted: true, trailingIcon: "chevron.right")
        }
        .buttonStyle(.plain)
    }

    private func alternateRow(_ recipe: Recipe) -> some View {
        Button {
            planStore.choose(recipe, for: slot)
            dismiss()
        } label: {
            recipeRow(recipe, highlighted: false, trailingIcon: "arrow.left.arrow.right")
        }
        .buttonStyle(.plain)
    }

    private func recipeRow(_ recipe: Recipe, highlighted: Bool, trailingIcon: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(recipe.title).font(.subheadline.weight(.medium))
                HStack(spacing: 6) {
                    if let time = recipe.timeMinutes { Text("\(time) min") }
                    if recipe.hasDeal { Text("\(Badge.deal) deal").foregroundStyle(Color.savings) }
                    if recipe.isKeeper { Text("\(Badge.keeper) keeper") }
                }
                .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(recipe.incrementalCost == 0 ? "$0" : "+\(moneyString(recipe.incrementalCost))")
                .font(.subheadline.weight(.semibold)).foregroundStyle(Color.savings)
            Image(systemName: trailingIcon).font(.caption).foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(highlighted ? Color.savingsFill : Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(Color.primary.opacity(0.06)))
    }

    private func reroll() {
        Task {
            await planStore.reroll(slot, profile: profileStore.profile)
            dismiss()
        }
    }

    // Natural-language tweaking (OpenAI chat) isn't a distinct backend endpoint
    // yet; for now a hint triggers a reroll so the slot still changes.
    private func rerollWithHint() {
        guard !chatText.isEmpty else { return }
        reroll()
    }
}

#Preview {
    Color(.systemGroupedBackground)
        .sheet(isPresented: .constant(true)) {
            SwapSheet(slot: SampleData.weekPlan.slots.first { $0.mealType == .dinner }!)
                .withPreviewStores()
                .presentationDetents([.medium, .large])
        }
}
