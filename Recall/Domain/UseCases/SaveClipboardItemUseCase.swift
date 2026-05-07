//
//  SaveClipboardItemUseCase.swift
//  Recall
//
//  Saves a new clipboard item and enforces history limit.
//

import Foundation

struct SaveClipboardItemUseCase: Sendable {
    private let repository: ClipboardRepositoryProtocol
    private let historyLimit: Int

    init(repository: ClipboardRepositoryProtocol, historyLimit: Int = 50) {
        self.repository = repository
        self.historyLimit = historyLimit
    }

    func execute(_ item: ClipboardItem) {
        repository.save(item)
        repository.trimToLimit(historyLimit)
    }
}
