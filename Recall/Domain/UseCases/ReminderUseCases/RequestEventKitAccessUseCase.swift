//
//  RequestEventKitAccessUseCase.swift
//  Recall
//
//  Created by twixx  on 30/05/26.
//

import Foundation

struct RequestEventKitAccessUseCase: Sendable{
    private let repository: EventKitRepositoryProtocol
    
    
    init(repository: EventKitRepositoryProtocol) {
        self.repository = repository
    }
    
    func execute() async throws -> Bool {
        try await repository.requestAccess()
    }
    
}
