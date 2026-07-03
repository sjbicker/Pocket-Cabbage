//
//  ProfileView.swift
//  Pocket Cabbage
//
//  Settings & account: household profile, diet/tastes/stores, the Recipe Box,
//  and backend diagnostics (base URL, App Attest mode, connection check).
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(ProfileStore.self) private var profileStore
    @Query private var keepers: [SavedRecipe]

    @State private var healthText: String?
    @State private var checking = false

    var body: some View {
        @Bindable var profile = profileStore.profile

        NavigationStack {
            List {
                Section("Household") {
                    Stepper("Family of \(profile.familySize)", value: $profile.familySize, in: 1...20)
                    HStack {
                        Text("ZIP")
                        Spacer()
                        TextField("ZIP", text: $profile.zipCode)
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                            .multilineTextAlignment(.trailing)
                    }
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Weekly budget")
                            Spacer()
                            Text(moneyString(profile.weeklyBudget)).foregroundStyle(Color.savings)
                        }
                        Slider(value: $profile.weeklyBudget, in: 40...400, step: 5).tint(.savings)
                    }
                }

                Section("Preferences") {
                    labeledChips("Dietary", profile.dietaryRestrictions, empty: "None set")
                    labeledChips("Tastes", profile.tastePreferences, empty: "None set")
                    labeledChips("Stores", profile.favoriteStores, empty: "None set")
                }

                Section {
                    NavigationLink {
                        RecipeBoxView()
                    } label: {
                        Label("Recipe Box · \(keepers.count) keepers", systemImage: "star")
                    }
                }

                Section("Backend") {
                    LabeledContent("Gateway", value: APIConfig.baseURL.absoluteString)
                        .font(.footnote)
                    LabeledContent("App Attest", value: APIConfig.appAttestEnabled ? "Enabled" : "Dev mode")
                    Button {
                        checkConnection()
                    } label: {
                        HStack {
                            Label("Check connection", systemImage: "wave.3.right")
                            Spacer()
                            if checking { ProgressView() }
                            else if let healthText { Text(healthText).foregroundStyle(.secondary) }
                        }
                    }
                }
            }
            .onChange(of: profile.familySize) { profileStore.save() }
            .onChange(of: profile.weeklyBudget) { profileStore.save() }
            .onChange(of: profile.zipCode) { profileStore.save() }
            .navigationTitle("Me")
        }
    }

    private func labeledChips(_ title: String, _ values: [String], empty: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline)
            if values.isEmpty {
                Text(empty).font(.caption).foregroundStyle(.tertiary)
            } else {
                let columns = [GridItem(.adaptive(minimum: 80), spacing: 6)]
                LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
                    ForEach(values, id: \.self) { Chip(text: $0, tint: .savings) }
                }
            }
        }
    }

    private func checkConnection() {
        checking = true
        healthText = nil
        Task {
            defer { checking = false }
            do {
                let health = try await APIClient().health()
                healthText = "OK · \(health.provider) · redis \(health.redis ? "up" : "down")"
            } catch {
                healthText = "Unreachable"
            }
        }
    }
}

#Preview {
    ProfileView().withPreviewStores()
}
