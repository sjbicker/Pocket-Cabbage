//
//  Theme.swift
//  Pocket Cabbage
//
//  App-wide design tokens. The wireframes are low-fidelity; this applies a
//  fresh, modern iOS look while preserving the design system's core semantic:
//  a single reserved accent for all money/savings meaning.
//

import SwiftUI

extension Color {
    /// The reserved "money saved / cost" accent (wireframe #1e7a45).
    static let savings = Color(red: 0x1e / 255, green: 0x7a / 255, blue: 0x45 / 255)
    /// Soft fill behind savings content (#eaf6ee / #f4faf6 family).
    static let savingsFill = Color(red: 0xf1 / 255, green: 0xf9 / 255, blue: 0xf4 / 255)
    /// Over-budget / variance amber (#b06a1e).
    static let overBudget = Color(red: 0xb0 / 255, green: 0x6a / 255, blue: 0x1e / 255)
    static let overBudgetFill = Color(red: 0xfd / 255, green: 0xf6 / 255, blue: 0xee / 255)
    /// Alert / unknown red (#a33).
    static let alert = Color(red: 0xaa / 255, green: 0x33 / 255, blue: 0x33 / 255)
}

enum Badge {
    static let deal = "🔥"       // sale / deal flag
    static let keeper = "⭐️"     // saved / thumbed-up recipe
}

/// Standard card container used across the app.
struct CardStyle: ViewModifier {
    var tint: Color? = nil
    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(tint ?? Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06))
            )
    }
}

extension View {
    /// Wraps content in the app's standard rounded card.
    func card(tint: Color? = nil) -> some View { modifier(CardStyle(tint: tint)) }
}

/// Formats a dollar amount, showing "$0" when nothing needs buying (per wireframes).
func moneyString(_ value: Double, showsZeroAsFree: Bool = false) -> String {
    if showsZeroAsFree && value == 0 { return "$0" }
    return value.formatted(.currency(code: "USD").precision(.fractionLength(2)))
}
