//
//  ChatMessage.swift
//  Recall
//
//  Domain entity representing a chat message.
//

import Foundation

// MARK: - AI Provider

enum AIProvider: String, CaseIterable, Identifiable, Sendable {
    case chatGPT = "ChatGPT"
    case claude = "Claude"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var iconName: String {
        switch self {
        case .chatGPT: return "brain.head.profile"
        case .claude: return "sparkles"
        }
    }

    var modelName: String {
        switch self {
        case .chatGPT: return "gpt-4o"
        case .claude: return "claude-sonnet-4-20250514"
        }
    }

    var accentColors: (start: (r: Double, g: Double, b: Double), end: (r: Double, g: Double, b: Double)) {
        switch self {
        case .chatGPT:
            return (start: (0.29, 0.84, 0.63), end: (0.10, 0.65, 0.50))
        case .claude:
            return (start: (0.85, 0.55, 0.30), end: (0.78, 0.35, 0.20))
        }
    }
}

// MARK: - Message Role

enum ChatRole: String, Codable, Sendable {
    case user
    case assistant
    case system
}

// MARK: - Chat Message

struct ChatMessage: Identifiable, Equatable, Sendable {
    let id: UUID
    let role: ChatRole
    var content: String
    let timestamp: Date
    let provider: AIProvider

    init(
        id: UUID = UUID(),
        role: ChatRole,
        content: String,
        timestamp: Date = Date(),
        provider: AIProvider
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.provider = provider
    }
}
