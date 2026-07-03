//
//  SyncDayWizardView.swift
//  Pocket Cabbage
//
//  Wireframe 1e: the guided bi-weekly stepper — Pantry → Fridge → Freezer → Ads.
//  Each zone: capture a photo, AI identifies items, user confirms/adjusts with
//  +/- steppers, then advances. The ads step feeds into a fresh meal plan.
//

import SwiftUI

struct SyncDayWizardView: View {
    @Environment(ScanStore.self) private var scanStore
    @Environment(PlanStore.self) private var planStore
    @Environment(ProfileStore.self) private var profileStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var scanStore = scanStore

        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                stepper
                if scanStore.isAdsStep {
                    adsStep($scanStore)
                } else if let zone = scanStore.currentZone {
                    zoneStep(zone, $scanStore)
                }
                Spacer(minLength: 0)
                footer
            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Sync Day")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { scanStore.reset(); dismiss() }
                }
            }
            .overlay { if scanStore.isScanning { ProgressView("Reading…").controlSize(.large) } }
        }
    }

    // MARK: - Progress

    private var stepper: some View {
        let labels = ["Pantry", "Fridge", "Freezer", "Ads"]
        return VStack(spacing: 6) {
            HStack(spacing: 4) {
                ForEach(0..<4) { index in
                    Circle()
                        .fill(index <= scanStore.wizardStep ? Color.savings : Color.secondary.opacity(0.2))
                        .frame(width: 22, height: 22)
                        .overlay(Text(index < scanStore.wizardStep ? "✓" : "\(index + 1)")
                            .font(.caption2).foregroundStyle(.white))
                    if index < 3 {
                        Rectangle().fill(index < scanStore.wizardStep ? Color.savings : Color.secondary.opacity(0.2))
                            .frame(height: 2)
                    }
                }
            }
            HStack {
                ForEach(labels, id: \.self) { Text($0).frame(maxWidth: .infinity) }
            }
            .font(.caption2).foregroundStyle(.secondary)
        }
    }

    // MARK: - Zone step

    private func zoneStep(_ zone: StorageZone, _ scanStore: Bindable<ScanStore>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(zone.title) — confirm what changed").font(.headline)

            CaptureControl(onCapture: { base64, media in
                Task { await self.scanStore.scanZone(imageBase64: base64, mediaType: media) }
            }) {
                Label("Scan \(zone.title.lowercased()) with camera", systemImage: "camera")
                    .frame(maxWidth: .infinity).padding()
                    .background(Color(.secondarySystemGroupedBackground),
                                in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                        .foregroundStyle(.secondary))
            }

            if let error = self.scanStore.errorMessage {
                Text(error).font(.caption).foregroundStyle(Color.overBudget)
            }

            if self.scanStore.detected.isEmpty {
                Text("No items yet — scan the \(zone.title.lowercased()), or add them by hand.")
                    .font(.subheadline).foregroundStyle(.secondary)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(scanStore.detected) { $item in
                            detectedRow($item)
                        }
                    }
                }
            }

            Button { self.scanStore.addDetectedItem() } label: {
                Label("Add an item", systemImage: "plus.circle")
            }
            .font(.subheadline)
        }
    }

    private func detectedRow(_ item: Binding<DetectedItem>) -> some View {
        HStack {
            if item.wrappedValue.recognized {
                TextField("item", text: item.name).font(.subheadline)
            } else {
                TextField("tap to name", text: item.name)
                    .font(.subheadline).foregroundStyle(Color.overBudget)
            }
            Spacer()
            Stepper(value: item.quantity, in: 0...99) {
                Text("\(Int(item.wrappedValue.quantity))").monospacedDigit()
            }
            .labelsHidden()
            Text("\(Int(item.wrappedValue.quantity))").frame(width: 24).monospacedDigit()
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Ads step

    private func adsStep(_ scanStore: Bindable<ScanStore>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Scan this week's ads").font(.headline)
            CaptureControl(onCapture: { base64, media in
                Task { await self.scanStore.scanAd(imageBase64: base64, mediaType: media) }
            }) {
                Label("Scan a store ad", systemImage: "camera")
                    .frame(maxWidth: .infinity).padding()
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                        .foregroundStyle(.secondary))
            }
            let deals = self.scanStore.scannedDeals.isEmpty ? SampleData.rankedDeals : self.scanStore.scannedDeals
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(deals) { DealRow(deal: $0) }
                }
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        Group {
            if scanStore.isAdsStep {
                PrimaryButton(title: "Build this week's plan →", systemImage: "sparkles") {
                    Task {
                        await planStore.generate(profile: profileStore.profile)
                        scanStore.reset()
                        dismiss()
                    }
                }
            } else if let zone = scanStore.currentZone {
                let next = scanStore.wizardStep < 2 ? scanStore.zones[scanStore.wizardStep + 1].title : "Ads"
                PrimaryButton(title: "Looks right — next: \(next) →") {
                    scanStore.confirmCurrentZone()
                }
                .id(zone) // reset styling per zone
            }
        }
    }
}

/// Ranked deal card used in the ads step and ad-review screen (1f).
struct DealRow: View {
    let deal: RankedDeal
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(deal.item).font(.subheadline.weight(.medium))
                Text([deal.regularPriceText, deal.relevance].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(deal.salePriceText).font(.subheadline.weight(.semibold)).foregroundStyle(Color.savings)
        }
        .padding(12)
        .background(deal.matchesPlan ? Color.savingsFill : Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12)
            .strokeBorder(deal.matchesPlan ? Color.savings.opacity(0.4) : Color.primary.opacity(0.06)))
    }
}

#Preview {
    SyncDayWizardView().withPreviewStores()
}
