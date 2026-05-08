//
//  OpenAIService.swift
//  Recall
//
//  ChatGPT (OpenAI) API service with streaming support.
//

import Foundation

final class OpenAIService: AIServiceProtocol, @unchecked Sendable {
    let provider: AIProvider = .chatGPT

    private let baseURL = "https://api.openai.com/v1/chat/completions"
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
            struct Choice: Decodable {
                struct Message: Decodable {
                    let content: String
                }
                let message: Message
            }
            let choices: [Choice]
        }

        let decoded = try JSONDecoder().decode(Response.self, from: data)
        guard let content = decoded.choices.first?.message.content else {
            throw AIServiceError.invalidResponse
        }
        return content
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
                        throw AIServiceError.httpError(
                            statusCode: httpResponse.statusCode,
                            message: "OpenAI API error"
                        )
                    }

                    for try await line in bytes.lines {
                        if line.hasPrefix("data: ") {
                            let jsonString = String(line.dropFirst(6))
                            if jsonString == "[DONE]" {
                                break
                            }
                            if let data = jsonString.data(using: .utf8),
                               let chunk = try? JSONDecoder().decode(StreamChunk.self, from: data),
                               let content = chunk.choices.first?.delta.content {
                                continuation.yield(content)
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
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": provider.modelName,
            "messages": messages.map { ["role": $0.role.rawValue, "content": $0.content] },
            "stream": stream,
            "max_tokens": 2048
        ]

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

// MARK: - Stream Chunk

private struct StreamChunk: Decodable {
    struct Choice: Decodable {
        struct Delta: Decodable {
            let content: String?
        }
        let delta: Delta
    }
    let choices: [Choice]
}
