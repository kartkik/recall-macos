//
//  ClipboardListView.swift
//  Recall
//
//  Scrollable list of clipboard items grouped by pinned/recent.
//

import SwiftUI

struct ClipboardListView: View {
    let items: [ClipboardItem]
    let selectedIndex: Int?
    var onSelect: (ClipboardItem) -> Void
    var onDelete: (ClipboardItem) -> Void
    var onTogglePin: (ClipboardItem) -> Void

    var body: some View {
        let pinned = items.filter { $0.isPinned }
        let recent = items.filter { !$0.isPinned }

        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 2) {
                    // Pinned section
                    if !pinned.isEmpty {
                        sectionHeader("Pinned", icon: "pin.fill")

                        ForEach(Array(pinned.enumerated()), id: \.element.id) { globalIndex, item in
                            let absoluteIndex = items.firstIndex(where: { $0.id == item.id }) ?? 0
                            ClipboardItemRow(
                                item: item,
                                isSelected: selectedIndex == absoluteIndex,
                                onSelect: { onSelect(item) },
                                onDelete: { onDelete(item) },
                                onTogglePin: { onTogglePin(item) }
                            )
                            .id(item.id)
                        }
                    }

                    // Recent section
                    if !recent.isEmpty {
                        if !pinned.isEmpty {
                            sectionHeader("Recent", icon: "clock")
                        }

                        ForEach(Array(recent.enumerated()), id: \.element.id) { _, item in
                            let absoluteIndex = items.firstIndex(where: { $0.id == item.id }) ?? 0
                            ClipboardItemRow(
                                item: item,
                                isSelected: selectedIndex == absoluteIndex,
                                onSelect: { onSelect(item) },
                                onDelete: { onDelete(item) },
                                onTogglePin: { onTogglePin(item) }
                            )
                            .id(item.id)
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
            .onChange(of: selectedIndex) { _, newIndex in
                if let newIndex, newIndex < items.count {
                    withAnimation(.easeOut(duration: 0.15)) {
                        proxy.scrollTo(items[newIndex].id, anchor: .center)
                    }
                }
            }
        }
    }

    // MARK: - Section Header

    @ViewBuilder
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.white.opacity(0.35))

            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.35))
                .tracking(1.2)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 2)
    }
}
