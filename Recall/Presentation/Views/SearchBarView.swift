//
//  SearchBarView.swift
//  Recall
//
//  Search/filter bar with clear button.
//

import SwiftUI

struct SearchBarView: View {
    @Binding var searchText: String
    var onSearch: () -> Void
    var onClear: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))

            TextField("Search clipboard…", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(.white)
                .focused($isFocused)
                .onChange(of: searchText) { _, _ in
                    onSearch()
                }

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    onClear()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(.white.opacity(0.1), lineWidth: 0.5)
                )
        )
        .onAppear {
            isFocused = true
        }
    }
}
