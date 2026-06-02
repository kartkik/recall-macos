//
//  EventKitService.swift
//  Recall
//

import Foundation
import EventKit

final class EventKitService: Sendable {
    private let store = EKEventStore()

    func requestAccess() async throws -> Bool {
        let calendarStatus = EKEventStore.authorizationStatus(for: .event)
        let remindersStatus = EKEventStore.authorizationStatus(for: .reminder)
        
        var calendarGranted = false
        var remindersGranted = false
        
        if #available(macOS 14.0, *) {
            if calendarStatus == .notDetermined {
                calendarGranted = try await store.requestFullAccessToEvents()
            } else {
                calendarGranted = calendarStatus == .authorized || calendarStatus == .fullAccess
            }
            
            if remindersStatus == .notDetermined {
                remindersGranted = try await store.requestFullAccessToReminders()
            } else {
                remindersGranted = remindersStatus == .authorized || remindersStatus == .fullAccess
            }
        } else {
            if calendarStatus == .notDetermined {
                calendarGranted = try await withCheckedThrowingContinuation { continuation in
                    store.requestAccess(to: .event) { granted, error in
                        if let error = error { continuation.resume(throwing: error) }
                        else { continuation.resume(returning: granted) }
                    }
                }
            } else {
                calendarGranted = calendarStatus == .authorized
            }
            
            if remindersStatus == .notDetermined {
                remindersGranted = try await withCheckedThrowingContinuation { continuation in
                    store.requestAccess(to: .reminder) { granted, error in
                        if let error = error { continuation.resume(throwing: error) }
                        else { continuation.resume(returning: granted) }
                    }
                }
            } else {
                remindersGranted = remindersStatus == .authorized
            }
        }
        
        return calendarGranted && remindersGranted
    }

    func hasAccess() -> Bool {
        let calendarStatus = EKEventStore.authorizationStatus(for: .event)
        let remindersStatus = EKEventStore.authorizationStatus(for: .reminder)
        
        if #available(macOS 14.0, *) {
            return (calendarStatus == .authorized || calendarStatus == .fullAccess) &&
                   (remindersStatus == .authorized || remindersStatus == .fullAccess)
        } else {
            return calendarStatus == .authorized && remindersStatus == .authorized
        }
    }

    func fetchEvents(for date: Date) -> [EKEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return [] }
        
        let predicate = store.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        return store.events(matching: predicate)
    }

    func fetchReminders(for date: Date) async -> [EKReminder] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return [] }
        
        let predicate = store.predicateForIncompleteReminders(withDueDateStarting: startOfDay, ending: endOfDay, calendars: nil)
        let incomplete = await withCheckedContinuation { (continuation: CheckedContinuation<[EKReminder], Never>) in
            store.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
        
        let completedPredicate = store.predicateForCompletedReminders(withCompletionDateStarting: startOfDay, ending: endOfDay, calendars: nil)
        let completed = await withCheckedContinuation { (continuation: CheckedContinuation<[EKReminder], Never>) in
            store.fetchReminders(matching: completedPredicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
        
        return incomplete + completed
    }

    func createEvent(title: String, date: Date, timeRange: String, colorName: String) throws {
        let event = EKEvent(eventStore: store)
        event.title = title
        
        let calendar = Calendar.current
        let parsedTimes = parseTimeRange(timeRange, for: date)
        event.startDate = parsedTimes.start
        event.endDate = parsedTimes.end
        event.calendar = store.defaultCalendarForNewEvents
        
        try store.save(event, span: .thisEvent, commit: true)
    }

    func createReminder(title: String, date: Date, timeRange: String, colorName: String) throws {
        let reminder = EKReminder(eventStore: store)
        reminder.title = title
        reminder.calendar = store.defaultCalendarForNewReminders()
        
        let calendar = Calendar.current
        let parsedTimes = parseTimeRange(timeRange, for: date)
        reminder.dueDateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: parsedTimes.start)
        reminder.startDateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: parsedTimes.start)
        
        try store.save(reminder, commit: true)
    }

    func toggleReminderCompletion(id: String) throws {
        guard let item = store.calendarItem(withIdentifier: id) as? EKReminder else {
            throw NSError(domain: "EventKitService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Reminder not found"])
        }
        item.isCompleted.toggle()
        try store.save(item, commit: true)
    }

    func deleteItem(id: String, isReminder: Bool) throws {
        guard let item = store.calendarItem(withIdentifier: id) else {
            throw NSError(domain: "EventKitService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Item not found"])
        }
        
        if isReminder {
            guard let reminder = item as? EKReminder else { return }
            try store.remove(reminder, commit: true)
        } else {
            guard let event = item as? EKEvent else { return }
            try store.remove(event, span: .thisEvent, commit: true)
        }
    }

    private func parseTimeRange(_ range: String, for date: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        let components = range.components(separatedBy: "–").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard components.count >= 1, let startStr = components.first, !startStr.isEmpty else {
            return (startOfDay, calendar.date(byAdding: .hour, value: 1, to: startOfDay) ?? startOfDay)
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        guard let parsedStart = formatter.date(from: startStr) else {
            return (startOfDay, calendar.date(byAdding: .hour, value: 1, to: startOfDay) ?? startOfDay)
        }
        
        var startComponents = calendar.dateComponents([.year, .month, .day], from: startOfDay)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: parsedStart)
        startComponents.hour = timeComponents.hour
        startComponents.minute = timeComponents.minute
        
        guard let startDate = calendar.date(from: startComponents) else {
            return (startOfDay, calendar.date(byAdding: .hour, value: 1, to: startOfDay) ?? startOfDay)
        }
        
        var endDate = calendar.date(byAdding: .hour, value: 1, to: startDate) ?? startDate
        if components.count > 1, let endStr = components.last, let parsedEnd = formatter.date(from: endStr) {
            var endComponents = calendar.dateComponents([.year, .month, .day], from: startOfDay)
            let endTimeComponents = calendar.dateComponents([.hour, .minute], from: parsedEnd)
            endComponents.hour = endTimeComponents.hour
            endComponents.minute = endTimeComponents.minute
            if let dateEnd = calendar.date(from: endComponents) {
                endDate = dateEnd
            }
        }
        
        return (startDate, endDate)
    }
}
