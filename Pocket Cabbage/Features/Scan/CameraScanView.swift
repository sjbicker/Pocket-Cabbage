//
//  CameraScanView.swift
//  Pocket Cabbage
//
//  Wireframe 1d: a quick one-zone capture. Snap a shelf, the backend identifies
//  items, they appear as chips, and you save them to the inventory.
//

import SwiftUI
import SwiftData

struct CameraScanView: View {
    let zone: StorageZone

    @Environment(ScanStore.self) private var scanStore
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var saved = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CaptureControl(onCapture: { base64, media in
                    Task { await scanStore.scanZone(imageBase64: base64, mediaType: media) }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "camera.viewfinder").font(.largeTitle)
                        Text("Tap to scan your \(zone.title.lowercased())")
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity).frame(height: 200)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                        .foregroundStyle(.secondary))
                }

                if scanStore.isScanning { ProgressView("Reading…") }

                if let error = scanStore.errorMessage {
                    Text(error).font(.caption).foregroundStyle(Color.overBudget)
                }

                if !scanStore.detected.isEmpty {
                    Text("Found this pass · \(scanStore.detected.count) items").font(.headline)
                    let columns = [GridItem(.adaptive(minimum: 90), spacing: 8)]
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                        ForEach(scanStore.detected) { item in
                            Text("\(item.name) ×\(Int(item.quantity))")
                                .font(.caption)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(Color.savingsFill, in: Capsule())
                        }
                    }
                    PrimaryButton(title: saved ? "Saved ✓" : "Save to \(zone.title)", systemImage: "tray.and.arrow.down") {
                        save()
                    }
                    .disabled(saved)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("\(zone.title) scan")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func save() {
        for item in scanStore.detected where !item.name.isEmpty {
            context.insert(StoredPantryItem(name: item.name, zone: zone,
                                            quantity: item.quantity, unit: item.unit))
        }
        try? context.save()
        withAnimation { saved = true }
    }
}

#Preview {
    NavigationStack { CameraScanView(zone: .pantry) }.withPreviewStores()
}
