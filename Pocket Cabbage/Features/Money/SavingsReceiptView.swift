//
//  SavingsReceiptView.swift
//  Pocket Cabbage
//
//  Wireframe 4c: a shareable monthly "savings receipt" styled like a till print.
//

import SwiftUI

struct SavingsReceiptView: View {
    @Environment(DashboardStore.self) private var dashboardStore

    private let line = String(repeating: "-", count: 28)

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                receipt
                ShareLink(item: shareText) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity).padding()
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Savings Receipt")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var receipt: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("🥬 POCKETCABBAGE").frame(maxWidth: .infinity)
            Text("* MONTHLY SAVINGS RECEIPT *").frame(maxWidth: .infinity)
            Text(line)
            row("MEALS PLANNED", "84")
            row("RECIPES KEPT 👍", "9")
            row("PANTRY ITEMS USED", "61")
            Text(line)
            ForEach(dashboardStore.storeSpend) { store in
                row(store.store.uppercased(), "−\(moneyString(store.saved))")
            }
            Text(line)
            HStack {
                Text("TOTAL SAVED").fontWeight(.bold)
                Spacer()
                Text(moneyString(dashboardStore.saved)).fontWeight(.bold)
            }
            .font(.system(.body, design: .monospaced))
            Text("BEST DEAL: THIGHS $1.79/LB")
            Text(line)
            Text("THANK YOU FOR\nSHOPPING SMART ✂").frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
        }
        .font(.system(.footnote, design: .monospaced))
        .padding()
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.primary.opacity(0.15)))
        .shadow(color: .black.opacity(0.12), radius: 4, x: 2, y: 3)
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack { Text(label); Spacer(); Text(value) }
            .font(.system(.footnote, design: .monospaced))
    }

    private var shareText: String {
        "I saved \(moneyString(dashboardStore.saved)) this month with PocketCabbage 🥬"
    }
}

#Preview {
    NavigationStack { SavingsReceiptView() }.withPreviewStores()
}
