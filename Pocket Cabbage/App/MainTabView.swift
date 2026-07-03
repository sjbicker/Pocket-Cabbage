//
//  MainTabView.swift
//  Pocket Cabbage
//
//  The persistent 5-tab bar: Money · Plan · Scan (center) · Lists · Profile.
//

import SwiftUI

struct MainTabView: View {
    @State private var selection: AppTab = .money

    enum AppTab: Hashable { case money, plan, scan, lists, profile }

    var body: some View {
        TabView(selection: $selection) {
            Tab("Money", systemImage: "dollarsign.circle.fill", value: .money) {
                MoneyHomeView()
            }
            Tab("Plan", systemImage: "calendar", value: .plan) {
                WeekPlanView()
            }
            Tab("Scan", systemImage: "camera.viewfinder", value: .scan) {
                ScanHubView()
            }
            Tab("Lists", systemImage: "cart.fill", value: .lists) {
                ShoppingListsView()
            }
            Tab("Me", systemImage: "person.crop.circle.fill", value: .profile) {
                ProfileView()
            }
        }
        .tint(.savings)
    }
}

#Preview {
    MainTabView()
        .modelContainer(PreviewData.container)
        .environment(PreviewData.profileStore)
        .environment(PreviewData.planStore)
        .environment(PreviewData.scanStore)
        .environment(PreviewData.shoppingStore)
        .environment(PreviewData.dashboardStore)
}
