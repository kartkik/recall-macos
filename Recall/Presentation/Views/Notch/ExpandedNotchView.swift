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
    var apiKeyStore: APIKeyStoreProtocol
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. Fixed Top Bar
            NotchTopBar(
                selectedTab: $selectedTab,
                clipboardViewModel: clipboardViewModel,
                chatViewModel: chatViewModel,
                apiKeyStore: apiKeyStore
            )

            Divider()
                .overlay(.white.opacity(0.06))
                .padding(.top, 4)

            // 2. Main Content Area (switches between views)
            HStack(spacing: 0) {
                mainContent
                    .frame(maxWidth: .infinity)

                // Side info panel
                if selectedTab == .clipboard && !clipboardViewModel.clipboardItems.isEmpty {
                    Divider()
                        .overlay(.white.opacity(0.06))

                    NotchSidePanel(clipboardViewModel: clipboardViewModel)
                        .frame(width: 170)
                }
            }
            .frame(maxHeight: .infinity)

            // 3. Bottom Bar
            NotchBottomBar(selectedTab: selectedTab)
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        switch selectedTab {
        case .clipboard:
            ClipboardView(viewModel: clipboardViewModel)
        case .chat:
            ChatView(viewModel: chatViewModel, apiKeyStore: apiKeyStore)
                .padding(.horizontal, 6)
        }
    }
}
