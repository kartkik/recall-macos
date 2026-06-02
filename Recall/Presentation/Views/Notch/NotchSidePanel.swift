//
//  NotchSidePanel.swift
//  Recall
//

import SwiftUI

struct NotchSidePanel: View {
    var clipboardViewModel: ClipboardViewModel
    
    var body: some View {
        VStack(spacing: 4) {
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

    private func infoCard(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 4,) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.2))

                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
            }
            .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
                    .tracking(0.8)

                Text(value)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
            }

        }
        .frame(width: 100, alignment: .leading)
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(.white.opacity(0.06), lineWidth: 0.5)
        )
    }
}
