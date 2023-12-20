// SPDX-License-Identifier: MIT
//
//  APDUOperationProtocol.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 08/10/2022.
//

import Foundation
import AirIDDriver

enum OperationError: Error, LocalizedError, Codable {
    case invalidResponse(Data, Data)
    case explicit(String)
    case serializationError(String)
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse(let expected, let actual):
            return "Invalid Response: \(expected.hexEncodedString()) | \(actual.hexEncodedString())"
        case .explicit(let error):
            return error
        case .cancelled:
            return "Cancelled"
        case .serializationError(let reason):
            return "Serialization Error: \(reason)"
        }
    }
}

enum OperationState: Codable {
    case pending
    case running
    case failed(OperationError)
    case success
    
    var name: String {
        switch self {
        case .pending:
            return "Pending"
        case .running:
            return "Running"
        case .success:
            return "Success"
        case .failed(let error):
            return error.localizedDescription
        }
    }
    
    var isLoading: Bool {
        switch self {
        case .pending: return false
        case .running: return true
        case .success: return false
        case .failed: return false
        }
    }
}


protocol APDUOperationProtocol: ObservableObject, Identifiable {
    
    var statePublisher: Published<OperationState>.Publisher { get }
    
    var name: String { get }
    
    func start() async
    
    func tryStart() async throws
    
    func state(to state: OperationState) async
}
