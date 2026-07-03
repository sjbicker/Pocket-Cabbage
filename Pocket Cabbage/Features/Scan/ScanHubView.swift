//
//  ScanHubView.swift
//  Pocket Cabbage
//
//  Entry point for the center Scan tab. Launches the bi-weekly Sync Day wizard
//  and offers quick one-off pantry/ad scans.
//

import SwiftUI

struct ScanHubView: View {
    @Environment(DashboardStore.self) private var dashboardStore
    @State private var showWizard = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    syncCard
                    HStack(spacing: 12) {
                        NavigationLink { CameraScanView(zone: .pantry) } label: {
                            quickTile("Scan pantry", "cabinet")
                        }
                        NavigationLink { AdScanReviewView() } label: {
                            quickTile("Scan ads", "newspaper")
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Scan")
            .sheet(isPresented: $showWizard) { SyncDayWizardView() }
        }
    }

    private var syncCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sync Day 🔄").font(.title2.weight(.semibold))
            Text("Every ~2 weeks · takes about 5 minutes. We'll walk pantry → fridge → freezer → ads, then draft your week.")
                .font(.subheadline).foregroundStyle(.secondary)
            let days = dashboardStore.daysSinceLastSync()
            if days > 13 {
                Label("Last scan \(days) days ago — you're due.", systemImage: "clock.badge.exclamationmark")
                    .font(.caption).foregroundStyle(Color.overBudget)
            }
            PrimaryButton(title: "Start Sync Day", systemImage: "camera.viewfinder") { showWizard = true }
        }
        .padding()
        .background(Color.savingsFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func quickTile(_ title: String, _ symbol: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: symbol).font(.title)
            Text(title).font(.subheadline.weight(.medium))
        }
        .frame(maxWidth: .infinity).padding(.vertical, 24)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    ScanHubView().withPreviewStores()
}
