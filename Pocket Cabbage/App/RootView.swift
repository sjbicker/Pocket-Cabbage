//
//  RootView.swift
//  Pocket Cabbage
//
//  Gates onboarding vs the main app.
//

import SwiftUI

struct RootView: View {
    @Environment(ProfileStore.self) private var profileStore

    var body: some View {
        if profileStore.onboardingComplete {
            MainTabView()
        } else {
            OnboardingFlow()
        }
    }
}
