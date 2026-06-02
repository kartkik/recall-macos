//
//  CreateReminderEventUseCase.swift
//  Recall
//
//  Created by twixx  on 30/05/26.
//

import Foundation


struct CreateReminderEventUseCase: Sendable {
    
    private let repository: EventKitRepositoryProtocol
    
    
    init(repository: EventKitRepositoryProtocol) {
        self.repository = repository
    }
    
    
    func execute(title: String,
    date: Date, timeRange : String, colorName: String, isReminder: Bool) async throws {
        
        
        if isReminder{
            try await repository.createReminder(title: title, date: date, timeRange: timeRange, colorName: colorName)
        }else{
            try await repository.createEvent(title: title, date: date, timeRange: timeRange, colorName: colorName)
        }
    }
    
    
    
}
