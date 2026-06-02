//
//  ExpandedNotchView.swift
//  Recall
//

import SwiftUI

struct ExpandedNotchView: View {
    @Binding var selectedTab: RecallTab
    var clipboardViewModel: ClipboardViewModel
    var chatViewModel: ChatViewModel
    var mediaViewModel: MediaPlayerViewModel
    var todoViewModel: TodoViewModel
    var apiKeyStore: APIKeyStoreProtocol

    // Fixed pixel heights for pinned bars
    private let topBarHeight: CGFloat = 48

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let contentTop = topBarHeight + 1     // below top bar + divider
            let contentHeight = h - contentTop

            // ── Content — renders first (bottom z-layer) ──
            contentForSelectedTab
                .frame(width: w, height: max(contentHeight, 0))
                .clipped()
                .position(x: w / 2, y: contentTop + max(contentHeight, 0) / 2)
                .padding()

            // ── Divider — middle z-layer ──
            Divider()
                .overlay(.white.opacity(0.06))
                .frame(width: w)
                .position(x: w / 2, y: topBarHeight)

            // ── Top Bar — renders last (top z-layer, always clickable) ──
            NotchTopBar(
                selectedTab: $selectedTab,
                clipboardViewModel: clipboardViewModel,
                chatViewModel: chatViewModel,
                apiKeyStore: apiKeyStore
            )
            .frame(width: w, height: topBarHeight)
            .position(x: w / 2, y: topBarHeight / 2)
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var contentForSelectedTab: some View {
        switch selectedTab {
        case .clipboard:
            HStack(spacing: 0) {
                ClipboardView(viewModel: clipboardViewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if !clipboardViewModel.clipboardItems.isEmpty {
                    Divider()
                        .overlay(.white.opacity(0.06))
                    

                    NotchSidePanel(clipboardViewModel: clipboardViewModel)
                        .frame(width: 160)
                        
                }
            }
        case .chat:
            ChatView(viewModel: chatViewModel, apiKeyStore: apiKeyStore)
        case .calender:
            TodoView(viewModel: todoViewModel)
        }
    }
}
