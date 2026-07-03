//
//  RecipeBoxView.swift
//  Pocket Cabbage
//
//  The user's saved (thumbed-up) keepers, available for manual selection.
//  Also hosts the evening post-meal check-in sheet (1l).
//

import SwiftUI
import SwiftData

struct RecipeBoxView: View {
    @Query(sort: \SavedRecipe.savedAt, order: .reverse) private var saved: [SavedRecipe]

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        ScrollView {
            if saved.isEmpty {
                ContentUnavailableView("No keepers yet",
                                       systemImage: "star",
                                       description: Text("Thumbs-up a recipe after cooking and it lands here."))
                    .padding(.top, 60)
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(saved) { recipe in
                        VStack(alignment: .leading, spacing: 6) {
                            PlaceholderImage(systemImage: "fork.knife", height: 90)
                            Text(recipe.title).font(.subheadline.weight(.medium)).lineLimit(1)
                            HStack(spacing: 6) {
                                Text(recipe.mealType.title)
                                if recipe.timeMinutes > 0 { Text("· \(recipe.timeMinutes)m") }
                            }
                            .font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(8)
                        .background(Color(.secondarySystemGroupedBackground),
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Recipe Box \(Badge.keeper)")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

/// Wireframe 1l: evening bottom sheet asking how tonight's meal was.
struct PostMealCheckInView: View {
    let recipe: Recipe
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var keepers: [SavedRecipe]

    var body: some View {
        VStack(spacing: 16) {
            Capsule().fill(.secondary.opacity(0.3)).frame(width: 36, height: 4)
            VStack(spacing: 2) {
                Text("Tonight you cooked").font(.subheadline).foregroundStyle(.secondary)
                Text("\(recipe.title) 🍳").font(.title3.weight(.semibold))
            }
            HStack(spacing: 12) {
                choiceButton(emoji: "👍", label: "Keeper!", tint: .savings) { keep(true); dismiss() }
                choiceButton(emoji: "👎", label: "Not again", tint: .secondary) { keep(false); dismiss() }
            }
            Text("👍 saves it to your Recipe Box for future weeks")
                .font(.caption).foregroundStyle(.secondary)
            Divider()
            HStack {
                Text("Your Recipe Box · \(keepers.count) keepers")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding()
    }

    private func choiceButton(emoji: String, label: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(emoji).font(.system(size: 30))
                Text(label).font(.caption).foregroundStyle(tint)
            }
            .frame(width: 110).padding(.vertical, 14)
            .background(tint == .savings ? Color.savingsFill : Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(tint.opacity(0.4)))
        }
        .buttonStyle(.plain)
    }

    private func keep(_ up: Bool) {
        guard up else { return }
        let saved = SavedRecipe(recipeId: recipe.id, title: recipe.title, mealType: recipe.mealType)
        saved.timeMinutes = recipe.timeMinutes ?? 0
        saved.estimatedCost = recipe.estimatedCost ?? 0
        saved.payload = try? JSONEncoder().encode(recipe)
        context.insert(saved)
        try? context.save()
    }
}

#Preview("Recipe Box") {
    NavigationStack { RecipeBoxView() }.withPreviewStores()
}

#Preview("Check-in") {
    Color(.systemGroupedBackground)
        .sheet(isPresented: .constant(true)) {
            PostMealCheckInView(recipe: SampleData.weekPlan.slots[2].chosen)
                .withPreviewStores()
                .presentationDetents([.medium])
        }
}
