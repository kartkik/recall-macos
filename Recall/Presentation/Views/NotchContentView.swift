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
    var todoViewModel: TodoViewModel
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

                // Insets keep content within the straight edges of the NotchShape.
                // The shape's left/right walls are at ~8.4%/91.4% of width,
                // and the bottom corners curve inward starting at ~70-75% of height.
                let leftInset = w * 0.09
                let rightInset = w * 0.09

                let topInset = isExpanded ? h * 0.03 : h * 0.15
                let bottomInset = isExpanded ? h * 0.08 : h * 0.05

                Group {

                    if isExpanded {

                        ExpandedNotchView(
                            selectedTab: $selectedTab,
                            clipboardViewModel: clipboardViewModel,
                            chatViewModel: chatViewModel,
                            mediaViewModel: mediaViewModel,
                            todoViewModel: todoViewModel,
                            apiKeyStore: apiKeyStore
                        )

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
                .clipped()
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
        .clipShape(NotchShape())
        .onHover { hovering in
            isHovered = hovering
        }
        .animation(
            .spring(response: 0.4, dampingFraction: 0.85),
            value: isExpanded
        )
    }
}
