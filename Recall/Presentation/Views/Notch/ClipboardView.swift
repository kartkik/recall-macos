//
//  ClipboardView.swift
//  Recall
//

import SwiftUI

struct ClipboardView: View {
    var viewModel: ClipboardViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            

            if viewModel.clipboardItems.isEmpty {
                EmptyStateView(isSearching: !viewModel.searchQuery.isEmpty)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                
                
                SearchBarView(
                    searchText: Binding(
                        get: { viewModel.searchQuery },
                        set: { viewModel.searchQuery = $0 }
                    ),
                    onSearch: { viewModel.search() },
                    onClear: { viewModel.loadItems() }
                ).padding(6)
             
                ClipboardListView(
                    items: viewModel.clipboardItems,
                    selectedIndex: viewModel.selectedIndex,
                    onSelect: { viewModel.selectItem($0) },
                    onDelete: { viewModel.deleteItem($0) },
                    onTogglePin: { viewModel.copyItem($0) }
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
