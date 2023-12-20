// SPDX-License-Identifier: MIT
//
//  APDUSetProtocolOperation.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 08/10/2022.
//

import Foundation
import AirIDDriver

class APDUSetProtocolOperation: APDUBaseOperation {
    private unowned var device: DeviceProtocol!
    private var cardProtocol: AIPCardProtocol
    
    override var description: String {
        "Protocol \(cardProtocol.description)"
    }
    
    init(device: DeviceProtocol, name: String, protocol: AIPCardProtocol) {
        self.device = device
        self.cardProtocol = `protocol`
        super.init(type: .setProtocol, deviceID: device.id, name: name)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.cardProtocol = try container.decode(AIPCardProtocol.self, forKey: .cardProtocol)
        try super.init(from: decoder)
    }
    
    override func setDevice(_ device: DeviceProtocol) {
        self.device = device
    }
    
    override func tryStart() async throws {
        try Task.checkCancellation()
        await self.state(to: .running)
        try await device.selectProtocol(cardProtocol: self.cardProtocol)
    }
    
    enum CodingKeys: String, CodingKey {
        case cardProtocol
    }
}

extension AIPCardProtocol: CustomStringConvertible, Codable {
    public var description: String {
        switch self {
        case .T0:
            return "T=0"
        case .T1:
            return "T=1"
        case .tx:
            return "T=0/T=1"
        case .raw:
            return "Raw"
        default:
            return "Unknown"
        }
    }
}
