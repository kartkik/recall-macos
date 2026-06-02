//
//  ClipboardRepositoryProtocol.swift
//  Recall
//
//  Protocol defining clipboard data operations.
//

import Foundation

protocol ClipboardRepositoryProtocol: Sendable {
    /// Fetches all clipboard items, sorted by timestamp descending, pinned first.
    func fetchAll() -> [ClipboardItem]

    /// Saves a new clipboard item to the store.
    func save(_ item: ClipboardItem)

    /// Deletes a specific clipboard item.
    func delete(_ item: ClipboardItem)

    /// Searches clipboard items by text content (case-insensitive).
    func search(query: String) -> [ClipboardItem]

    /// Toggles the pinned state of an item.
    func togglePin(_ item: ClipboardItem)
    
    func copyItem(_ item: ClipboardItem)


    /// Clears all clipboard history (excluding pinned items).
    func clearAll()

    
    /// Returns the total count of items in the store.
    func count() -> Int

    /// Deletes the oldest unpinned items to maintain the history limit.
    func trimToLimit(_ limit: Int)
}
