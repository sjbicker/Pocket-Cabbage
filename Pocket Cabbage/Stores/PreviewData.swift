//
//  PreviewData.swift
//  Pocket Cabbage
//
//  Shared in-memory container + stores for SwiftUI previews, seeded so screens
//  render fully populated without a running backend.
//

#if DEBUG
import SwiftUI
import SwiftData

@MainActor
enum PreviewData {
    static let container: ModelContainer = {
        let schema = Schema([
            HouseholdProfile.self, StoredPantryItem.self, AdDeal.self,
            SavedRecipe.self, Receipt.self, PriceMemory.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let profile = HouseholdProfile()
        profile.onboardingComplete = true
        profile.favoriteStores = ["Kroger", "Aldi", "Safeway"]
        profile.dietaryRestrictions = ["vegetarian"]
        context.insert(profile)

        for (name, zone) in [("Rice", StorageZone.pantry), ("Black beans", .pantry),
                             ("Milk", .fridge), ("Frozen peas", .freezer)] {
            context.insert(StoredPantryItem(name: name, zone: zone))
        }
        for recipe in SampleData.weekPlan.slots.prefix(6).map(\.chosen) {
            let saved = SavedRecipe(recipeId: recipe.id, title: recipe.title, mealType: recipe.mealType)
            saved.timeMinutes = recipe.timeMinutes ?? 20
            saved.estimatedCost = recipe.estimatedCost ?? 0
            context.insert(saved)
        }
        try? context.save()
        return container
    }()

    static let api = APIClient()
    static let profileStore = ProfileStore(context: container.mainContext)
    static let planStore = PlanStore(api: api, context: container.mainContext)
    static let scanStore = ScanStore(api: api, context: container.mainContext)
    static let shoppingStore = ShoppingStore(api: api)
    static let dashboardStore = DashboardStore(api: api, context: container.mainContext)
}

/// Convenience: applies the full preview environment to any screen.
extension View {
    func withPreviewStores() -> some View {
        self
            .modelContainer(PreviewData.container)
            .environment(PreviewData.profileStore)
            .environment(PreviewData.planStore)
            .environment(PreviewData.scanStore)
            .environment(PreviewData.shoppingStore)
            .environment(PreviewData.dashboardStore)
    }
}
#endif
