//
//  AIServiceProtocol.swift
//  Recall
//
//  Protocol for AI chat services.
//

import Foundation

protocol AIServiceProtocol: Sendable {
    /// The provider this service handles.
    var provider: AIProvider { get }

    /// Sends a message and returns the full response.
    func sendMessage(
        messages: [(role: ChatRole, content: String)],
        apiKey: String
    ) async throws -> String

    /// Sends a message and streams the response token by token.
    func streamMessage(
        messages: [(role: ChatRole, content: String)],
        apiKey: String
    ) -> AsyncThrowingStream<String, Error>
}

// MARK: - AI Service Errors

enum AIServiceError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case httpError(statusCode: Int, message: String)
    case networkError(Error)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API key not configured. Add it in Settings."
        case .invalidResponse:
            return "Received an invalid response from the AI service."
        case .httpError(let code, let message):
            return "HTTP \(code): \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
}
