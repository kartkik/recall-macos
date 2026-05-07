//
//  PasteClipboardItemUseCase.swift
//  Recall
//
//  Copies a clipboard item back to the system pasteboard.
//

import Foundation

struct PasteClipboardItemUseCase: Sendable {
    private let pasteboardService: PasteboardServiceProtocol

    init(pasteboardService: PasteboardServiceProtocol) {
        self.pasteboardService = pasteboardService
    }

    func execute(_ item: ClipboardItem) {
        switch item.contentType {
        case .text:
            pasteboardService.setTextContent(item.content)
        case .image:
            if let imageData = item.imageData {
                pasteboardService.setImageContent(imageData)
            }
        }
    }
}
