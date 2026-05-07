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

    // MARK: - Repository

    let clipboardRepository: ClipboardRepositoryProtocol

    // MARK: - Use Cases

    let getClipboardHistoryUseCase: GetClipboardHistoryUseCase
    let saveClipboardItemUseCase: SaveClipboardItemUseCase
    let deleteClipboardItemUseCase: DeleteClipboardItemUseCase
    let searchClipboardUseCase: SearchClipboardUseCase
    let pasteClipboardItemUseCase: PasteClipboardItemUseCase

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

        // Repository
        clipboardRepository = ClipboardRepository(modelContext: modelContext)

        // Use Cases
        getClipboardHistoryUseCase = GetClipboardHistoryUseCase(repository: clipboardRepository)
        saveClipboardItemUseCase = SaveClipboardItemUseCase(repository: clipboardRepository)
        deleteClipboardItemUseCase = DeleteClipboardItemUseCase(repository: clipboardRepository)
        searchClipboardUseCase = SearchClipboardUseCase(repository: clipboardRepository)
        pasteClipboardItemUseCase = PasteClipboardItemUseCase(pasteboardService: pasteboardService)
    }

    // MARK: - Factory

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
}
