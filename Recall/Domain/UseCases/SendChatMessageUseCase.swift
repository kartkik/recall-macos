//
//  SendChatMessageUseCase.swift
//  Recall
//
//  Use case for sending messages to AI and streaming responses.
//

import Foundation

struct SendChatMessageUseCase: Sendable {
    private let services: [AIProvider: AIServiceProtocol]
    private let apiKeyStore: APIKeyStoreProtocol

    init(services: [AIProvider: AIServiceProtocol], apiKeyStore: APIKeyStoreProtocol) {
        self.services = services
        self.apiKeyStore = apiKeyStore
    }

    /// Streams a response from the selected AI provider.
    func execute(
        provider: AIProvider,
        messages: [(role: ChatRole, content: String)]
    ) -> AsyncThrowingStream<String, Error> {
        guard let service = services[provider] else {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: AIServiceError.invalidResponse)
            }
        }

        guard let apiKey = apiKeyStore.getKey(for: provider), !apiKey.isEmpty else {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: AIServiceError.missingAPIKey)
            }
        }

        return service.streamMessage(messages: messages, apiKey: apiKey)
    }
}
