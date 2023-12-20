// SPDX-License-Identifier: MIT
//
//  APDUTestSourceSnapshot.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 08/10/2022.
//

import Foundation

class APDUTestSourceSnapshot: APDUTestSourceProtocol {
    enum Source {
        case file(URL)
        case data(Data)
        case operations([APDUBaseOperation])
    }
    
    struct APDUTestContents: Codable {
        let deviceIdentifier: UUID
        let operations: [APDUOperationContainer]
    }
    
    let source: Source
    
    init(data: Data) {
        self.source = .data(data)
    }
    
    init(fileURL: URL) {
        self.source = .file(fileURL)
    }
    
    init(operations: [APDUBaseOperation]) {
        self.source = .operations(operations)
    }
    
    func getAPDUTestOperations(for device: DeviceProtocol) throws -> [APDUBaseOperation] {
        return try self.contents(of: source, for: device)
    }
    
    private func contents(of source: Source, for device: DeviceProtocol) throws -> [APDUBaseOperation] {
        switch self.source {
        case .data(let data):
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let containers = try decoder.decode(APDUTestContents.self, from: data)
            
            let operations = containers.operations.map { $0.internalOperation }
            return operations
        case .file(let url):
            return try self.contents(of: .data(try Data(contentsOf: url)), for: device)
        case .operations(let operations):
            operations.forEach { $0.setDevice(device) }
            return operations
        }
    }
}
