//
//  SampleData.swift
//  Pocket Cabbage
//
//  Realistic fixtures mirroring the wireframe numbers. Used for SwiftUI
//  previews, for the analytics/optimizer/receipt screens (no backend endpoints
//  yet), and as an offline fallback so the app is usable without a server.
//

import Foundation

enum SampleData {

    // MARK: - Recipes

    static func recipe(_ id: String, _ title: String, _ meal: MealType,
                       cost: Double, time: Int, source: String = "spoonacular",
                       diet: [String] = [], deal: Bool = false,
                       keeper: Bool = false,
                       owned: [String] = [], buy: [(String, Double)] = []) -> Recipe {
        var ingredients = owned.map { Ingredient(name: $0, owned: true) }
        ingredients += buy.enumerated().map { idx, item in
            Ingredient(name: item.0, price: item.1, store: "Kroger",
                       onSale: deal && idx == 0)
        }
        return Recipe(id: id, title: title, mealType: meal, servings: 4,
                      ingredients: ingredients,
                      instructions: [
                        "Prep and measure your ingredients.",
                        "Cook the base per package directions.",
                        "Combine everything and season to taste.",
                        "Plate, serve and enjoy."
                      ],
                      source: source, estimatedCost: cost, timeMinutes: time,
                      dietFlags: diet, imageURL: nil, isKeeper: keeper)
    }

    /// A fully pre-populated week (matches the 2a grid style).
    static var weekPlan: WeekPlan {
        let names: [MealType: [(String, Double, Int, Bool)]] = [
            .breakfast: [("Oatmeal", 0, 5, false), ("Scrambled eggs", 0, 10, false),
                         ("Smoothie", 1.50, 5, false), ("Toast & jam", 0, 5, false),
                         ("Yogurt bowl", 1.20, 5, false), ("Pancakes", 2.10, 20, false),
                         ("Bagels", 0, 5, false)],
            .lunch: [("PBJ", 0, 5, false), ("Leftovers", 0, 5, false),
                     ("Turkey wraps", 0, 10, false), ("Tomato soup", 1.80, 15, false),
                     ("Grain bowl", 3.20, 15, false), ("Grilled cheese", 0, 10, false),
                     ("Chicken salad", 2.40, 15, false)],
            .dinner: [("Chili mac", 3.20, 35, true), ("Chicken stir-fry", 4.30, 25, true),
                      ("Tacos", 3.80, 30, false), ("Sheet-pan thighs", 3.90, 40, true),
                      ("Pasta primavera", 2.90, 30, false), ("Fried rice", 1.10, 20, false),
                      ("Baked salmon", 6.40, 25, false)],
            .snack: [("Apples", 2.00, 0, false), ("Popcorn", 0, 5, false),
                     ("Yogurt + granola", 3.00, 0, false), ("Cheese & crackers", 1.80, 0, false),
                     ("Trail mix", 2.20, 0, false), ("Hummus & veg", 2.60, 5, false),
                     ("Banana bread", 1.40, 0, false)]
        ]
        var slots: [MealSlot] = []
        for day in 1...7 {
            for meal in MealType.allCases {
                let picks = names[meal]!
                let (title, cost, time, deal) = picks[(day - 1) % picks.count]
                let chosen = recipe("sample-\(meal.rawValue)-\(day)", title, meal,
                                    cost: cost, time: time, deal: deal,
                                    owned: ["salt", "pepper", "oil"],
                                    buy: cost > 0 ? [(title.lowercased(), cost)] : [])
                // two alternates from the same meal's pool
                let altA = picks[(day) % picks.count]
                let altB = picks[(day + 1) % picks.count]
                let alternates = [
                    recipe("alt-\(meal.rawValue)-\(day)-a", altA.0, meal, cost: altA.1,
                           time: altA.2, deal: altA.3, buy: altA.1 > 0 ? [(altA.0.lowercased(), altA.1)] : []),
                    recipe("alt-\(meal.rawValue)-\(day)-b", altB.0, meal, cost: altB.1,
                           time: altB.2, deal: altB.3, keeper: true,
                           buy: altB.1 > 0 ? [(altB.0.lowercased(), altB.1)] : [])
                ]
                slots.append(MealSlot(day: day, mealType: meal, chosen: chosen, alternates: alternates))
            }
        }
        let total = slots.reduce(0) { $0 + $1.incrementalCost }
        return WeekPlan(weekLabel: "Week of Jul 6", slots: slots,
                        estimatedTotalCost: total, weeklyBudget: 125,
                        totalSavings: 23, withinBudget: true)
    }

    // MARK: - Shopping lists (4a / 3b)

    static var storeLists: [StoreList] {
        [
            StoreList(store: "Kroger", items: [
                ShoppingItem(name: "Chicken thighs 3 lb", quantity: "3 lb", price: 5.37,
                             aisle: "Meat — Aisle 12", onSale: true, recipeRefs: ["Stir-fry", "Sheet-pan"], checked: true),
                ShoppingItem(name: "Shredded cheese", quantity: "×2", price: 5.00,
                             aisle: "Dairy — Aisle 8", onSale: true, recipeRefs: ["Chili mac", "Tacos"]),
                ShoppingItem(name: "Milk 1 gal", quantity: "1 gal", price: 2.79,
                             aisle: "Dairy — Aisle 8"),
                ShoppingItem(name: "Apples, gala 3 lb", quantity: "3 lb", price: 2.00,
                             aisle: "Produce — Aisle 1", recipeRefs: ["Snacks"]),
                ShoppingItem(name: "Ginger root", quantity: "1", price: 1.60,
                             aisle: "Produce — Aisle 1", recipeRefs: ["Stir-fry"]),
                ShoppingItem(name: "Yogurt cups", quantity: "×8", price: 3.00,
                             aisle: "Dairy — Aisle 8", recipeRefs: ["Snacks"])
            ], supportsKrogerCart: true),
            StoreList(store: "Aldi", items: [
                ShoppingItem(name: "Ground beef 1 lb", quantity: "1 lb", price: 2.89,
                             aisle: "Meat", onSale: true, recipeRefs: ["Chili mac"]),
                ShoppingItem(name: "Tortillas", quantity: "1", price: 1.49, aisle: "Bakery",
                             recipeRefs: ["Tacos", "Wraps"]),
                ShoppingItem(name: "Frozen peas", quantity: "1", price: 1.19, aisle: "Frozen"),
                ShoppingItem(name: "Canned beans", quantity: "×2", price: 1.60, aisle: "Canned")
            ])
        ]
    }

    // MARK: - Optimizer (3a)

    static var optimizerChanges: [OptimizerChange] {
        [
            OptimizerChange(kind: .storeSwitch, summary: "Ground beef → Aldi",
                            detail: "$2.89/lb vs $3.49 Kroger", savings: 1.20),
            OptimizerChange(kind: .storeSwitch, summary: "Yogurt cups → Safeway",
                            detail: "BOGO in this week's ad", savings: 1.50),
            OptimizerChange(kind: .mealSwap, summary: "Wed dinner: Tacos → Chili",
                            detail: "beans on hand + beef deal", savings: 3.80)
        ]
    }

    // MARK: - Dashboard (5a / 4b)

    static let spentThisMonth = 324.0
    static let savedThisMonth = 187.40
    static let costPerMeal = 1.28
    static let projectionAccuracy = 0.94

    static var weekdaySpend: [WeekdaySpend] {
        [ .init(weekday: "M", amount: 6), .init(weekday: "T", amount: 12),
          .init(weekday: "W", amount: 4), .init(weekday: "T", amount: 8),
          .init(weekday: "F", amount: 9), .init(weekday: "Sa", amount: 41, isBigShop: true),
          .init(weekday: "Su", amount: 7) ]
    }

    static var weeklySavings: [WeeklySavings] {
        [ .init(label: "wk1", amount: 38), .init(label: "wk2", amount: 51),
          .init(label: "wk3", amount: 44), .init(label: "this wk", amount: 54, isCurrent: true) ]
    }

    static var storeSpend: [StoreSpend] {
        [ .init(store: "Kroger", spent: 212, saved: 118),
          .init(store: "Aldi", spent: 74, saved: 41),
          .init(store: "Safeway", spent: 38, saved: 28) ]
    }

    // MARK: - Learning (5c)

    static var accuracyTrend: [AccuracyPoint] {
        [ .init(label: "May", accuracy: 0.78), .init(label: "Jun", accuracy: 0.86),
          .init(label: "Jul", accuracy: 0.91), .init(label: "now", accuracy: 0.94) ]
    }

    static var learningSwaps: [LearningSwap] {
        [ .init(from: "Chili mac", to: "Lentil chili mac", savings: 2.10, cadence: "/meal",
                rationale: "lentils you actually paid $0.89/lb for · same 👍 rating pattern", highlighted: true),
          .init(from: "Yogurt cups", to: "tub + granola", savings: 1.40, cadence: "/wk",
                rationale: "receipts show cups run 38% over tub per oz", highlighted: true),
          .init(from: "Smoothies", to: "frozen fruit blend", savings: 0.90, cadence: "/wk",
                rationale: "fresh berries kept beating their estimate") ]
    }

    // MARK: - Ad scan deals (1f)

    static var rankedDeals: [RankedDeal] {
        [ .init(item: "Chicken thighs", salePriceText: "$1.79/lb", regularPriceText: "reg $2.99",
                relevance: "you buy this 2×/mo", matchesPlan: true),
          .init(item: "Shredded cheese", salePriceText: "2 / $5", regularPriceText: "reg $3.49",
                relevance: "pairs with 4 saved recipes", matchesPlan: true),
          .init(item: "Ground beef", salePriceText: "$3.49/lb", regularPriceText: "reg $3.99",
                relevance: "ok deal — chili, tacos") ]
    }

    // MARK: - Receipt reconcile (5b)

    static var receiptLines: [ReceiptLineItem] {
        [ .init(name: "Chicken thighs 3 lb", price: 5.37, plannedPrice: 5.37),
          .init(name: "Milk 1 gal", price: 3.19, plannedPrice: 2.79),
          .init(name: "Ginger root", price: 2.10, plannedPrice: 1.60),
          .init(name: "Ice cream", price: 4.99, isUnplanned: true),
          .init(name: "Chips", price: 2.49, isUnplanned: true) ]
    }
}
