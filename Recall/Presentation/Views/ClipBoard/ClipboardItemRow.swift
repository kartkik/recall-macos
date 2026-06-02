//
//  ClipboardItemRow.swift
//  Recall
//
//  Individual clipboard item row with hover effects and actions.
//

import AppKit
import SwiftUI

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let isSelected: Bool
    var onSelect: () -> Void
    var onDelete: () -> Void
    var onCopied: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            // Content type icon / app icon
            appIconView

            // Content preview
            VStack(alignment: .leading, spacing: 3) {
                contentPreview

                HStack(spacing: 6) {
                    if let appName = item.sourceAppName {
                        Text(appName)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                    }

                    Text(item.relativeTime)
                        .font(.system(size: 10, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }

            Spacer()

            // Action buttons (visible on hover)
            if isHovered {
                actionButtons
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(isSelected ? accentGradient : clearGradient, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var appIconView: some View {
        Group {
            if item.contentType == .image {
                if let imageData = item.imageData, let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(width: 32, height: 32)
                }
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.purple.opacity(0.3), .blue.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Image(systemName: iconName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .frame(width: 32, height: 32)
            }
        }
    }

    @ViewBuilder
    private var contentPreview: some View {
        if item.contentType == .image {
            Text("Image")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
        } else {
            Text(item.preview)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(2)
                .truncationMode(.tail)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 4) {
            // Pin button
            Button(action: onCopied) {
                Image(systemName:  "doc.on.doc")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(item.isPinned ? .yellow : .white.opacity(0.5))
            }
            .buttonStyle(.plain)
            .frame(width: 24, height: 24)

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.red.opacity(0.7))
            }
            .buttonStyle(.plain)
            .frame(width: 24, height: 24)
        }
    }

    // MARK: - Helpers

    private var backgroundColor: Color {
        if isSelected {
            return .white.opacity(0.12)
        } else if isHovered {
            return .white.opacity(0.06)
        }
        return .clear
    }

    private var accentGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.39, green: 0.40, blue: 0.95).opacity(0.6),
                Color(red: 0.55, green: 0.36, blue: 0.96).opacity(0.6)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var clearGradient: LinearGradient {
        LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom)
    }

    private var iconName: String {
        if item.isPinned { return "pin.fill" }
        if item.content.hasPrefix("http") { return "link" }
        return "doc.text"
    }
}
