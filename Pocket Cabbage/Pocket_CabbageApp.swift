//
//  Pocket_CabbageApp.swift
//  Pocket Cabbage
//
//  App entry point. Builds the local SwiftData store, the shared APIClient, and
//  the @Observable stores, then injects them into the environment.
//

import SwiftUI
import SwiftData

@main
struct Pocket_CabbageApp: App {
    let container: ModelContainer

    @State private var profileStore: ProfileStore
    @State private var planStore: PlanStore
    @State private var scanStore: ScanStore
    @State private var shoppingStore: ShoppingStore
    @State private var dashboardStore: DashboardStore

    init() {
        let schema = Schema([
            HouseholdProfile.self, StoredPantryItem.self, AdDeal.self,
            SavedRecipe.self, Receipt.self, PriceMemory.self,
        ])
        // Local-only for now. To enable cross-device sync later, change
        // `cloudKitDatabase: .none` to `.automatic` (the models are CloudKit-ready).
        let configuration = ModelConfiguration(schema: schema,
                                               isStoredInMemoryOnly: false,
                                               cloudKitDatabase: .none)
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        let context = container.mainContext
        let api = APIClient()
        _profileStore = State(initialValue: ProfileStore(context: context))
        _planStore = State(initialValue: PlanStore(api: api, context: context))
        _scanStore = State(initialValue: ScanStore(api: api, context: context))
        _shoppingStore = State(initialValue: ShoppingStore(api: api))
        _dashboardStore = State(initialValue: DashboardStore(api: api, context: context))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(profileStore)
                .environment(planStore)
                .environment(scanStore)
                .environment(shoppingStore)
                .environment(dashboardStore)
        }
        .modelContainer(container)
    }
}
