//
//  GetClipboardHistoryUseCase.swift
//  Recall
//
//  Fetches clipboard history sorted by timestamp, pinned items first.
//

import Foundation

struct GetClipboardHistoryUseCase: Sendable {
    private let repository: ClipboardRepositoryProtocol

    init(repository: ClipboardRepositoryProtocol) {
        self.repository = repository
    }

    func execute() -> [ClipboardItem] {
        return repository.fetchAll()
    }
}
