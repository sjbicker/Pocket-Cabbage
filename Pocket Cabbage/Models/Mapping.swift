//
//  Mapping.swift
//  Pocket Cabbage
//
//  Converts backend DTOs into the app's transient domain value types, marking
//  which ingredients are already on hand from the user's pantry.
//

import Foundation

extension RecipeDTO {
    /// Builds a domain Recipe, flagging ingredients present in `pantry`
    /// (lowercased names) as owned.
    func toDomain(pantry: Set<String>) -> Recipe {
        let ingredients = ingredients.map { dto -> Ingredient in
            let owned = pantry.contains(dto.name.lowercased().trimmingCharacters(in: .whitespaces))
            return Ingredient(name: dto.name, quantity: dto.quantity, unit: dto.unit, owned: owned)
        }
        return Recipe(
            id: id,
            title: title,
            mealType: mealType,
            servings: servings,
            ingredients: ingredients,
            instructions: instructions,
            source: source,
            estimatedCost: estimatedCost,
            timeMinutes: nil,
            dietFlags: [],
            imageURL: nil
        )
    }
}

extension MealPlanResponse {
    /// Parses a "day_N" key into its day number.
    static func dayNumber(from key: String) -> Int {
        Int(key.replacingOccurrences(of: "day_", with: "")) ?? 0
    }

    /// Builds a WeekPlan. Backend returns one chosen recipe per slot; alternates
    /// start empty and are filled by a reroll/swap.
    func toWeekPlan(weekLabel: String, pantry: Set<String>) -> WeekPlan {
        var slots: [MealSlot] = []
        for (dayKey, recipes) in plan {
            let day = Self.dayNumber(from: dayKey)
            for dto in recipes {
                slots.append(MealSlot(day: day, mealType: dto.mealType,
                                      chosen: dto.toDomain(pantry: pantry)))
            }
        }
        slots.sort {
            $0.day != $1.day ? $0.day < $1.day
            : MealType.allCases.firstIndex(of: $0.mealType)! < MealType.allCases.firstIndex(of: $1.mealType)!
        }
        let savings = max(0, weeklyBudget - estimatedTotalCost)
        return WeekPlan(weekLabel: weekLabel, slots: slots,
                        estimatedTotalCost: estimatedTotalCost,
                        weeklyBudget: weeklyBudget, totalSavings: savings,
                        withinBudget: withinBudget, locationID: locationId)
    }
}

extension HouseholdProfile {
    /// Builds the meal-plan request payload from the stored profile + pantry.
    func mealPlanRequest(pantry: [StoredPantryItem], saleItems: [String: Double],
                         likedRecipeIds: [String] = [],
                         dislikedRecipeIds: [String] = []) -> MealPlanRequest {
        MealPlanRequest(
            zipCode: zipCode,
            weeklyBudget: weeklyBudget,
            familySize: familySize,
            dietaryRestrictions: dietaryRestrictions,
            mealTypes: MealType.allCases,
            days: 7,
            pantry: pantry.map { PantryItemDTO(name: $0.name, quantity: $0.quantity, unit: $0.unit) },
            saleItems: saleItems,
            likedRecipeIds: likedRecipeIds,
            dislikedRecipeIds: dislikedRecipeIds
        )
    }
}
