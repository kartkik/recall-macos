//
//  ChatMessageBubble.swift
//  Recall
//
//  Chat message bubble with copy-to-clipboard support.
//

import SwiftUI

struct ChatMessageBubble: View {
    let message: ChatMessage
    let onCopy: () -> Void

    @State private var isHovered = false
    @State private var showCopied = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.role == .assistant {
                // AI avatar
                aiAvatar
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                // Message bubble
                Text(message.content.isEmpty ? "…" : message.content)
                    .font(.system(size: 12, weight: .regular, design: .default))
                    .foregroundStyle(.white.opacity(message.content.isEmpty ? 0.3 : 0.9))
                    .textSelection(.enabled)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(bubbleBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                // Timestamp + copy button row
                if !message.content.isEmpty {
                    HStack(spacing: 6) {
                        if message.role == .assistant && (isHovered || showCopied) {
                            Button(action: handleCopy) {
                                HStack(spacing: 3) {
                                    Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                                        .font(.system(size: 9))
                                    Text(showCopied ? "Copied!" : "Copy")
                                        .font(.system(size: 9, weight: .medium, design: .rounded))
                                }
                                .foregroundStyle(showCopied ? .green.opacity(0.8) : .white.opacity(0.4))
                            }
                            .buttonStyle(.plain)
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        }

                        Text(message.timestamp, style: .time)
                            .font(.system(size: 9, weight: .regular, design: .rounded))
                            .foregroundStyle(.white.opacity(0.25))
                    }
                }
            }
            .frame(maxWidth: 280, alignment: message.role == .user ? .trailing : .leading)

            if message.role == .user {
                // User avatar
                userAvatar
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
        .padding(.horizontal, 8)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    // MARK: - Subviews

    private var bubbleBackground: some ShapeStyle {
        if message.role == .user {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(
                            red: message.provider.accentColors.start.r,
                            green: message.provider.accentColors.start.g,
                            blue: message.provider.accentColors.start.b
                        ).opacity(0.35),
                        Color(
                            red: message.provider.accentColors.end.r,
                            green: message.provider.accentColors.end.g,
                            blue: message.provider.accentColors.end.b
                        ).opacity(0.25)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        return AnyShapeStyle(Color.white.opacity(0.08))
    }

    private var aiAvatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(
                                red: message.provider.accentColors.start.r,
                                green: message.provider.accentColors.start.g,
                                blue: message.provider.accentColors.start.b
                            ),
                            Color(
                                red: message.provider.accentColors.end.r,
                                green: message.provider.accentColors.end.g,
                                blue: message.provider.accentColors.end.b
                            )
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: message.provider.iconName)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: 22, height: 22)
    }

    private var userAvatar: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.15))

            Image(systemName: "person.fill")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(width: 22, height: 22)
    }

    // MARK: - Actions

    private func handleCopy() {
        onCopy()
        withAnimation { showCopied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { showCopied = false }
        }
    }
}
