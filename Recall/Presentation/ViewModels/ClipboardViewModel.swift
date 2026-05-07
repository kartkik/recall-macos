//
//  ClipboardViewModel.swift
//  Recall
//
//  Main ViewModel coordinating clipboard operations.
//

import Combine
import Foundation
import SwiftUI

@Observable
final class ClipboardViewModel {
    // MARK: - State

    var clipboardItems: [ClipboardItem] = []
    var searchQuery: String = ""
    var isExpanded: Bool = false
    var selectedIndex: Int? = nil

    // MARK: - Dependencies

    private let getHistoryUseCase: GetClipboardHistoryUseCase
    private let saveItemUseCase: SaveClipboardItemUseCase
    private let deleteItemUseCase: DeleteClipboardItemUseCase
    private let searchUseCase: SearchClipboardUseCase
    private let pasteItemUseCase: PasteClipboardItemUseCase
    private let repository: ClipboardRepositoryProtocol
    private let clipboardMonitor: ClipboardMonitor
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Callbacks

    var onPanelShouldHide: (() -> Void)?

    // MARK: - Init

    init(
        getHistoryUseCase: GetClipboardHistoryUseCase,
        saveItemUseCase: SaveClipboardItemUseCase,
        deleteItemUseCase: DeleteClipboardItemUseCase,
        searchUseCase: SearchClipboardUseCase,
        pasteItemUseCase: PasteClipboardItemUseCase,
        repository: ClipboardRepositoryProtocol,
        clipboardMonitor: ClipboardMonitor
    ) {
        self.getHistoryUseCase = getHistoryUseCase
        self.saveItemUseCase = saveItemUseCase
        self.deleteItemUseCase = deleteItemUseCase
        self.searchUseCase = searchUseCase
        self.pasteItemUseCase = pasteItemUseCase
        self.repository = repository
        self.clipboardMonitor = clipboardMonitor

        setupMonitor()
        loadItems()
    }

    // MARK: - Public Actions

    func loadItems() {
        if searchQuery.isEmpty {
            clipboardItems = getHistoryUseCase.execute()
        } else {
            clipboardItems = searchUseCase.execute(query: searchQuery)
        }
    }

    func search() {
        clipboardItems = searchUseCase.execute(query: searchQuery)
        selectedIndex = clipboardItems.isEmpty ? nil : 0
    }

    func selectItem(_ item: ClipboardItem) {
        // Set ignore flag so the monitor doesn't re-capture this
        clipboardMonitor.ignoreNextChange = true
        pasteItemUseCase.execute(item)
        onPanelShouldHide?()
    }

    func deleteItem(_ item: ClipboardItem) {
        deleteItemUseCase.execute(item)
        loadItems()
    }

    func togglePin(_ item: ClipboardItem) {
        repository.togglePin(item)
        loadItems()
    }

    func clearAll() {
        repository.clearAll()
        loadItems()
    }

    // MARK: - Keyboard Navigation

    func moveSelectionUp() {
        guard !clipboardItems.isEmpty else { return }
        if let current = selectedIndex {
            selectedIndex = max(0, current - 1)
        } else {
            selectedIndex = 0
        }
    }

    func moveSelectionDown() {
        guard !clipboardItems.isEmpty else { return }
        if let current = selectedIndex {
            selectedIndex = min(clipboardItems.count - 1, current + 1)
        } else {
            selectedIndex = 0
        }
    }

    func confirmSelection() {
        guard let index = selectedIndex, index < clipboardItems.count else { return }
        selectItem(clipboardItems[index])
    }

    // MARK: - Private

    private func setupMonitor() {
        clipboardMonitor.onNewItem
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newItem in
                guard let self else { return }
                self.saveItemUseCase.execute(newItem)
                self.loadItems()
            }
            .store(in: &cancellables)
    }
}
