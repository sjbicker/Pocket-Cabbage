//
//  AdScanReviewView.swift
//  Pocket Cabbage
//
//  Wireframe 1f: after scanning a store ad, show extracted deals, how many
//  match items you cook with, and a CTA to build the week around them.
//

import SwiftUI

struct AdScanReviewView: View {
    @Environment(ScanStore.self) private var scanStore
    @Environment(PlanStore.self) private var planStore
    @Environment(ProfileStore.self) private var profileStore
    @Environment(\.dismiss) private var dismiss

    private var deals: [RankedDeal] {
        scanStore.scannedDeals.isEmpty ? SampleData.rankedDeals : scanStore.scannedDeals
    }
    private var matchCount: Int { deals.filter(\.matchesPlan).count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CaptureControl(onCapture: { base64, media in
                    Task { await scanStore.scanAd(imageBase64: base64, mediaType: media) }
                }) {
                    Label("Scan a store ad", systemImage: "camera")
                        .frame(maxWidth: .infinity).padding()
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                            .foregroundStyle(.secondary))
                }

                HStack(spacing: 12) {
                    PlaceholderImage(systemImage: "newspaper", height: 90)
                        .frame(width: 74)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(scanStore.adStoreName ?? "Weekly ad") · scanned ✓")
                            .font(.headline)
                        Text("Found \(deals.count) deals.")
                            .font(.subheadline).foregroundStyle(.secondary)
                        Text("\(matchCount) match items you cook with.")
                            .font(.subheadline).foregroundStyle(Color.savings)
                    }
                }

                Text("Best matches for your plan").font(.headline)
                ForEach(deals) { DealRow(deal: $0) }

                PrimaryButton(title: "Build this week's plan around these →", systemImage: "sparkles") {
                    Task {
                        await planStore.generate(profile: profileStore.profile)
                        dismiss()
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Ad Scan")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#Preview {
    NavigationStack { AdScanReviewView() }.withPreviewStores()
}
