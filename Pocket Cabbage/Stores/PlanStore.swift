//
//  PlanStore.swift
//  Pocket Cabbage
//
//  Owns the current week plan. Generates and swaps meals via the backend
//  (POST /v1/mealplan/generate, /swap); falls back to sample data when the
//  server is unreachable so the plan grid is never empty.
//

import Foundation
import SwiftData

@MainActor @Observable
final class PlanStore {
    private let api: APIClient
    private let context: ModelContext

    var plan: WeekPlan
    var isLoading = false
    var errorMessage: String?

    /// Optimizer state (sample logic — no backend endpoint yet).
    var optimizerChanges: [OptimizerChange] = SampleData.optimizerChanges
    var singleStoreTotal: Double = 41.80

    init(api: APIClient, context: ModelContext) {
        self.api = api
        self.context = context
        self.plan = SampleData.weekPlan
    }

    // MARK: - Generation

    func generate(profile: HouseholdProfile) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let pantry = (try? context.fetch(FetchDescriptor<StoredPantryItem>())) ?? []
        let deals = (try? context.fetch(FetchDescriptor<AdDeal>())) ?? []
        let sales = Dictionary(deals.map { ($0.item.lowercased(), $0.salePrice) },
                               uniquingKeysWith: { a, _ in a })
        let request = profile.mealPlanRequest(pantry: pantry, saleItems: sales)
        let pantryNames = Set(pantry.map { $0.name.lowercased() })

        do {
            let response = try await api.generateMealPlan(request)
            plan = response.toWeekPlan(weekLabel: plan.weekLabel, pantry: pantryNames)
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
            // Keep whatever plan we had (sample data) so the UI stays populated.
        }
    }

    // MARK: - Swapping

    /// Applies a chosen alternate to a slot immediately (local, no network).
    func choose(_ alternate: Recipe, for slot: MealSlot) {
        guard let idx = plan.slots.firstIndex(where: { $0.id == slot.id }) else { return }
        var updated = plan.slots[idx]
        let previous = updated.chosen
        updated.chosen = alternate
        updated.alternates = ([previous] + updated.alternates.filter { $0.id != alternate.id }).prefix(2).map { $0 }
        plan.slots[idx] = updated
        recomputeTotals()
    }

    /// Asks the backend for a fresh option for this slot (🎲 reroll). Drops the
    /// current recipe and regenerates, then re-reads this slot.
    func reroll(_ slot: MealSlot, profile: HouseholdProfile) async {
        isLoading = true
        defer { isLoading = false }

        let pantry = (try? context.fetch(FetchDescriptor<StoredPantryItem>())) ?? []
        let pantryNames = Set(pantry.map { $0.name.lowercased() })
        let base = profile.mealPlanRequest(pantry: pantry, saleItems: [:])
        let currentResponse = makeResponseDTO()
        let request = SwapRequest(
            zipCode: base.zipCode, weeklyBudget: base.weeklyBudget, familySize: base.familySize,
            dietaryRestrictions: base.dietaryRestrictions, mealTypes: base.mealTypes, days: base.days,
            pantry: base.pantry, saleItems: base.saleItems,
            likedRecipeIds: base.likedRecipeIds, dislikedRecipeIds: base.dislikedRecipeIds,
            currentPlan: currentResponse, dropRecipeId: slot.chosen.id)
        do {
            let response = try await api.swapMeal(request)
            plan = response.toWeekPlan(weekLabel: plan.weekLabel, pantry: pantryNames)
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }

    // MARK: - Optimizer

    func applyOptimizer() {
        plan.optimized = true
        let saved = optimizerChanges.filter { !$0.undone }.reduce(0) { $0 + $1.savings }
        plan.totalSavings += saved
        recomputeTotals()
    }

    func toggleUndo(_ change: OptimizerChange) {
        guard let idx = optimizerChanges.firstIndex(where: { $0.id == change.id }) else { return }
        optimizerChanges[idx].undone.toggle()
    }

    var optimizedTotal: Double {
        singleStoreTotal - optimizerChanges.filter { !$0.undone }.reduce(0) { $0 + $1.savings }
    }

    // MARK: - Helpers

    private func recomputeTotals() {
        plan.estimatedTotalCost = plan.slots.reduce(0) { $0 + $1.incrementalCost }
    }

    /// Reconstructs a MealPlanResponse DTO from the current plan (for swap calls
    /// and the shopping-list endpoint).
    func makeResponseDTO() -> MealPlanResponse {
        var dict: [String: [RecipeDTO]] = [:]
        for slot in plan.slots {
            let key = "day_\(slot.day)"
            let dto = RecipeDTO(id: slot.chosen.id, title: slot.chosen.title,
                                mealType: slot.chosen.mealType, servings: slot.chosen.servings,
                                ingredients: slot.chosen.ingredients.map {
                                    IngredientDTO(name: $0.name, quantity: $0.quantity, unit: $0.unit) },
                                instructions: slot.chosen.instructions,
                                source: slot.chosen.source, estimatedCost: slot.chosen.estimatedCost)
            dict[key, default: []].append(dto)
        }
        return MealPlanResponse(plan: dict, estimatedTotalCost: plan.estimatedTotalCost,
                                weeklyBudget: plan.weeklyBudget, withinBudget: plan.withinBudget,
                                budgetPasses: 0, locationId: plan.locationID)
    }
}
