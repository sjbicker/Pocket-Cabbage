//
//  OnboardingFlow.swift
//  Pocket Cabbage
//
//  First-run setup: family size, dietary needs, taste preferences, favorite
//  stores and a weekly budget. Seeds HouseholdProfile, then kicks off the first
//  meal-plan generation.
//

import SwiftUI

struct OnboardingFlow: View {
    @Environment(ProfileStore.self) private var profileStore
    @Environment(PlanStore.self) private var planStore

    @State private var step = 0
    private let steps = ["Household", "Dietary", "Tastes", "Stores", "Budget"]

    private let diets = ["Vegetarian", "Vegan", "Gluten-free", "Dairy-free", "Nut allergy", "Pescatarian"]
    private let cuisines = ["Italian", "Mexican", "Asian", "American", "Mediterranean", "Indian", "BBQ", "Comfort"]
    private let stores = ["Kroger", "Aldi", "Safeway", "Walmart", "Costco", "Trader Joe's", "Publix", "Whole Foods"]

    var body: some View {
        @Bindable var profile = profileStore.profile

        VStack(spacing: 20) {
            // progress
            HStack(spacing: 6) {
                ForEach(steps.indices, id: \.self) { index in
                    Capsule()
                        .fill(index <= step ? Color.savings : Color.secondary.opacity(0.2))
                        .frame(height: 5)
                }
            }
            .padding(.top, 8)

            HStack {
                Text("🥬 Let's set up PocketCabbage").font(.title2.weight(.semibold))
                Spacer()
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    switch step {
                    case 0: householdStep(profile)
                    case 1: chipStep(title: "Any dietary needs?",
                                     subtitle: "We'll never suggest meals that break these.",
                                     options: diets, selection: $profile.dietaryRestrictions)
                    case 2: chipStep(title: "What does your family love?",
                                     subtitle: "Pick cuisines and flavors you lean toward.",
                                     options: cuisines, selection: $profile.tastePreferences)
                    case 3: chipStep(title: "Which stores do you shop?",
                                     subtitle: "We'll scan these ads and compare prices.",
                                     options: stores, selection: $profile.favoriteStores)
                    case 4: budgetStep(profile)
                    default: EmptyView()
                    }
                }
                .padding(.vertical, 8)
            }

            Spacer(minLength: 0)

            HStack(spacing: 12) {
                if step > 0 {
                    Button("Back") { withAnimation { step -= 1 } }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.secondary.opacity(0.3)))
                }
                PrimaryButton(title: step == steps.count - 1 ? "Start planning →" : "Next") {
                    if step == steps.count - 1 { finish() }
                    else { withAnimation { step += 1 } }
                }
            }
        }
        .padding()
    }

    // MARK: - Steps

    private func householdStep(_ profile: HouseholdProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How many people are you cooking for?")
                .font(.headline)
            Stepper(value: Binding(get: { profile.familySize },
                                   set: { profile.familySize = $0 }), in: 1...20) {
                HStack {
                    Image(systemName: "person.2.fill").foregroundStyle(.secondary)
                    Text("Family of \(profile.familySize)").font(.title3.weight(.medium))
                }
            }
            .padding()
            .card()

            Text("ZIP code (for local pricing)").font(.headline).padding(.top, 4)
            TextField("ZIP", text: Binding(get: { profile.zipCode },
                                           set: { profile.zipCode = $0 }))
                #if os(iOS)
                .keyboardType(.numberPad)
                #endif
                .padding()
                .card()
        }
    }

    private func chipStep(title: String, subtitle: String,
                          options: [String], selection: Binding<[String]>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            SelectableChipGrid(options: options, selection: selection)
                .padding(.top, 4)
        }
    }

    private func budgetStep(_ profile: HouseholdProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Weekly grocery budget").font(.headline)
            Text("Optional — we'll try to keep plans under this.")
                .font(.subheadline).foregroundStyle(.secondary)
            HStack {
                Text(moneyString(profile.weeklyBudget, showsZeroAsFree: false))
                    .font(.largeTitle.weight(.semibold))
                    .foregroundStyle(Color.savings)
                Spacer()
            }
            Slider(value: Binding(get: { profile.weeklyBudget },
                                  set: { profile.weeklyBudget = $0 }), in: 40...400, step: 5)
                .tint(.savings)
            HStack { Text("$40"); Spacer(); Text("$400") }
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }

    private func finish() {
        profileStore.completeOnboarding()
        Task { await planStore.generate(profile: profileStore.profile) }
    }
}

/// Multi-select chip grid backed by a `[String]` selection.
struct SelectableChipGrid: View {
    let options: [String]
    @Binding var selection: [String]

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(options, id: \.self) { option in
                let isOn = selection.contains(option)
                Button {
                    if isOn { selection.removeAll { $0 == option } }
                    else { selection.append(option) }
                } label: {
                    Text(option)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(isOn ? Color.savingsFill : Color(.secondarySystemGroupedBackground),
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(isOn ? Color.savings : Color.primary.opacity(0.08)))
                        .foregroundStyle(isOn ? Color.savings : .primary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    OnboardingFlow().withPreviewStores()
}
