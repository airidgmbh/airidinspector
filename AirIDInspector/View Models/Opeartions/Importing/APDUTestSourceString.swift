// SPDX-License-Identifier: MIT
//
//  APDUTestSourceString.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 08/10/2022.
//

import Foundation
import AirIDDriver

class APDUTestSourceString: APDUTestSourceProtocol {
    struct InvalidFileError: LocalizedError {
        var errorDescription: String? {
            "File is invalid"
        }
    }
    
    let rawString: String
    
    init(string: String) {
        self.rawString = string
    }
    
    func getAPDUTestOperations(for device: DeviceProtocol) throws -> [APDUBaseOperation] {
        var lines = rawString.components(separatedBy: .newlines)
        var operations: [APDUBaseOperation] = []
        
        if let firstLine = lines.first, firstLine.starts(with: "T=") {
            let protocolType = String(firstLine.dropFirst(2))
            var cardProtocol: AIPCardProtocol
            
            switch protocolType {
            case "1": cardProtocol = .T1
            case "0": cardProtocol = .T0
            default: cardProtocol = .tx
            }
            
            
            operations.append(APDUSetProtocolOperation(device: device, name: "Set Protocol..", protocol: cardProtocol))
            lines.removeFirst()
        }
        
        if let firstLine = lines.first, firstLine.starts(with: "ATR:") {
            let ATR = String(firstLine.dropFirst(4)).hexadecimal
            if let atrData = ATR {
                operations.insert(APDUSelectATROperation(device: device, name: "Select ATR..", atrData: atrData), at: 0)
            }
            
            lines.removeFirst()
        } else {
            // manually append the select ATR operation
            operations.insert(APDUSelectATROperation(device: device, name: "Selecting ATR..", atrData: nil), at: 0)
        }
        
        let chunks = stride(from: 0, to: lines.count, by: 2).map {
            Array(lines[$0 ..< Swift.min($0 + 2, lines.count)])
        }
        
        if chunks.isEmpty {
            throw InvalidFileError()
        }
        
        
        for chunk in chunks {
            if let data = chunk.first?.hexadecimal, let response = chunk.last {
                let newOperation = APDUTestOperation(device: device,
                                                     data: data,
                                                     expectedResponse: response)
                operations.append(newOperation)
            }
        }
        
        return operations
    }
}
