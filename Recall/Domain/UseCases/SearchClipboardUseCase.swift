//
//  SearchClipboardUseCase.swift
//  Recall
//
//  Searches clipboard items by text content.
//

import Foundation

struct SearchClipboardUseCase: Sendable {
    private let repository: ClipboardRepositoryProtocol

    init(repository: ClipboardRepositoryProtocol) {
        self.repository = repository
    }

    func execute(query: String) -> [ClipboardItem] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return repository.fetchAll()
        }
        return repository.search(query: query)
    }
}
