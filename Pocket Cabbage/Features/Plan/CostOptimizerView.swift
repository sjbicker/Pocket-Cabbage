//
//  CostOptimizerView.swift
//  Pocket Cabbage
//
//  Wireframe 3a: compares every ingredient across scanned ads + Kroger, shows a
//  before/after total and the list of proposed store-switches/meal-swaps, each
//  individually undoable. Accepting generates per-store shopping lists (4a).
//

import SwiftUI

struct CostOptimizerView: View {
    @Environment(PlanStore.self) private var planStore
    @Environment(\.dismiss) private var dismiss

    private var savings: Double { planStore.singleStoreTotal - planStore.optimizedTotal }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    explainer
                    beforeAfter
                    Text("What changed").font(.headline)
                    ForEach(planStore.optimizerChanges) { change in
                        changeRow(change)
                    }
                    Text("Accepting generates one shopping list per store.")
                        .font(.caption).foregroundStyle(.secondary)
                    PrimaryButton(title: "Accept optimized plan →", systemImage: "checkmark.circle") {
                        planStore.applyOptimizer()
                        dismiss()
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Cost Optimizer")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var explainer: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("💰 Cost optimizer").font(.headline)
                    Spacer()
                    Text("ON").font(.caption.weight(.bold))
                        .padding(.horizontal, 10).padding(.vertical, 2)
                        .background(Color.savings, in: Capsule()).foregroundStyle(.white)
                }
                Text("Compares every ingredient across Kroger · Aldi ad · Safeway ad and picks the cheapest mix.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.savingsFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var beforeAfter: some View {
        HStack(spacing: 10) {
            VStack(spacing: 2) {
                Text(moneyString(planStore.singleStoreTotal)).strikethrough()
                    .foregroundStyle(.secondary)
                Text("Kroger only").font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 10)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

            VStack(spacing: 2) {
                Text(moneyString(planStore.optimizedTotal)).font(.title3.weight(.semibold))
                    .foregroundStyle(Color.savings)
                Text("optimized · save \(moneyString(savings))").font(.caption)
                    .foregroundStyle(Color.savings)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 10)
            .background(Color.savingsFill, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.savings.opacity(0.5)))
        }
    }

    private func changeRow(_ change: OptimizerChange) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(change.summary)
                    .font(.subheadline.weight(.medium))
                    .strikethrough(change.undone)
                    .foregroundStyle(change.undone ? .secondary : .primary)
                Text(change.detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if !change.undone {
                Text("−\(moneyString(change.savings))")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(Color.savings)
            }
            Button { planStore.toggleUndo(change) } label: {
                Image(systemName: change.undone ? "arrow.uturn.backward.circle" : "xmark.circle")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    CostOptimizerView().withPreviewStores()
}
