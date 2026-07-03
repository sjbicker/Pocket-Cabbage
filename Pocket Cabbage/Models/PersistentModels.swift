//
//  PersistentModels.swift
//  Pocket Cabbage
//
//  On-device persisted user data (SwiftData). Written CloudKit-ready: every
//  stored property has a default value and there are no unique constraints or
//  required relationships, so enabling CloudKit sync later is a one-line change
//  in the ModelContainer configuration (see Pocket_CabbageApp).
//

import Foundation
import SwiftData

// MARK: - Household profile (onboarding)

@Model
final class HouseholdProfile {
    var familySize: Int = 4
    var dietaryRestrictions: [String] = []
    var tastePreferences: [String] = []
    var dislikes: [String] = []
    var favoriteStores: [String] = []
    var zipCode: String = APIConfig.defaultZip
    /// Optional weekly spending ceiling.
    var weeklyBudget: Double = 125
    var treatsBudget: Double = 20
    var createdAt: Date = Date.now
    /// True once onboarding has been completed at least once.
    var onboardingComplete: Bool = false

    init() {}
}

// MARK: - Inventory

enum StorageZone: String, Codable, CaseIterable, Identifiable {
    case pantry, fridge, freezer
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var systemImage: String {
        switch self {
        case .pantry: "cabinet"
        case .fridge: "refrigerator"
        case .freezer: "snowflake"
        }
    }
}

@Model
final class StoredPantryItem {
    var name: String = ""
    var category: String = ""
    var zoneRaw: String = StorageZone.pantry.rawValue
    var quantity: Double = 1
    var unit: String = "unit"
    var lastConfirmed: Date = Date.now

    var zone: StorageZone {
        get { StorageZone(rawValue: zoneRaw) ?? .pantry }
        set { zoneRaw = newValue.rawValue }
    }

    init(name: String = "", zone: StorageZone = .pantry, quantity: Double = 1, unit: String = "unit") {
        self.name = name
        self.zoneRaw = zone.rawValue
        self.quantity = quantity
        self.unit = unit
    }
}

// MARK: - Ad deals

@Model
final class AdDeal {
    var store: String = ""
    var item: String = ""
    var salePrice: Double = 0
    var regularPrice: Double = 0
    var unit: String = ""
    var validThrough: Date = Date.now
    /// Why this deal is relevant (e.g. "you buy this 2×/mo").
    var relevance: String = ""

    init(store: String = "", item: String = "", salePrice: Double = 0,
         regularPrice: Double = 0, validThrough: Date = .now, relevance: String = "") {
        self.store = store
        self.item = item
        self.salePrice = salePrice
        self.regularPrice = regularPrice
        self.validThrough = validThrough
        self.relevance = relevance
    }
}

// MARK: - Recipe Box (thumbed-up keepers)

@Model
final class SavedRecipe {
    var recipeId: String = ""
    var title: String = ""
    var mealTypeRaw: String = MealType.dinner.rawValue
    var source: String = "ai"
    var timeMinutes: Int = 0
    var estimatedCost: Double = 0
    var imageURLString: String = ""
    var savedAt: Date = Date.now
    /// Encoded Recipe payload so the full recipe can be re-selected later.
    var payload: Data? = nil

    var mealType: MealType {
        get { MealType(rawValue: mealTypeRaw) ?? .dinner }
        set { mealTypeRaw = newValue.rawValue }
    }

    init(recipeId: String = "", title: String = "", mealType: MealType = .dinner) {
        self.recipeId = recipeId
        self.title = title
        self.mealTypeRaw = mealType.rawValue
    }
}

// MARK: - Receipts

struct ReceiptLineItem: Codable, Hashable, Identifiable {
    var id = UUID()
    var name: String
    var price: Double
    var quantity: Double = 1
    /// nil = unmatched/unplanned, otherwise the delta vs the planned price.
    var plannedPrice: Double? = nil
    var isUnplanned: Bool = false

    var variance: Double? {
        guard let planned = plannedPrice else { return nil }
        return price - planned
    }
}

@Model
final class Receipt {
    var store: String = ""
    var date: Date = Date.now
    var plannedTotal: Double = 0
    var actualTotal: Double = 0
    var lineItems: [ReceiptLineItem] = []
    var matchedCount: Int = 0
    var readCount: Int = 0

    var diff: Double { actualTotal - plannedTotal }

    init(store: String = "", date: Date = .now) {
        self.store = store
        self.date = date
    }
}

// MARK: - Price memory (drives projection accuracy)

@Model
final class PriceMemory {
    var store: String = ""
    var item: String = ""
    /// Most recent observed prices (rolling window).
    var observedPrices: [Double] = []
    var lastUpdated: Date = Date.now

    var average: Double {
        observedPrices.isEmpty ? 0 : observedPrices.reduce(0, +) / Double(observedPrices.count)
    }

    init(store: String = "", item: String = "") {
        self.store = store
        self.item = item
    }
}
