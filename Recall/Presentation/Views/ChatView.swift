//
//  ChatView.swift
//  Recall
//

import SwiftUI

struct ChatView: View {
    var viewModel: ChatViewModel
    var apiKeyStore: APIKeyStoreProtocol

    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {

            // Header
            chatHeader

            Divider()
                .overlay(.white.opacity(0.08))

            // Content
            if viewModel.messages.isEmpty {
                chatEmptyState
                    .frame(maxHeight: .infinity)
            } else {
                messageList
            }

            // Error
            if let error = viewModel.errorMessage {
                errorBanner(error)
            }

            Divider()
                .overlay(.white.opacity(0.08))

            // Input
            chatInputBar
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150) // FIXED HEIGHT
        .background(Color.black.opacity(0.001))
        .clipped()
        .sheet(isPresented: $showSettings) {
            APIKeySettingsView(apiKeyStore: apiKeyStore)
        }
    }

    // MARK: - Header

    private var chatHeader: some View {
        HStack(spacing: 6) {

            ForEach(AIProvider.allCases) { provider in
                providerButton(provider)
            }

            Spacer()

            // Clear
            if !viewModel.messages.isEmpty {
                Button(action: {
                    viewModel.clearChat()
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .buttonStyle(.plain)
            }

            // Settings
            Button(action: {
                showSettings = true
            }) {
                Image(systemName: "key.fill")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
    }

    @ViewBuilder
    private func providerButton(_ provider: AIProvider) -> some View {

        let isSelected = viewModel.selectedProvider == provider
        let hasKey = apiKeyStore.hasKey(for: provider)

        Button(action: {
            viewModel.selectedProvider = provider
        }) {
            HStack(spacing: 3) {

                Image(systemName: provider.iconName)
                    .font(.system(size: 9, weight: .semibold))

                Text(provider.displayName)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))

                if !hasKey {
                    Circle()
                        .fill(.red.opacity(0.7))
                        .frame(width: 4, height: 4)
                }
            }
            .foregroundStyle(
                isSelected
                ? .white
                : .white.opacity(0.45)
            )
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(
                        isSelected
                        ? providerColor(provider).opacity(0.25)
                        : .white.opacity(0.04)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(
                        isSelected
                        ? providerColor(provider).opacity(0.45)
                        : .clear,
                        lineWidth: 0.5
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Messages

    private var messageList: some View {
        ScrollViewReader { proxy in

            ScrollView(.vertical, showsIndicators: false) {

                LazyVStack(spacing: 4) {

                    ForEach(viewModel.messages) { message in

                        ChatMessageBubble(
                            message: message,
                            onCopy: {
                                viewModel.copyMessage(message)
                            }
                        )
                        .id(message.id)
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxHeight: 60) // IMPORTANT FIX
            .onChange(of: viewModel.messages.count) { _, _ in

                if let lastMessage = viewModel.messages.last {

                    withAnimation(.easeOut(duration: 0.15)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.messages.last?.content) { _, _ in

                if let lastMessage = viewModel.messages.last {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Empty State

    private var chatEmptyState: some View {

        VStack(spacing: 5) {

            Image(systemName: viewModel.selectedProvider.iconName)
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            providerColor(viewModel.selectedProvider),
                            providerColor(viewModel.selectedProvider).opacity(0.6)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .opacity(0.7)

            Text("Chat with \(viewModel.selectedProvider.displayName)")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.65))

            if !apiKeyStore.hasKey(for: viewModel.selectedProvider) {

                Text("Add API key in settings")
                    .font(.system(size: 9, weight: .regular, design: .rounded))
                    .foregroundStyle(.orange.opacity(0.65))

            } else {

                Text("Ask anything")
                    .font(.system(size: 9, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }

    // MARK: - Error Banner

    @ViewBuilder
    private func errorBanner(_ message: String) -> some View {

        HStack(spacing: 4) {

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 8))
                .foregroundStyle(.orange)

            Text(message)
                .font(.system(size: 8, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(1)

            Spacer()

            Button("Retry") {
                viewModel.retryLastMessage()
            }
            .font(.system(size: 8, weight: .semibold, design: .rounded))
            .foregroundStyle(.orange)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.orange.opacity(0.08))
    }

    // MARK: - Input

    private var chatInputBar: some View {

        HStack(spacing: 6) {

            TextField(
                "Ask something…",
                text: Binding(
                    get: { viewModel.inputText },
                    set: { viewModel.inputText = $0 }
                )
            )
            .textFieldStyle(.plain)
            .font(.system(size: 10, weight: .regular, design: .rounded))
            .foregroundStyle(.white)
            .onSubmit {
                viewModel.sendMessage()
            }

            if viewModel.isStreaming {

                Button(action: {
                    viewModel.stopStreaming()
                }) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.red.opacity(0.7))
                }
                .buttonStyle(.plain)

            } else {

                Button(action: {
                    viewModel.sendMessage()
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(
                            viewModel.inputText
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                                .isEmpty
                            ? .white.opacity(0.2)
                            : providerColor(viewModel.selectedProvider)
                        )
                }
                .buttonStyle(.plain)
                .disabled(
                    viewModel.inputText
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .isEmpty
                )
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
    }

    // MARK: - Helpers

    private func providerColor(_ provider: AIProvider) -> Color {

        Color(
            red: provider.accentColors.start.r,
            green: provider.accentColors.start.g,
            blue: provider.accentColors.start.b
        )
    }
}
// MARK: - API Key Settings View

struct APIKeySettingsView: View {
    let apiKeyStore: APIKeyStoreProtocol
    @Environment(\.dismiss) private var dismiss

    @State private var openAIKey: String = ""
    @State private var anthropicKey: String = ""

    var body: some View {
        VStack(spacing: 16) {
            // Title
            HStack {
                Text("API Keys")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .buttonStyle(.plain)
            }

            // OpenAI
            apiKeyField(
                title: "OpenAI (ChatGPT)",
                key: $openAIKey,
                placeholder: "sk-...",
                provider: .chatGPT
            )

            // Anthropic
            apiKeyField(
                title: "Anthropic (Claude)",
                key: $anthropicKey,
                placeholder: "sk-ant-...",
                provider: .claude
            )

            Spacer()

            // Save button
            Button(action: saveKeys) {
                Text("Save Keys")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.39, green: 0.40, blue: 0.95),
                                        Color(red: 0.55, green: 0.36, blue: 0.96)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(width: 320, height: 280)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            openAIKey = apiKeyStore.getKey(for: .chatGPT) ?? ""
            anthropicKey = apiKeyStore.getKey(for: .claude) ?? ""
        }
    }

    @ViewBuilder
    private func apiKeyField(
        title: String,
        key: Binding<String>,
        placeholder: String,
        provider: AIProvider
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))

                if apiKeyStore.hasKey(for: provider) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.green.opacity(0.7))
                }
            }

            SecureField(placeholder, text: key)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 11, design: .monospaced))
        }
    }

    private func saveKeys() {
        if !openAIKey.isEmpty {
            apiKeyStore.setKey(openAIKey, for: .chatGPT)
        } else {
            apiKeyStore.removeKey(for: .chatGPT)
        }

        if !anthropicKey.isEmpty {
            apiKeyStore.setKey(anthropicKey, for: .claude)
        } else {
            apiKeyStore.removeKey(for: .claude)
        }

        dismiss()
    }
}
