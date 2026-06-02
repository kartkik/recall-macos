//
//  TodoViewModel.swift
//  Recall
//
//  Created by twixx  on 01/06/26.
//

import Foundation
import Combine
import SwiftUI

@Observable
final class TodoViewModel {
    // MARK: - State
    var eventsAndReminders: [ReminderEvent] = []
    var selectedDate: Date = Date()
    var hasAccess: Bool = false
    var isLoading: Bool = false
    var errorMessage: String? = nil

    // MARK: - Dependencies
    private let requestAccessUseCase: RequestEventKitAccessUseCase
    private let fetchReminderEventsUseCase: FetchReminderEventsUseCase
    private let createReminderEventUseCase: CreateReminderEventUseCase
    private let toggleReminderCompletionUseCase: ToggleReminderCompletionUseCase
    private let deleteReminderEventUseCase: DeleteReminderEventUseCase
    private let repository: EventKitRepositoryProtocol

    init(
        requestAccessUseCase: RequestEventKitAccessUseCase,
        fetchReminderEventsUseCase: FetchReminderEventsUseCase,
        createReminderEventUseCase: CreateReminderEventUseCase,
        toggleReminderCompletionUseCase: ToggleReminderCompletionUseCase,
        deleteReminderEventUseCase: DeleteReminderEventUseCase,
        repository: EventKitRepositoryProtocol
    ) {
        self.requestAccessUseCase = requestAccessUseCase
        self.fetchReminderEventsUseCase = fetchReminderEventsUseCase
        self.createReminderEventUseCase = createReminderEventUseCase
        self.toggleReminderCompletionUseCase = toggleReminderCompletionUseCase
        self.deleteReminderEventUseCase = deleteReminderEventUseCase
        self.repository = repository
        
        Task { @MainActor in
            await checkAccess()
        }
    }

    func checkAccess() async {
        self.hasAccess = await repository.hasAccess()
    }

    func requestAccess() {
        Task { @MainActor in
            do {
                let granted = try await requestAccessUseCase.execute()
                self.hasAccess = granted
                if granted {
                    loadItems()
                }
            } catch {
                self.errorMessage = "Failed to request access: \(error.localizedDescription)"
            }
        }
    }

    func loadItems() {
        guard hasAccess else { return }
        isLoading = true
        errorMessage = nil
        
        Task { @MainActor in
            do {
                self.eventsAndReminders = try await fetchReminderEventsUseCase.execute(date: selectedDate)
            } catch {
                self.errorMessage = "Failed to load events: \(error.localizedDescription)"
            }
            self.isLoading = false
        }
    }

    func addEventOrReminder(title: String, timeRange: String, colorName: String, isReminder: Bool) {
        guard hasAccess else { return }
        isLoading = true
        
        Task { @MainActor in
            do {
                try await createReminderEventUseCase.execute(
                    title: title,
                    date: selectedDate,
                    timeRange: timeRange,
                    colorName: colorName,
                    isReminder: isReminder
                )
                loadItems()
            } catch {
                self.errorMessage = "Failed to create item: \(error.localizedDescription)"
            }
            self.isLoading = false
        }
    }

    func toggleReminderCompletion(_ item: ReminderEvent) {
        guard hasAccess, item.isReminder else { return }
        
        Task { @MainActor in
            do {
                try await toggleReminderCompletionUseCase.execute(id: item.id)
                loadItems()
            } catch {
                self.errorMessage = "Failed to toggle item: \(error.localizedDescription)"
            }
        }
    }

    func deleteItem(_ item: ReminderEvent) {
        guard hasAccess else { return }
        
        Task { @MainActor in
            do {
                try await deleteReminderEventUseCase.execute(id: item.id, isReminder: item.isReminder)
                loadItems()
            } catch {
                self.errorMessage = "Failed to delete item: \(error.localizedDescription)"
            }
        }
    }
}
