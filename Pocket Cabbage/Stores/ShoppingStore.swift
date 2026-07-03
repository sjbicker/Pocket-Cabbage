//
//  ShoppingStore.swift
//  Pocket Cabbage
//
//  Owns the shopping lists. The optimized per-store lists (4a/3b) come from
//  sample data (no optimizer endpoint yet); the consolidated master list can be
//  built from a plan via POST /v1/shopping-list.
//

import Foundation

@MainActor @Observable
final class ShoppingStore {
    private let api: APIClient

    var storeLists: [StoreList] = SampleData.storeLists
    /// Consolidated list built from the current plan by the backend.
    var masterList: StoreList?
    var maxStops = 2
    var isLoading = false
    var errorMessage: String?

    init(api: APIClient) {
        self.api = api
    }

    var combinedTotal: Double { storeLists.reduce(0) { $0 + $1.total } }
    var optimizerSavings: Double { 8.70 }   // sample: vs single-store

    func toggle(_ item: ShoppingItem, inStore storeID: StoreList.ID) {
        guard let s = storeLists.firstIndex(where: { $0.id == storeID }),
              let i = storeLists[s].items.firstIndex(where: { $0.id == item.id }) else { return }
        storeLists[s].items[i].checked.toggle()
    }

    /// Builds the consolidated master list from the current plan.
    func buildMasterList(from plan: MealPlanResponse, pantry: [PantryItemDTO]) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await api.shoppingList(plan: plan, pantry: pantry)
            let items = response.items.map {
                ShoppingItem(name: $0.name,
                             quantity: $0.quantity == 1 ? "" : "×\(Int($0.quantity))",
                             price: 0, aisle: "Grocery")
            }
            masterList = StoreList(store: "All stores", items: items)
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }
}
