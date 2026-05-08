//
//  NotchContentView.swift
//  Recall
//
//  Root SwiftUI view — NotchShape is the main container,
//  all content lives inside its visible bounds.
//

import SwiftUI

// MARK: - Tab

enum RecallTab: String, CaseIterable {
    case clipboard = "Clipboard"
    case chat = "AI Chat"

    var icon: String {
        switch self {
        case .clipboard: return "clipboard"
        case .chat: return "bubble.left.and.bubble.right.fill"
        }
    }
}

struct NotchContentView: View {
    var clipboardViewModel: ClipboardViewModel
    var chatViewModel: ChatViewModel
    var apiKeyStore: APIKeyStoreProtocol
    var expansionState: NotchExpansionState

    @State private var selectedTab: RecallTab = .clipboard
    @State private var isHovered: Bool = false

    private var isExpanded: Bool { expansionState.isExpanded }

    var body: some View {
        // The NotchShape IS the main view — everything is drawn inside it
        ZStack {
            // 1. NotchShape as the solid black background
            NotchShape()
                .fill(Color.black)

            // 2. Content placed INSIDE the notch shape bounds
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let leftInset = w * 0.085
                let rightInset = w * 0.087
                let topInset = isExpanded ? h * 0.01 : h * 0.15
                let bottomInset = isExpanded ? h * 0.005 : h * 0.05

                Group {
                    if isExpanded {
                        expandedView
                    } else {
                        collapsedView
                    }
                }
                .frame(
                    width: w - leftInset - rightInset,
                    height: h - topInset - bottomInset
                )
                .offset(x: leftInset, y: topInset)
            }

            // 3. Star sparkle particles on hover
            GeometryReader { geo in
                StarParticleView(
                    isActive: isHovered,
                    particleCount: 6,
                    bounds: geo.size
                )
            }
            .allowsHitTesting(false)
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isExpanded)
    }

    // MARK: - Collapsed View (Notch Pill)

    private var collapsedView: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.39, green: 0.40, blue: 0.95),
                            Color(red: 0.55, green: 0.36, blue: 0.96)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 8, height: 8)

            Text("Recall")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(isHovered ? 0.9 : 0.6))

            if !clipboardViewModel.clipboardItems.isEmpty {
                Text("·  \(clipboardViewModel.clipboardItems.count)")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(isHovered ? 0.5 : 0.3))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Expanded View

    private var expandedView: some View {
        VStack(spacing: 0) {
            // Top bar with tabs + controls
            topBar

            Divider()
                .overlay(.white.opacity(0.06))
                .padding(.top, 4)

            // Content area
            HStack(spacing: 0) {
                // Main content (left/full area)
                mainContent
                    .frame(maxWidth: .infinity)

                // Side info panel when on clipboard tab
                if selectedTab == .clipboard && !clipboardViewModel.clipboardItems.isEmpty {
                    Divider()
                        .overlay(.white.opacity(0.06))

                    sideInfoPanel
                        .frame(width: 170)
                }
            }
            .frame(maxHeight: .infinity)

            // Bottom bar
            bottomBar
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 0) {
            // Tab icons
            HStack(spacing: 4) {
                ForEach(RecallTab.allCases, id: \.self) { tab in
                    tabIcon(tab)
                }
            }

            Spacer()

            // Recall title
            HStack(spacing: 5) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.39, green: 0.40, blue: 0.95),
                                Color(red: 0.55, green: 0.36, blue: 0.96)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 7, height: 7)

                Text("Recall")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            // Controls
            HStack(spacing: 6) {
                if selectedTab == .clipboard {
                    Button(action: { clipboardViewModel.clearAll() }) {
                        Image(systemName: "trash")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.35))
                            .frame(width: 26, height: 26)
                            .background(Circle().fill(.white.opacity(0.06)))
                    }
                    .buttonStyle(.plain)
                    .help("Clear unpinned")
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.top, 4)
    }

    @ViewBuilder
    private func tabIcon(_ tab: RecallTab) -> some View {
        let isSelected = selectedTab == tab

        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        }) {
            Image(systemName: tab.icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isSelected ? .white.opacity(0.9) : .white.opacity(0.3))
                .frame(width: 30, height: 26)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(isSelected ? .white.opacity(0.1) : .clear)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        switch selectedTab {
        case .clipboard:
            clipboardContent
        case .chat:
            ChatView(viewModel: chatViewModel, apiKeyStore: apiKeyStore)
        }
    }

    private var clipboardContent: some View {
        VStack(spacing: 0) {
            SearchBarView(
                searchText: Binding(
                    get: { clipboardViewModel.searchQuery },
                    set: { clipboardViewModel.searchQuery = $0 }
                ),
                onSearch: { clipboardViewModel.search() },
                onClear: { clipboardViewModel.loadItems() }
            )
            .padding(.horizontal, 6)
            .padding(.top, 6)

            if clipboardViewModel.clipboardItems.isEmpty {
                EmptyStateView(isSearching: !clipboardViewModel.searchQuery.isEmpty)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ClipboardListView(
                    items: clipboardViewModel.clipboardItems,
                    selectedIndex: clipboardViewModel.selectedIndex,
                    onSelect: { clipboardViewModel.selectItem($0) },
                    onDelete: { clipboardViewModel.deleteItem($0) },
                    onTogglePin: { clipboardViewModel.togglePin($0) }
                )
            }
        }
    }

    // MARK: - Side Info Panel

    private var sideInfoPanel: some View {
        VStack(spacing: 8) {
            infoCard(
                icon: "clipboard.fill",
                label: "CLIPBOARD",
                value: "\(clipboardViewModel.clipboardItems.count) items",
                color: Color(red: 0.39, green: 0.40, blue: 0.95)
            )

            let pinnedCount = clipboardViewModel.clipboardItems.filter { $0.isPinned }.count
            infoCard(
                icon: "pin.fill",
                label: "PINNED",
                value: "\(pinnedCount)",
                color: .orange
            )

            infoCard(
                icon: "command",
                label: "SHORTCUT",
                value: "⌘⇧V",
                color: .cyan
            )

            Spacer()
        }
        .padding(.horizontal, 6)
        .padding(.top, 8)
    }

    @ViewBuilder
    private func infoCard(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.2))

                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
            }
            .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
                    .tracking(0.8)

                Text(value)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
            }

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(.white.opacity(0.06), lineWidth: 0.5)
        )
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 10) {
            if selectedTab == .clipboard {
                keyboardHint("↑↓", label: "Navigate")
                keyboardHint("⏎", label: "Paste")
                keyboardHint("⎋", label: "Close")
            }

            Spacer()

            Text("⌘⇧V to toggle")
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.2))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background(.white.opacity(0.02))
    }

    @ViewBuilder
    private func keyboardHint(_ key: String, label: String) -> some View {
        HStack(spacing: 3) {
            Text(key)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.35))
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(.white.opacity(0.06))
                )

            Text(label)
                .font(.system(size: 9, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.2))
        }
    }
}
