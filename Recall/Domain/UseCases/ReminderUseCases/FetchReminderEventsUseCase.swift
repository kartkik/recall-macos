//
//  FetchReminderEventsUseCase.swift
//  Recall
//
//  Created by twixx  on 30/05/26.
//

import Foundation

struct FetchReminderEventsUseCase: Sendable{
    
    private let repository : EventKitRepositoryProtocol
    
    init(repository :EventKitRepositoryProtocol){
        self.repository = repository
    }
    
    
    func execute(date : Date) async throws -> [ReminderEvent]{
        try await repository.fetchEventAndReminders(for: date)
    }
}
