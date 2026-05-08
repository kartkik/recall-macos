//
//  ChatViewModel.swift
//  Recall
//
//  ViewModel for AI chat functionality.
//

import AppKit
import Combine
import Foundation

@Observable
final class ChatViewModel {
    // MARK: - State

    var messages: [ChatMessage] = []
    var inputText: String = ""
    var isStreaming: Bool = false
    var selectedProvider: AIProvider = .chatGPT
    var errorMessage: String? = nil

    // MARK: - Dependencies

    private let sendMessageUseCase: SendChatMessageUseCase
    private let pasteboardService: PasteboardServiceProtocol
    private var streamTask: Task<Void, Never>?

    // MARK: - Init

    init(
        sendMessageUseCase: SendChatMessageUseCase,
        pasteboardService: PasteboardServiceProtocol
    ) {
        self.sendMessageUseCase = sendMessageUseCase
        self.pasteboardService = pasteboardService
    }

    // MARK: - Actions

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isStreaming else { return }

        errorMessage = nil

        // Add user message
        let userMessage = ChatMessage(
            role: .user,
            content: text,
            provider: selectedProvider
        )
        messages.append(userMessage)
        inputText = ""

        // Create placeholder assistant message for streaming
        let assistantMessage = ChatMessage(
            role: .assistant,
            content: "",
            provider: selectedProvider
        )
        messages.append(assistantMessage)
        let assistantIndex = messages.count - 1

        isStreaming = true

        // Build conversation history for API
        let conversationHistory = messages
            .filter { $0.role != .system }
            .dropLast() // Drop the empty assistant placeholder
            .map { (role: $0.role, content: $0.content) }

        // Stream response
        streamTask = Task { @MainActor in
            do {
                let stream = sendMessageUseCase.execute(
                    provider: selectedProvider,
                    messages: Array(conversationHistory)
                )

                for try await token in stream {
                    if Task.isCancelled { break }
                    messages[assistantIndex].content += token
                }
            } catch {
                if !Task.isCancelled {
                    errorMessage = error.localizedDescription
                    // Remove the empty assistant message if there was an error
                    if messages[assistantIndex].content.isEmpty {
                        messages.remove(at: assistantIndex)
                    }
                }
            }
            isStreaming = false
        }
    }

    func stopStreaming() {
        streamTask?.cancel()
        streamTask = nil
        isStreaming = false
    }

    func copyMessage(_ message: ChatMessage) {
        pasteboardService.setTextContent(message.content)
    }

    func clearChat() {
        stopStreaming()
        messages.removeAll()
        errorMessage = nil
    }

    func retryLastMessage() {
        guard let lastUserMessage = messages.last(where: { $0.role == .user }) else { return }
        // Remove everything after the last user message
        if let lastAssistantIndex = messages.lastIndex(where: { $0.role == .assistant }) {
            messages.remove(at: lastAssistantIndex)
        }
        errorMessage = nil
        inputText = lastUserMessage.content
        messages.removeLast() // Remove the user message too since sendMessage will re-add it
        sendMessage()
    }
}
