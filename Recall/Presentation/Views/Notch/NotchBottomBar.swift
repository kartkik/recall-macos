//
//  NotchBottomBar.swift
//  Recall
//

import SwiftUI

struct NotchBottomBar: View {
    var selectedTab: RecallTab
    
    var body: some View {
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
