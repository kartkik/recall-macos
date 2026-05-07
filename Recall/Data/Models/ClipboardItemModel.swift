//
//  ClipboardItemModel.swift
//  Recall
//
//  SwiftData model for persisting clipboard items.
//

import Foundation
import SwiftData

@Model
final class ClipboardItemModel {
    var id: UUID
    var content: String
    @Attribute(.externalStorage) var imageData: Data?
    var contentTypeRaw: String
    var timestamp: Date
    var isPinned: Bool
    var sourceAppName: String?
    var sourceAppBundleID: String?

    init(
        id: UUID = UUID(),
        content: String,
        imageData: Data? = nil,
        contentTypeRaw: String = ClipboardContentType.text.rawValue,
        timestamp: Date = Date(),
        isPinned: Bool = false,
        sourceAppName: String? = nil,
        sourceAppBundleID: String? = nil
    ) {
        self.id = id
        self.content = content
        self.imageData = imageData
        self.contentTypeRaw = contentTypeRaw
        self.timestamp = timestamp
        self.isPinned = isPinned
        self.sourceAppName = sourceAppName
        self.sourceAppBundleID = sourceAppBundleID
    }

    var contentType: ClipboardContentType {
        get { ClipboardContentType(rawValue: contentTypeRaw) ?? .text }
        set { contentTypeRaw = newValue.rawValue }
    }
}
