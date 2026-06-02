//
//  DeleteReminderEventUseCase.swift
//  Recall
//
//  Created by twixx  on 30/05/26.
//

import Foundation

struct DeleteReminderEventUseCase: Sendable{
    
    private let repository: EventKitRepositoryProtocol
    
    init(repository: EventKitRepositoryProtocol) {
        self.repository = repository
    }
    
    
    func execute(id : String, isReminder : Bool ) async throws {
        try await repository.deleteItem(id: id , isReminder: isReminder)
    }
}
