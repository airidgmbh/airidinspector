// SPDX-License-Identifier: MIT
//
//  APDUSelectATROperation.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 08/10/2022.
//

import Foundation
import AirIDDriver

class APDUSelectATROperation: APDUBaseOperation {
    private unowned var device: DeviceProtocol!
    private(set) var atrData: Data?
    private(set) var responseATR: Data?
    
    override var description: String {
        responseATR?.hexEncodedString() ?? ""
    }
    
    init(device: DeviceProtocol, name: String = "Selecting ATR..", atrData: Data?) {
        self.device = device
        self.atrData = atrData
        super.init(type: .selectATR, deviceID: device.id, name: name)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.atrData = try container.decodeIfPresent(Data.self, forKey: .atrData)
        self.responseATR = try container.decodeIfPresent(Data.self, forKey: .responseATR)
        
        try super.init(from: decoder)
    }
    
    override func setDevice(_ device: DeviceProtocol) {
        self.device = device
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(atrData, forKey: .atrData)
        try container.encode(responseATR, forKey: .responseATR)
    }
    
    override func tryStart() async throws {
        try Task.checkCancellation()
        await self.state(to: .running)
        let response = try await self.device.wakeUp()
        
        guard let atrData = self.atrData else {
            return
        }
        
        self.responseATR = response
        if response != atrData {
            throw OperationError.invalidResponse(atrData, response)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case atrData
        case responseATR
    }
}
