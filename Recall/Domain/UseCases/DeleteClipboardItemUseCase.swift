//
//  DeleteClipboardItemUseCase.swift
//  Recall
//
//  Deletes a single clipboard item from history.
//

import Foundation

struct DeleteClipboardItemUseCase: Sendable {
    private let repository: ClipboardRepositoryProtocol

    init(repository: ClipboardRepositoryProtocol) {
        self.repository = repository
    }

    func execute(_ item: ClipboardItem) {
        repository.delete(item)
    }
}
