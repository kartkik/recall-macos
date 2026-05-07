//
//  PasteboardService.swift
//  Recall
//
//  Concrete pasteboard service wrapping NSPasteboard.
//

import AppKit
import Foundation

final class PasteboardService: PasteboardServiceProtocol, @unchecked Sendable {

    func currentTextContent() -> String? {
        NSPasteboard.general.string(forType: .string)
    }

    func currentImageData() -> Data? {
        // Try TIFF first (most common on macOS), then PNG
        if let data = NSPasteboard.general.data(forType: .tiff) {
            return data
        }
        if let data = NSPasteboard.general.data(forType: .png) {
            return data
        }
        return nil
    }

    func setTextContent(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    func setImageContent(_ data: Data) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setData(data, forType: .tiff)
    }

    func changeCount() -> Int {
        NSPasteboard.general.changeCount
    }
}
