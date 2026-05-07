//
//  PasteboardServiceProtocol.swift
//  Recall
//
//  Protocol for system pasteboard interactions.
//

import Foundation

protocol PasteboardServiceProtocol: Sendable {
    /// Returns the current text content from the system pasteboard.
    func currentTextContent() -> String?

    /// Returns the current image data from the system pasteboard.
    func currentImageData() -> Data?

    /// Sets text content on the system pasteboard.
    func setTextContent(_ text: String)

    /// Sets image data on the system pasteboard.
    func setImageContent(_ data: Data)

    /// Returns the current change count of the pasteboard.
    func changeCount() -> Int
}
