//
//  ReceiptReconcileView.swift
//  Pocket Cabbage
//
//  Wireframe 5b: snap a receipt, OCR the line items, reconcile against the
//  planned list. Shows planned/actual/diff, per-line variances, unplanned items,
//  a "learned" banner and a save that updates future projections.
//

import SwiftUI

struct ReceiptReconcileView: View {
    @Environment(DashboardStore.self) private var dashboardStore
    @Environment(\.dismiss) private var dismiss
    @State private var savedConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                captureRow
                summaryStrip
                lineItems
                unplannedCallout
                learnedBanner
                PrimaryButton(title: "Save & update my numbers →", systemImage: "checkmark") {
                    dashboardStore.saveReceipt()
                    savedConfirmation = true
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Receipt")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .alert("Saved", isPresented: $savedConfirmation) {
            Button("Done") { dismiss() }
        } message: { Text("Your projections have been updated.") }
        .overlay { if dashboardStore.isReconciling { ProgressView("Reading receipt…").controlSize(.large) } }
    }

    private var captureRow: some View {
        HStack(spacing: 12) {
            CaptureControl(onCapture: { base64, media in
                Task { await dashboardStore.reconcile(imageBase64: base64, mediaType: media) }
            }) {
                PlaceholderImage(systemImage: "doc.text.viewfinder", height: 92)
                    .frame(width: 72)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("\(dashboardStore.reconcileStore) receipt").font(.headline)
                Text("Read \(dashboardStore.reconcileLines.count) line items · matched \(dashboardStore.matchedCount) to your list.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }

    private var summaryStrip: some View {
        HStack(spacing: 0) {
            summaryCell("Planned", dashboardStore.plannedTotal, tint: .primary)
            Divider()
            summaryCell("Actual", dashboardStore.actualTotal, tint: .overBudget, fill: true)
            Divider()
            summaryCell("Diff", dashboardStore.diff, tint: .overBudget, signed: true)
        }
        .frame(height: 64)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.primary.opacity(0.08)))
    }

    private func summaryCell(_ label: String, _ value: Double, tint: Color,
                             fill: Bool = false, signed: Bool = false) -> some View {
        VStack(spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(signed && value >= 0 ? "+\(moneyString(value))" : moneyString(value))
                .font(.headline).foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(fill ? Color.overBudgetFill : Color.clear)
    }

    private var lineItems: some View {
        VStack(spacing: 6) {
            ForEach(dashboardStore.reconcileLines.filter { !$0.isUnplanned }) { line in
                HStack {
                    Image(systemName: (line.variance ?? 0) > 0 ? "exclamationmark.triangle" : "checkmark")
                        .foregroundStyle((line.variance ?? 0) > 0 ? Color.overBudget : Color.savings)
                    Text(line.name)
                    Spacer()
                    Text(moneyString(line.price))
                    if let variance = line.variance, variance != 0 {
                        Text("+\(moneyString(variance))").foregroundStyle(Color.overBudget)
                    } else {
                        Text("= plan").foregroundStyle(Color.savings)
                    }
                }
                .font(.subheadline)
                .padding(.vertical, 5)
                Divider()
            }
        }
    }

    @ViewBuilder private var unplannedCallout: some View {
        let unplanned = dashboardStore.unplannedLines
        if !unplanned.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(unplanned.count) unplanned items").font(.subheadline.weight(.semibold))
                Text(unplanned.map { "\($0.name) \(moneyString($0.price))" }.joined(separator: " · "))
                    .font(.caption)
                Text("Keep as \"treats budget\"?").font(.caption).foregroundStyle(.secondary)
            }
            .foregroundStyle(Color.alert)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.alert.opacity(0.5)))
        }
    }

    private var learnedBanner: some View {
        Label("Learned: Kroger milk runs ~$0.40 over ad price → future projections adjusted.",
              systemImage: "brain.head.profile")
            .font(.caption)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.savingsFill, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack { ReceiptReconcileView() }.withPreviewStores()
}
