//
//  ClipboardView.swift
//  Recall
//

import SwiftUI

struct ClipboardView: View {
    var viewModel: ClipboardViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            SearchBarView(
                searchText: Binding(
                    get: { viewModel.searchQuery },
                    set: { viewModel.searchQuery = $0 }
                ),
                onSearch: { viewModel.search() },
                onClear: { viewModel.loadItems() }
            )
            .padding(.horizontal, 6)
            .padding(.top, 6)

            if viewModel.clipboardItems.isEmpty {
                EmptyStateView(isSearching: !viewModel.searchQuery.isEmpty)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ClipboardListView(
                    items: viewModel.clipboardItems,
                    selectedIndex: viewModel.selectedIndex,
                    onSelect: { viewModel.selectItem($0) },
                    onDelete: { viewModel.deleteItem($0) },
                    onTogglePin: { viewModel.togglePin($0) }
                )
            }
        }
    }
}
