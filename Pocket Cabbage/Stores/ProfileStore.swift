//
//  ProfileStore.swift
//  Pocket Cabbage
//
//  Owns the single HouseholdProfile and the onboarding gate. Backed by
//  SwiftData; fetches an existing profile or creates one on first launch.
//

import Foundation
import SwiftData

@MainActor @Observable
final class ProfileStore {
    private let context: ModelContext
    var profile: HouseholdProfile

    init(context: ModelContext) {
        self.context = context
        let descriptor = FetchDescriptor<HouseholdProfile>()
        if let existing = try? context.fetch(descriptor).first {
            profile = existing
        } else {
            let created = HouseholdProfile()
            context.insert(created)
            profile = created
            try? context.save()
        }
    }

    var onboardingComplete: Bool { profile.onboardingComplete }

    func completeOnboarding() {
        profile.onboardingComplete = true
        save()
    }

    func save() { try? context.save() }
}
