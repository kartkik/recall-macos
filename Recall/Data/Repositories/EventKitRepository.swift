//
//  EventKitRepository.swift
//  Recall
//
//  Created by twixx  on 01/06/26.
//


import Foundation
import EventKit
import SwiftUI

final class EventKitRepository: EventKitRepositoryProtocol {
    func fetchEventAndReminders(for date: Date) async throws -> [ReminderEvent] {
        let events = service.fetchEvents(for: date)
        let reminders = await service.fetchReminders(for: date)
        
        let mappedEvents = events.map { event in
            ReminderEvent(
                id: event.calendarItemIdentifier,
                title: event.title ?? "Untitled Event",
                isCompleted: false,
                startDate: event.startDate,
                endDate: event.endDate,
                isReminder: false,
                colorName: colorNameForCalendar(event.calendar)
            )
        }
        
        let mappedReminders = reminders.map { reminder in
            ReminderEvent(
                id: reminder.calendarItemIdentifier,
                title: reminder.title ?? "Untitled Task",
                isCompleted: reminder.isCompleted,
                startDate: reminder.startDateComponents?.date,
                endDate: reminder.dueDateComponents?.date,
                isReminder: true,
                colorName: colorNameForCalendar(reminder.calendar)
            )
        }
        
        return (mappedEvents + mappedReminders).sorted { a, b in
            let dateA = a.startDate ?? .distantFuture
            let dateB = b.startDate ?? .distantFuture
            return dateA < dateB
        }
    }
    
   
    
    private let service: EventKitService

    init(service: EventKitService) {
        self.service = service
    }

    func requestAccess() async throws -> Bool {
        try await service.requestAccess()
    }

    func hasAccess() -> Bool {
        service.hasAccess()
    }


    func createEvent(title: String, date: Date, timeRange: String, colorName: String) async throws {
        try service.createEvent(title: title, date: date, timeRange: timeRange, colorName: colorName)
    }

    func createReminder(title: String, date: Date, timeRange: String, colorName: String) async throws {
        try service.createReminder(title: title, date: date, timeRange: timeRange, colorName: colorName)
    }

    func toggleReminderCompletion(id: String) async throws {
        try service.toggleReminderCompletion(id: id)
    }

    func deleteItem(id: String, isReminder: Bool) async throws {
        try service.deleteItem(id: id, isReminder: isReminder)
    }

    private func colorNameForCalendar(_ calendar: EKCalendar) -> String {
        let name = calendar.title.lowercased()
        if name.contains("work") { return "Purple" }
        if name.contains("personal") { return "Blue" }
        if name.contains("home") { return "Green" }
        if name.contains("reminder") { return "Teal" }
        return "Purple"
    }
}
