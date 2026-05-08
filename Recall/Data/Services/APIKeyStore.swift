//
//  APIKeyStore.swift
//  Recall
//
//  Stores and retrieves API keys for AI providers.
//

import Foundation

// MARK: - Protocol

protocol APIKeyStoreProtocol: Sendable {
    func getKey(for provider: AIProvider) -> String?
    func setKey(_ key: String, for provider: AIProvider)
    func removeKey(for provider: AIProvider)
    func hasKey(for provider: AIProvider) -> Bool
}

// MARK: - UserDefaults Implementation

final class APIKeyStore: APIKeyStoreProtocol, @unchecked Sendable {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func getKey(for provider: AIProvider) -> String? {
        defaults.string(forKey: storageKey(for: provider))
    }

    func setKey(_ key: String, for provider: AIProvider) {
        defaults.set(key, forKey: storageKey(for: provider))
    }

    func removeKey(for provider: AIProvider) {
        defaults.removeObject(forKey: storageKey(for: provider))
    }

    func hasKey(for provider: AIProvider) -> Bool {
        guard let key = getKey(for: provider) else { return false }
        return !key.isEmpty
    }

    private func storageKey(for provider: AIProvider) -> String {
        "recall.apikey.\(provider.rawValue)"
    }
}
