//
//  NotchContentView.swift
//  Recall
//
//  Root SwiftUI view hosted in the notch panel.
//

import SwiftUI

struct NotchContentView: View {
    @Bindable var viewModel: ClipboardViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()
                .background(.white.opacity(0.1))

            // Search bar
            SearchBarView(
                searchText: $viewModel.searchQuery,
                onSearch: { viewModel.search() },
                onClear: { viewModel.loadItems() }
            )
            .padding(.horizontal, 8)
            .padding(.top, 8)

            // Content
            if viewModel.clipboardItems.isEmpty {
                EmptyStateView(isSearching: !viewModel.searchQuery.isEmpty)
                    .frame(maxHeight: .infinity)
            } else {
                ClipboardListView(
                    items: viewModel.clipboardItems,
                    selectedIndex: viewModel.selectedIndex,
                    onSelect: { viewModel.selectItem($0) },
                    onDelete: { viewModel.deleteItem($0) },
                    onTogglePin: { viewModel.togglePin($0) }
                )
            }

            // Footer
            footerView
        }
        .frame(width: 360, height: 480)
        .background(
            ZStack {
                // Dark base
                Color.black.opacity(0.85)

                // Glass effect
                VisualEffectBackground(
                    material: .hudWindow,
                    blendingMode: .behindWindow,
                    state: .active
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.2),
                            .white.opacity(0.05),
                            .white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
        .shadow(color: .black.opacity(0.5), radius: 30, y: 10)
        .onKeyPress(.upArrow) {
            viewModel.moveSelectionUp()
            return .handled
        }
        .onKeyPress(.downArrow) {
            viewModel.moveSelectionDown()
            return .handled
        }
        .onKeyPress(.return) {
            viewModel.confirmSelection()
            return .handled
        }
        .onKeyPress(.escape) {
            viewModel.onPanelShouldHide?()
            return .handled
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            // App title with gradient icon
            HStack(spacing: 6) {
                Image(systemName: "clipboard.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.39, green: 0.40, blue: 0.95),
                                Color(red: 0.55, green: 0.36, blue: 0.96)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Recall")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
            }

            Spacer()

            // Item count badge
            Text("\(viewModel.clipboardItems.count)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(.white.opacity(0.1))
                )

            // Clear all button
            Button(action: { viewModel.clearAll() }) {
                Image(systemName: "trash")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .buttonStyle(.plain)
            .help("Clear all unpinned items")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack(spacing: 12) {
            keyboardHint("↑↓", label: "Navigate")
            keyboardHint("⏎", label: "Paste")
            keyboardHint("⎋", label: "Close")

            Spacer()

            Text("⌘⇧V to toggle")
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.25))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.white.opacity(0.03))
    }

    @ViewBuilder
    private func keyboardHint(_ key: String, label: String) -> some View {
        HStack(spacing: 3) {
            Text(key)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(.white.opacity(0.08))
                )

            Text(label)
                .font(.system(size: 9, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.25))
        }
    }
}
