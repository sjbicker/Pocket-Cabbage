//
//  ShoppingListsView.swift
//  Pocket Cabbage
//
//  Wireframes 4a + 3b: per-store, aisle-grouped checklists with quantities,
//  recipe cross-references, deal flags and running totals, plus a "max stops"
//  control that trades off convenience vs savings.
//

import SwiftUI

struct ShoppingListsView: View {
    @Environment(ShoppingStore.self) private var shoppingStore

    @State private var selectedStoreID: StoreList.ID?

    private var stores: [StoreList] { shoppingStore.storeLists }
    private var selected: StoreList? {
        stores.first { $0.id == selectedStoreID } ?? stores.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    maxStopsCard
                    storePicker
                    if let store = selected {
                        storeChecklist(store)
                    }
                    footer
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Shopping Lists")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .onAppear { if selectedStoreID == nil { selectedStoreID = stores.first?.id } }
        }
    }

    // MARK: - Max stops (3b)

    @ViewBuilder private var maxStopsCard: some View {
        @Bindable var store = shoppingStore
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Max stops I'll make").font(.subheadline)
                Spacer()
                Text("\(shoppingStore.maxStops) store\(shoppingStore.maxStops == 1 ? "" : "s")")
                    .font(.subheadline.weight(.semibold))
            }
            Slider(value: Binding(
                get: { Double(shoppingStore.maxStops) },
                set: { shoppingStore.maxStops = Int($0.rounded()) }), in: 1...3, step: 1)
                .tint(.savings)
            Text("1 stop = $38.90 · 2 stops = $33.10 · 3 stops = $32.40")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Store tabs (4a)

    private var storePicker: some View {
        Picker("Store", selection: Binding(
            get: { selected?.id ?? stores.first?.id },
            set: { selectedStoreID = $0 })) {
            ForEach(stores) { store in
                Text("\(store.store) · \(moneyString(store.total))").tag(Optional(store.id))
            }
        }
        .pickerStyle(.segmented)
    }

    private func storeChecklist(_ store: StoreList) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(store.aisles, id: \.self) { aisle in
                MiniSectionHeader(text: aisle)
                ForEach(store.items(inAisle: aisle)) { item in
                    itemRow(item, in: store)
                }
            }
            if store.supportsKrogerCart {
                PrimaryButton(title: "Send to Kroger cart / pickup →", systemImage: "cart.badge.plus") {}
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func itemRow(_ item: ShoppingItem, in store: StoreList) -> some View {
        Button { shoppingStore.toggle(item, inStore: store.id) } label: {
            HStack(alignment: .top) {
                Image(systemName: item.checked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.checked ? Color.savings : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .strikethrough(item.checked)
                        .foregroundStyle(item.checked ? .secondary : .primary)
                    if !item.recipeRefs.isEmpty {
                        Text(item.recipeRefs.joined(separator: ", "))
                            .font(.caption).foregroundStyle(.tertiary)
                    }
                }
                Spacer()
                Text("\(moneyString(item.price))\(item.onSale ? " 🔥" : "")")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(item.onSale ? Color.savings : .primary)
            }
            .font(.subheadline)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        HStack {
            Text("Both stores: ").foregroundStyle(.secondary)
            + Text(moneyString(shoppingStore.combinedTotal)).fontWeight(.semibold)
            Spacer()
            Text("saves \(moneyString(shoppingStore.optimizerSavings)) vs one store")
                .foregroundStyle(Color.savings)
        }
        .font(.subheadline)
        .padding()
        .background(Color.savingsFill, in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    ShoppingListsView().withPreviewStores()
}
