//
//  AnthropicService.swift
//  Recall
//
//  Claude (Anthropic) API service with streaming support.
//

import Foundation

final class AnthropicService: AIServiceProtocol, @unchecked Sendable {
    let provider: AIProvider = .claude

    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let apiVersion = "2023-06-01"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Non-streaming

    func sendMessage(
        messages: [(role: ChatRole, content: String)],
        apiKey: String
    ) async throws -> String {
        let request = try buildRequest(messages: messages, apiKey: apiKey, stream: false)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)

        struct Response: Decodable {
            struct Content: Decodable {
                let text: String
            }
            let content: [Content]
        }

        let decoded = try JSONDecoder().decode(Response.self, from: data)
        guard let text = decoded.content.first?.text else {
            throw AIServiceError.invalidResponse
        }
        return text
    }

    // MARK: - Streaming

    func streamMessage(
        messages: [(role: ChatRole, content: String)],
        apiKey: String
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let request = try buildRequest(messages: messages, apiKey: apiKey, stream: true)
                    let (bytes, response) = try await session.bytes(for: request)

                    if let httpResponse = response as? HTTPURLResponse,
                       !(200...299).contains(httpResponse.statusCode) {
                        // Try to read error body
                        var errorBody = ""
                        for try await line in bytes.lines {
                            errorBody += line
                        }
                        throw AIServiceError.httpError(
                            statusCode: httpResponse.statusCode,
                            message: errorBody.isEmpty ? "Anthropic API error" : errorBody
                        )
                    }

                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let jsonString = String(line.dropFirst(6))
                            if let data = jsonString.data(using: .utf8) {
                                if let event = try? JSONDecoder().decode(StreamEvent.self, from: data) {
                                    switch event.type {
                                    case "content_block_delta":
                                        if let text = event.delta?.text {
                                            continuation.yield(text)
                                        }
                                    case "message_stop":
                                        break
                                    default:
                                        break
                                    }
                                }
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Private

    private func buildRequest(
        messages: [(role: ChatRole, content: String)],
        apiKey: String,
        stream: Bool
    ) throws -> URLRequest {
        guard let url = URL(string: baseURL) else {
            throw AIServiceError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.addValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // Anthropic doesn't support "system" role in messages array — extract it
        let systemMessage = messages.first { $0.role == .system }?.content
        let conversationMessages = messages
            .filter { $0.role != .system }
            .map { ["role": $0.role.rawValue, "content": $0.content] }

        var body: [String: Any] = [
            "model": provider.modelName,
            "messages": conversationMessages,
            "max_tokens": 2048,
            "stream": stream
        ]

        if let system = systemMessage {
            body["system"] = system
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIServiceError.httpError(statusCode: httpResponse.statusCode, message: message)
        }
    }
}

// MARK: - Stream Event

private struct StreamEvent: Decodable {
    let type: String
    struct Delta: Decodable {
        let text: String?
    }
    let delta: Delta?
}
