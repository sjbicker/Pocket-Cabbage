//
//  ScanStore.swift
//  Pocket Cabbage
//
//  Drives the bi-weekly "Sync Day" wizard (pantry → fridge → freezer → ads).
//  Sends captured images to the backend vision endpoints and lets the user
//  confirm/adjust before persisting to the SwiftData inventory.
//

import Foundation
import SwiftData

/// An editable, recognized item shown in the confirm/adjust list.
struct DetectedItem: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var quantity: Double = 1
    var unit: String = "unit"
    /// false → the "tap to name" case from the wireframes (1d).
    var recognized: Bool = true
}

@MainActor @Observable
final class ScanStore {
    private let api: APIClient
    private let context: ModelContext

    let zones: [StorageZone] = [.pantry, .fridge, .freezer]
    /// 0…2 = zones, 3 = ads.
    var wizardStep = 0
    var isScanning = false
    var errorMessage: String?

    /// Items detected for the current zone, editable before confirming.
    var detected: [DetectedItem] = []
    /// Deals extracted from the most recent ad scan (1f).
    var scannedDeals: [RankedDeal] = []
    var adStoreName: String?

    init(api: APIClient, context: ModelContext) {
        self.api = api
        self.context = context
    }

    var currentZone: StorageZone? {
        zones.indices.contains(wizardStep) ? zones[wizardStep] : nil
    }
    var isAdsStep: Bool { wizardStep == zones.count }

    // MARK: - Scanning

    func scanZone(imageBase64: String, mediaType: String = "image/jpeg") async {
        isScanning = true
        errorMessage = nil
        defer { isScanning = false }
        do {
            let result = try await api.scanPantry(imageBase64: imageBase64, mediaType: mediaType)
            detected = result.items.map { DetectedItem(name: $0.name, quantity: $0.quantity, unit: $0.unit) }
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }

    func scanAd(imageBase64: String, mediaType: String = "image/jpeg") async {
        isScanning = true
        errorMessage = nil
        defer { isScanning = false }
        do {
            let result = try await api.scanFlyer(imageBase64: imageBase64, mediaType: mediaType)
            adStoreName = result.store
            scannedDeals = result.items.map {
                RankedDeal(item: $0.name,
                           salePriceText: $0.salePrice.map { moneyString($0) } ?? "—",
                           regularPriceText: "", relevance: result.store ?? "")
            }
            // persist deals for meal-plan sale matching
            for deal in result.items {
                let model = AdDeal(store: result.store ?? "Store", item: deal.name,
                                   salePrice: deal.salePrice ?? 0)
                context.insert(model)
            }
            try? context.save()
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }

    // MARK: - Confirm / advance

    func confirmCurrentZone() {
        guard let zone = currentZone else { return }
        for item in detected where !item.name.isEmpty {
            context.insert(StoredPantryItem(name: item.name, zone: zone,
                                            quantity: item.quantity, unit: item.unit))
        }
        try? context.save()
        detected = []
        wizardStep += 1
    }

    func addDetectedItem() { detected.append(DetectedItem(name: "", recognized: false)) }

    func reset() {
        wizardStep = 0
        detected = []
        scannedDeals = []
        adStoreName = nil
        errorMessage = nil
    }
}
