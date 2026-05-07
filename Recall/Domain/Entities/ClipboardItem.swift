//
//  ClipboardItem.swift
//  Recall
//
//  Domain entity representing a clipboard item.
//

import Foundation

// MARK: - Content Type

enum ClipboardContentType: String, Codable, Sendable {
    case text
    case image
}

// MARK: - Clipboard Item Entity

struct ClipboardItem: Identifiable, Equatable, Sendable {
    let id: UUID
    let content: String
    let imageData: Data?
    let contentType: ClipboardContentType
    let timestamp: Date
    var isPinned: Bool
    let sourceAppName: String?
    let sourceAppBundleID: String?

    init(
        id: UUID = UUID(),
        content: String,
        imageData: Data? = nil,
        contentType: ClipboardContentType = .text,
        timestamp: Date = Date(),
        isPinned: Bool = false,
        sourceAppName: String? = nil,
        sourceAppBundleID: String? = nil
    ) {
        self.id = id
        self.content = content
        self.imageData = imageData
        self.contentType = contentType
        self.timestamp = timestamp
        self.isPinned = isPinned
        self.sourceAppName = sourceAppName
        self.sourceAppBundleID = sourceAppBundleID
    }
}

// MARK: - Convenience

extension ClipboardItem {
    /// Returns a truncated preview of the content for display.
    var preview: String {
        if contentType == .image {
            return "📷 Image"
        }
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > 120 {
            return String(trimmed.prefix(120)) + "…"
        }
        return trimmed
    }

    /// Relative time description (e.g., "2m ago", "1h ago").
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
