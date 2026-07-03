//
//  RecipeDetailView.swift
//  Pocket Cabbage
//
//  Wireframe 1j: hero, incremental cost, meta, owned-vs-buy split, full step
//  instructions, and 👍/👎 that teaches the recommender + saves to the Recipe Box.
//

import SwiftUI
import SwiftData

struct RecipeDetailView: View {
    let recipe: Recipe

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var rated: Bool?

    private var toBuyTotal: Double { recipe.toBuy.compactMap(\.price).reduce(0, +) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PlaceholderImage(systemImage: "fork.knife", height: 150)

                HStack(alignment: .firstTextBaseline) {
                    Text(recipe.title).font(.title2.weight(.semibold))
                    Spacer()
                    Text("+\(moneyString(recipe.incrementalCost))")
                        .font(.headline).foregroundStyle(Color.savings)
                }

                metaRow
                ownedBuyStrip

                sectionTitle("Ingredients")
                ForEach(recipe.ingredients) { ingredient in
                    ingredientRow(ingredient)
                }

                sectionTitle("Steps")
                ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)").font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.savings)
                            .frame(width: 22)
                        Text(step).font(.subheadline)
                    }
                }

                feedbackRow
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Recipe")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var metaRow: some View {
        HStack(spacing: 6) {
            if let time = recipe.timeMinutes { Label("\(time) min", systemImage: "clock") }
            Text("· serves \(recipe.servings)")
            ForEach(recipe.dietFlags, id: \.self) { Text("· \($0) ✓") }
            Text("· \(recipe.source)")
        }
        .font(.caption).foregroundStyle(.secondary)
    }

    private var ownedBuyStrip: some View {
        HStack(spacing: 0) {
            VStack { Text("\(recipe.ownedCount) items").font(.headline); Text("you own").font(.caption) }
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(Color.savingsFill)
            VStack {
                Text("\(recipe.toBuy.count) to buy").font(.headline)
                Text("\(moneyString(toBuyTotal))\(recipe.hasDeal ? " · deal 🔥" : "")").font(.caption)
                    .foregroundStyle(Color.savings)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 12)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.primary.opacity(0.08)))
    }

    private func ingredientRow(_ ingredient: Ingredient) -> some View {
        HStack {
            Image(systemName: ingredient.owned ? "checkmark.circle.fill" : "cart")
                .foregroundStyle(ingredient.owned ? Color.savings : .secondary)
            Text(ingredient.name)
            Spacer()
            if !ingredient.owned, let price = ingredient.price {
                Text("\(moneyString(price))\(ingredient.onSale ? " 🔥" : "")")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(ingredient.onSale ? Color.savings : .primary)
                if let store = ingredient.store {
                    Text("@\(store)").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .font(.subheadline)
    }

    private var feedbackRow: some View {
        HStack {
            Text(rated == true ? "Saved to your Recipe Box \(Badge.keeper)"
                 : rated == false ? "Got it — we'll suggest it less."
                 : "Cooked it? Rate to teach Cabbage:")
                .font(.subheadline)
            Spacer()
            if rated == nil {
                Button { rate(up: true) } label: { Text("👍").font(.title2) }
                Button { rate(up: false) } label: { Text("👎").font(.title2) }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text).font(.headline)
    }

    private func rate(up: Bool) {
        withAnimation { rated = up }
        guard up else { return }
        let saved = SavedRecipe(recipeId: recipe.id, title: recipe.title, mealType: recipe.mealType)
        saved.source = recipe.source
        saved.timeMinutes = recipe.timeMinutes ?? 0
        saved.estimatedCost = recipe.estimatedCost ?? 0
        saved.payload = try? JSONEncoder().encode(recipe)
        context.insert(saved)
        try? context.save()
    }
}

#Preview {
    NavigationStack {
        RecipeDetailView(recipe: SampleData.weekPlan.slots.first { $0.mealType == .dinner }!.chosen)
    }
    .withPreviewStores()
}
