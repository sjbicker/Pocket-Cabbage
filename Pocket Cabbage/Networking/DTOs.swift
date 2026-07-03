//
//  DTOs.swift
//  Pocket Cabbage
//
//  Codable mirrors of the FastAPI gateway's request/response models
//  (Backend for ShelfPlan/main.py). Property names are camelCase; the
//  APIClient's JSONEncoder/Decoder use snake_case conversion to match the API.
//

import Foundation

// MARK: - Auth

struct ChallengeResponse: Codable {
    let challenge: String
}

/// POST /v1/auth/attest body. In dev mode (`APP_ATTEST_REQUIRED=false`) only
/// `keyId` + `challenge` are required.
struct AttestPayload: Codable {
    var keyId: String
    var attestation: String?
    var assertion: String?
    var challenge: String
    var clientDataHash: String?
}

struct TokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
}

// MARK: - Shared value DTOs

struct IngredientDTO: Codable {
    var name: String
    var quantity: Double = 1
    var unit: String = "unit"
}

struct PantryItemDTO: Codable {
    var name: String
    var quantity: Double = 1
    var unit: String = "unit"
}

struct RecipeDTO: Codable {
    var id: String
    var title: String
    var mealType: MealType
    var servings: Int
    var ingredients: [IngredientDTO]
    var instructions: [String]
    var source: String
    var estimatedCost: Double?
}

// MARK: - Meal plan

struct MealPlanRequest: Codable {
    var zipCode: String
    var weeklyBudget: Double
    var familySize: Int
    var dietaryRestrictions: [String] = []
    var mealTypes: [MealType] = MealType.allCases
    var days: Int = 7
    var pantry: [PantryItemDTO] = []
    var saleItems: [String: Double] = [:]
    var likedRecipeIds: [String] = []
    var dislikedRecipeIds: [String] = []
}

/// SwapRequest extends MealPlanRequest with the current plan + the id to drop.
struct SwapRequest: Codable {
    var zipCode: String
    var weeklyBudget: Double
    var familySize: Int
    var dietaryRestrictions: [String] = []
    var mealTypes: [MealType] = MealType.allCases
    var days: Int = 7
    var pantry: [PantryItemDTO] = []
    var saleItems: [String: Double] = [:]
    var likedRecipeIds: [String] = []
    var dislikedRecipeIds: [String] = []
    var currentPlan: MealPlanResponse
    var dropRecipeId: String
}

struct MealPlanResponse: Codable {
    /// Keyed by "day_1", "day_2", … (dictionary keys are not snake_case-converted).
    var plan: [String: [RecipeDTO]]
    var estimatedTotalCost: Double
    var weeklyBudget: Double
    var withinBudget: Bool
    var budgetPasses: Int
    var locationId: String?
}

// MARK: - Shopping list

struct ShoppingListResponse: Codable {
    struct Item: Codable {
        var name: String
        var quantity: Double
        var unit: String
    }
    var items: [Item]
    var count: Int
}

// MARK: - Pricing

struct PricingResponse: Codable {
    var ingredient: String
    var price: Double?
    var confidence: PriceConfidence
}

// MARK: - Scanning

struct ScanRequest: Codable {
    var imageBase64: String
    var mediaType: String = "image/jpeg"
}

/// Pantry / fridge / freezer vision result: {items:[{name,quantity,unit}]}.
struct PantryScanResult: Codable {
    struct Item: Codable {
        var name: String
        var quantity: Double = 1
        var unit: String = "unit"
    }
    var items: [Item]
}

/// Flyer vision result: {store, items:[{name,sale_price,unit}]}.
struct FlyerScanResult: Codable {
    struct Deal: Codable {
        var name: String
        var salePrice: Double?
        var unit: String?
    }
    var store: String?
    var items: [Deal]
}

/// Receipt vision result: {items:[{name,price,quantity}]}.
struct ReceiptScanResult: Codable {
    struct Line: Codable {
        var name: String
        var price: Double?
        var quantity: Double?
    }
    var items: [Line]
}

// MARK: - Diagnostics

struct HealthResponse: Codable {
    var status: String
    var redis: Bool
    var provider: String
    var env: String
}
