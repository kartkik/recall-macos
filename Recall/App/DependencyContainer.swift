//
//  DependencyContainer.swift
//  Recall
//
//  Dependency injection container — single source of truth for the object graph.
//

import Foundation
import SwiftData

final class DependencyContainer {
    // MARK: - Core

    let modelContainer: ModelContainer
    let modelContext: ModelContext

    // MARK: - Services

    let pasteboardService: PasteboardServiceProtocol
    let clipboardMonitor: ClipboardMonitor
    let apiKeyStore: APIKeyStoreProtocol

    // MARK: - AI Services

    private let openAIService: OpenAIService
    private let anthropicService: AnthropicService

    // MARK: - Repository

    let clipboardRepository: ClipboardRepositoryProtocol

    // MARK: - Clipboard Use Cases

    let getClipboardHistoryUseCase: GetClipboardHistoryUseCase
    let saveClipboardItemUseCase: SaveClipboardItemUseCase
    let deleteClipboardItemUseCase: DeleteClipboardItemUseCase
    let searchClipboardUseCase: SearchClipboardUseCase
    let pasteClipboardItemUseCase: PasteClipboardItemUseCase

    // MARK: - Chat Use Cases

    let sendChatMessageUseCase: SendChatMessageUseCase

    // MARK: - Init

    init() {
        // SwiftData
        let schema = Schema([ClipboardItemModel.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("[Recall] Failed to create ModelContainer: \(error)")
        }
        modelContext = ModelContext(modelContainer)

        // Services
        pasteboardService = PasteboardService()
        clipboardMonitor = ClipboardMonitor(pasteboardService: pasteboardService)
        apiKeyStore = APIKeyStore()

        // AI Services
        openAIService = OpenAIService()
        anthropicService = AnthropicService()

        // Repository
        clipboardRepository = ClipboardRepository(modelContext: modelContext)

        // Clipboard Use Cases
        getClipboardHistoryUseCase = GetClipboardHistoryUseCase(repository: clipboardRepository)
        saveClipboardItemUseCase = SaveClipboardItemUseCase(repository: clipboardRepository)
        deleteClipboardItemUseCase = DeleteClipboardItemUseCase(repository: clipboardRepository)
        searchClipboardUseCase = SearchClipboardUseCase(repository: clipboardRepository)
        pasteClipboardItemUseCase = PasteClipboardItemUseCase(pasteboardService: pasteboardService)

        // Chat Use Cases
        sendChatMessageUseCase = SendChatMessageUseCase(
            services: [
                .chatGPT: openAIService,
                .claude: anthropicService
            ],
            apiKeyStore: apiKeyStore
        )
    }

    // MARK: - Factories

    func makeClipboardViewModel() -> ClipboardViewModel {
        ClipboardViewModel(
            getHistoryUseCase: getClipboardHistoryUseCase,
            saveItemUseCase: saveClipboardItemUseCase,
            deleteItemUseCase: deleteClipboardItemUseCase,
            searchUseCase: searchClipboardUseCase,
            pasteItemUseCase: pasteClipboardItemUseCase,
            repository: clipboardRepository,
            clipboardMonitor: clipboardMonitor
        )
    }

    func makeChatViewModel() -> ChatViewModel {
        ChatViewModel(
            sendMessageUseCase: sendChatMessageUseCase,
            pasteboardService: pasteboardService
        )
    }
}
