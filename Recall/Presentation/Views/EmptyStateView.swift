//
//  EmptyStateView.swift
//  Recall
//
//  Shown when clipboard history is empty.
//

import SwiftUI

struct EmptyStateView: View {
    let isSearching: Bool

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: isSearching ? "magnifyingglass" : "clipboard")
                .font(.system(size: 32, weight: .light))
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
                .opacity(0.6)

            Text(isSearching ? "No results found" : "Nothing here yet")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))

            Text(isSearching ? "Try a different search term" : "Copy something to get started")
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
