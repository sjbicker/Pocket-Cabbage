//
//  CommonViews.swift
//  Pocket Cabbage
//
//  Small reusable building blocks shared across the feature screens.
//

import SwiftUI

/// The app's primary call-to-action button (savings-tinted, rounded).
struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var tint: Color = .savings
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .foregroundStyle(.white)
        .background(tint, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

/// A compact stat card used on the Money home (Spent / Saved / Per meal).
struct StatCard: View {
    let label: String
    let value: String
    var highlighted = false

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(highlighted ? Color.savings : .primary)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(highlighted ? Color.savingsFill : Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(highlighted ? Color.savings.opacity(0.4) : Color.primary.opacity(0.06))
        )
    }
}

/// Incremental-cost pill; shows "$0" in the savings color when nothing to buy.
struct CostBadge: View {
    let amount: Double
    var prefixPlus = true

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.savings)
    }

    private var text: String {
        if amount == 0 { return "$0" }
        return (prefixPlus ? "+" : "") + moneyString(amount)
    }
}

/// A small rounded chip (deal 🔥, keeper ⭐️, diet flags, etc.).
struct Chip: View {
    let text: String
    var tint: Color = .secondary

    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 9)
            .padding(.vertical, 3)
            .background(tint.opacity(0.12), in: Capsule())
            .foregroundStyle(tint)
    }
}

/// Placeholder image block used where recipe/photo assets aren't available yet.
struct PlaceholderImage: View {
    var systemImage = "photo"
    var height: CGFloat = 120

    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color(.tertiarySystemFill))
            .frame(height: height)
            .overlay(Image(systemName: systemImage).font(.title2).foregroundStyle(.tertiary))
    }
}

/// Section header used in lists/aisles.
struct MiniSectionHeader: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.caption2.weight(.semibold))
            .tracking(0.6)
            .foregroundStyle(.tertiary)
    }
}
