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
    let mediaRemoteService: MediaRemoteService

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
    
    
    // MARK: - TodoUseCase
    
    let eventKitService: EventKitService
    let eventKitRepository: EventKitRepositoryProtocol
    let requestEventKitAccessUseCase: RequestEventKitAccessUseCase
    let fetchReminderEventsUseCase: FetchReminderEventsUseCase
    let createReminderEventUseCase: CreateReminderEventUseCase
    let toggleReminderCompletionUseCase: ToggleReminderCompletionUseCase
    let deleteReminderEventUseCase: DeleteReminderEventUseCase

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
        mediaRemoteService = MediaRemoteService()

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
        
        
        
        eventKitService = EventKitService()
        eventKitRepository = EventKitRepository(service: eventKitService)
        requestEventKitAccessUseCase = RequestEventKitAccessUseCase(repository: eventKitRepository)
        fetchReminderEventsUseCase = FetchReminderEventsUseCase(repository: eventKitRepository)
        createReminderEventUseCase = CreateReminderEventUseCase(repository: eventKitRepository)
        toggleReminderCompletionUseCase = ToggleReminderCompletionUseCase(repository: eventKitRepository)
        deleteReminderEventUseCase = DeleteReminderEventUseCase(repository: eventKitRepository)
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

    func makeMediaPlayerViewModel() -> MediaPlayerViewModel {
        MediaPlayerViewModel(mediaService: mediaRemoteService)
    }
    
    
    func makeTodoViewModel() -> TodoViewModel {
        TodoViewModel(
            requestAccessUseCase: requestEventKitAccessUseCase,
            fetchReminderEventsUseCase: fetchReminderEventsUseCase,
            createReminderEventUseCase: createReminderEventUseCase,
            toggleReminderCompletionUseCase: toggleReminderCompletionUseCase,
            deleteReminderEventUseCase: deleteReminderEventUseCase,
            repository: eventKitRepository
        )
    }
}
