//
//  RecallTab.swift
//  Recall
//

import SwiftUI

enum RecallTab: String, CaseIterable {
    case clipboard = "Clipboard"
    case chat = "AI Chat"

    var icon: String {
        switch self {
        case .clipboard: return "clipboard"
        case .chat: return "bubble.left.and.bubble.right.fill"
        }
    }
}
