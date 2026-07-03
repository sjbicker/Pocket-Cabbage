//
//  AnalyticsTypes.swift
//  Pocket Cabbage
//
//  Value types backing the Money dashboard, learning insights and receipt
//  reconciliation. The backend has no analytics endpoints yet, so these are
//  populated from SampleData; they sit behind DashboardStore so real data can
//  be swapped in later without touching the views.
//

import Foundation

/// One bar in the "grocery spend by weekday" chart (5a).
struct WeekdaySpend: Identifiable, Hashable {
    var id = UUID()
    var weekday: String       // "M", "T", …
    var amount: Double
    var isBigShop: Bool = false
}

/// One bar in the "savings per week" chart (4b).
struct WeeklySavings: Identifiable, Hashable {
    var id = UUID()
    var label: String         // "wk1", "this wk"
    var amount: Double
    var isCurrent: Bool = false
}

/// Per-store spent vs saved breakdown (4b).
struct StoreSpend: Identifiable, Hashable {
    var id = UUID()
    var store: String
    var spent: Double
    var saved: Double
}

/// A point on the projection-accuracy trend (5c).
struct AccuracyPoint: Identifiable, Hashable {
    var id = UUID()
    var label: String         // "May", "now"
    var accuracy: Double      // 0...1
}

/// A cheaper-swap suggestion learned from real prices (5c).
struct LearningSwap: Identifiable, Hashable {
    var id = UUID()
    var from: String
    var to: String
    var savings: Double
    var cadence: String       // "/meal", "/wk"
    var rationale: String
    var highlighted: Bool = false
}

/// A ranked deal surfaced after scanning an ad (1f).
struct RankedDeal: Identifiable, Hashable {
    var id = UUID()
    var item: String
    var salePriceText: String     // "$1.79/lb", "2 / $5"
    var regularPriceText: String
    var relevance: String
    var matchesPlan: Bool = false
}
