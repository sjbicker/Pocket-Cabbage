//
//  DomainTypes.swift
//  Pocket Cabbage
//
//  Transient value types for the current week plan, shopping lists and
//  optimizer output. These are built from backend responses (see DTOs.swift)
//  and held in the @Observable stores; persisted user data lives in
//  PersistentModels.swift instead.
//

import Foundation

// MARK: - Meal type (shared by DTOs and domain)

enum MealType: String, Codable, CaseIterable, Identifiable, Hashable {
    case breakfast, lunch, dinner, snack
    var id: String { rawValue }

    var title: String { rawValue.capitalized }
    /// Single-letter column header used in the compact week grid (2a).
    var shortLabel: String {
        switch self {
        case .breakfast: "B"
        case .lunch: "L"
        case .dinner: "D"
        case .snack: "S"
        }
    }
    var systemImage: String {
        switch self {
        case .breakfast: "sunrise"
        case .lunch: "sun.max"
        case .dinner: "moon.stars"
        case .snack: "carrot"
        }
    }
}

/// Confidence tag mirroring the backend's layered price resolver.
enum PriceConfidence: String, Codable, Hashable {
    case sale, exact, estimate, regional, unknown

    var label: String {
        switch self {
        case .sale: "sale price"
        case .exact: "store price"
        case .estimate: "estimate"
        case .regional: "regional avg"
        case .unknown: "unknown"
        }
    }
}

// MARK: - Recipe

struct Ingredient: Identifiable, Hashable, Codable {
    var id = UUID()
    var name: String
    var quantity: Double = 1
    var unit: String = "unit"
    /// Whether this ingredient is already on hand (owned) vs to-buy.
    var owned: Bool = false
    /// Best resolved price for the to-buy split, if known.
    var price: Double? = nil
    var store: String? = nil
    var onSale: Bool = false
}

struct Recipe: Identifiable, Hashable, Codable {
    var id: String
    var title: String
    var mealType: MealType
    var servings: Int
    var ingredients: [Ingredient]
    var instructions: [String]
    /// "spoonacular" | "ai"
    var source: String
    var estimatedCost: Double?
    var timeMinutes: Int?
    var dietFlags: [String]
    var imageURL: URL?
    /// Whether the user has thumbed this recipe up (kept in Recipe Box).
    var isKeeper: Bool = false

    var ownedCount: Int { ingredients.filter { $0.owned }.count }
    var toBuy: [Ingredient] { ingredients.filter { !$0.owned } }
    var incrementalCost: Double { estimatedCost ?? toBuy.compactMap(\.price).reduce(0, +) }
    var hasDeal: Bool { ingredients.contains { $0.onSale } }
}

// MARK: - Week plan

struct MealSlot: Identifiable, Hashable {
    var id = UUID()
    var day: Int          // 1...7 (Mon = 1)
    var mealType: MealType
    var chosen: Recipe
    /// Two AI alternates held in reserve for the swap sheet (2a).
    var alternates: [Recipe] = []

    var incrementalCost: Double { chosen.incrementalCost }
}

struct WeekPlan: Identifiable {
    var id = UUID()
    var weekLabel: String
    var slots: [MealSlot]
    var estimatedTotalCost: Double
    var weeklyBudget: Double
    var totalSavings: Double
    var withinBudget: Bool
    var optimized: Bool = false
    var locationID: String?

    static let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var days: [Int] { Array(Set(slots.map(\.day))).sorted() }

    func slots(forDay day: Int) -> [MealSlot] {
        slots.filter { $0.day == day }
            .sorted { MealType.allCases.firstIndex(of: $0.mealType)! < MealType.allCases.firstIndex(of: $1.mealType)! }
    }

    func slot(day: Int, meal: MealType) -> MealSlot? {
        slots.first { $0.day == day && $0.mealType == meal }
    }
}

// MARK: - Shopping lists

struct ShoppingItem: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var quantity: String            // display form, e.g. "3 lb", "×2"
    var price: Double
    var aisle: String
    var onSale: Bool = false
    var recipeRefs: [String] = []   // recipe titles this item feeds
    var checked: Bool = false
}

struct StoreList: Identifiable, Hashable {
    var id = UUID()
    var store: String
    var items: [ShoppingItem]
    /// Whether this store offers Kroger cart/pickup handoff.
    var supportsKrogerCart: Bool = false

    var total: Double { items.reduce(0) { $0 + $1.price } }
    var checkedTotal: Double { items.filter(\.checked).reduce(0) { $0 + $1.price } }
    var aisles: [String] { Array(NSOrderedSet(array: items.map(\.aisle)) as! [String]) }
    func items(inAisle aisle: String) -> [ShoppingItem] { items.filter { $0.aisle == aisle } }
}

// MARK: - Optimizer

struct OptimizerChange: Identifiable, Hashable {
    enum Kind { case storeSwitch, mealSwap }
    var id = UUID()
    var kind: Kind
    var summary: String       // "Ground beef → Aldi"
    var detail: String        // "$2.89/lb vs $3.49 Kroger"
    var savings: Double
    var undone: Bool = false
}
