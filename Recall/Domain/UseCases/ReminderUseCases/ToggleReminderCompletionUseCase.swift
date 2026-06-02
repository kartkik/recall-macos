//
//  ToggleReminderCompletionUseCase.swift
//  Recall
//
//  Created by twixx  on 30/05/26.
//

import Foundation


struct ToggleReminderCompletionUseCase: Sendable{
    
    
    private let repository: EventKitRepositoryProtocol
    
    init(repository: EventKitRepositoryProtocol) {
        self.repository = repository
    }
    
    
    func execute(id : String) async throws {
        try await repository.toggleReminderCompletion(id: id)
    }
}
    
