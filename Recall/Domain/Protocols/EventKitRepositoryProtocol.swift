//
//  EventKitRepositoryProtocol.swift
//  Recall
//
//  Created by twixx  on 30/05/26.
//

import Foundation


protocol EventKitRepositoryProtocol :Sendable {
    func requestAccess() async throws -> Bool
    func hasAccess() async -> Bool
    func fetchEventAndReminders(for date: Date) async throws -> [ReminderEvent]
    func createEvent(title: String, date: Date, timeRange : String, colorName: String) async throws
    func createReminder(title: String, date: Date,timeRange : String, colorName: String) async throws
    func toggleReminderCompletion(id: String) async throws
    func deleteItem(id: String, isReminder: Bool) async throws

}
    