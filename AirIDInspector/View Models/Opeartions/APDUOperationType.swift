// SPDX-License-Identifier: MIT
//
//  APDUOperationType.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 08/10/2022.
//

import Foundation

enum APDUOperationType: String, Codable {
    case apduTest
    case setProtocol
    case selectATR
}

/**
 A container to ensure type safety for the operations in the same time we initialize them from the store
 */
struct APDUOperationContainer: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case type
    }
    
    let type: APDUOperationType
    let id: UUID
    let internalOperation: APDUBaseOperation
    
    init(operation: APDUBaseOperation) {
        self.internalOperation = operation
        self.type = operation.type
        self.id = operation.id
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: APDUBaseOperation.CodingKeys.self)
        
        self.id = try container.decode(UUID.self, forKey: .id)
        let type = try container.decode(APDUOperationType.self, forKey: .type)
        
        self.type = type
        
        switch type {
        case .apduTest:
            self.internalOperation = try APDUTestOperation(from: decoder)
        case .setProtocol:
            self.internalOperation = try APDUSetProtocolOperation(from: decoder)
        case .selectATR:
            self.internalOperation = try APDUSelectATROperation(from: decoder)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        try internalOperation.encode(to: encoder)
    }
}
