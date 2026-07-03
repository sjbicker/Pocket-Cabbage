//
//  DashboardStore.swift
//  Pocket Cabbage
//
//  Backs the Money home, learning insights and receipt reconciliation. The
//  analytics numbers are sample data (no backend endpoints yet); receipt OCR
//  uses the real POST /v1/scan/receipt endpoint.
//

import Foundation
import SwiftData

@MainActor @Observable
final class DashboardStore {
    private let api: APIClient
    private let context: ModelContext

    // Sample analytics (swap for real endpoints later).
    var spent = SampleData.spentThisMonth
    var saved = SampleData.savedThisMonth
    var costPerMeal = SampleData.costPerMeal
    var projectionAccuracy = SampleData.projectionAccuracy
    var weekdaySpend = SampleData.weekdaySpend
    var weeklySavings = SampleData.weeklySavings
    var storeSpend = SampleData.storeSpend
    var accuracyTrend = SampleData.accuracyTrend
    var learningSwaps = SampleData.learningSwaps

    // Receipt reconciliation working state.
    var reconcileLines: [ReceiptLineItem] = SampleData.receiptLines
    var reconcileStore = "Kroger"
    var reconcileDate = Date.now
    var isReconciling = false
    var errorMessage: String?

    init(api: APIClient, context: ModelContext) {
        self.api = api
        self.context = context
    }

    var plannedTotal: Double { reconcileLines.compactMap(\.plannedPrice).reduce(0, +) }
    var actualTotal: Double { reconcileLines.reduce(0) { $0 + $1.price } }
    var diff: Double { actualTotal - plannedTotal }
    var matchedCount: Int { reconcileLines.filter { !$0.isUnplanned }.count }
    var unplannedLines: [ReceiptLineItem] { reconcileLines.filter(\.isUnplanned) }

    /// Days since the most recent inventory confirmation (drives the sync banner).
    func daysSinceLastSync() -> Int {
        let items = (try? context.fetch(FetchDescriptor<StoredPantryItem>())) ?? []
        guard let latest = items.map(\.lastConfirmed).max() else { return 99 }
        return Calendar.current.dateComponents([.day], from: latest, to: .now).day ?? 0
    }

    // MARK: - Receipt OCR

    func reconcile(imageBase64: String, mediaType: String = "image/jpeg") async {
        isReconciling = true
        errorMessage = nil
        defer { isReconciling = false }
        do {
            let result = try await api.scanReceipt(imageBase64: imageBase64, mediaType: mediaType)
            reconcileLines = result.items.map {
                ReceiptLineItem(name: $0.name, price: $0.price ?? 0,
                                quantity: $0.quantity ?? 1, plannedPrice: nil, isUnplanned: false)
            }
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }

    /// Persists the reconciled receipt to SwiftData.
    func saveReceipt() {
        let receipt = Receipt(store: reconcileStore, date: reconcileDate)
        receipt.plannedTotal = plannedTotal
        receipt.actualTotal = actualTotal
        receipt.lineItems = reconcileLines
        receipt.matchedCount = matchedCount
        receipt.readCount = reconcileLines.count
        context.insert(receipt)
        try? context.save()
    }
}
