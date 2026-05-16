//
//  NotchContentView.swift
//  Recall
//
//  Root SwiftUI view — NotchShape is the main container,
//  all content lives inside its visible bounds.
//

import SwiftUI

struct NotchContentView: View {

    var clipboardViewModel: ClipboardViewModel
    var chatViewModel: ChatViewModel
    var mediaViewModel: MediaPlayerViewModel
    var apiKeyStore: APIKeyStoreProtocol
    var expansionState: NotchExpansionState

    @State private var selectedTab: RecallTab = .clipboard
    @State private var isHovered: Bool = false

    private var isExpanded: Bool {
        expansionState.isExpanded
    }

    var body: some View {

        ZStack {

            // MARK: - Background Shape

            NotchShape()
                .fill(Color.black)

            // MARK: - Main Content

            GeometryReader { geo in

                let w = geo.size.width
                let h = geo.size.height

                let leftInset = w * 0.085
                let rightInset = w * 0.087

                let topInset = isExpanded ? h * 0.01 : h * 0.15
                let bottomInset = isExpanded ? h * 0.005 : h * 0.05

                Group {

                    if isExpanded {

                        VStack(spacing: 0) {

                            // FIXED TOP BAR
                            NotchTopBar(
                                selectedTab: $selectedTab,
                                clipboardViewModel: clipboardViewModel,
                                chatViewModel: chatViewModel,
                                apiKeyStore: apiKeyStore
                            )

                            Divider()
                                .overlay(.white.opacity(0.08))

                            // TAB CONTENT
                            Group {

                                switch selectedTab {

                                case .clipboard:
ClipboardView(viewModel: clipboardViewModel)
                                    
                                case .chat:

                                    ChatView(
                                        viewModel: chatViewModel,
                                        apiKeyStore: apiKeyStore
                                    )
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }

                    } else {

                        // COLLAPSED VIEW
                        CollapsedNotchView(
                            clipboardViewModel: clipboardViewModel,
                            mediaViewModel: mediaViewModel,
                            isHovered: isHovered
                        )
                    }
                }
                .frame(
                    width: w - leftInset - rightInset,
                    height: h - topInset - bottomInset
                )
                .offset(
                    x: leftInset,
                    y: topInset
                )
            }

            // MARK: - Hover Particles

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
        .animation(
            .spring(response: 0.4, dampingFraction: 0.85),
            value: isExpanded
        )
    }
}
