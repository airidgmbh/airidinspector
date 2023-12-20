// SPDX-License-Identifier: MIT
//
//  APDUTestOperation.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 14/09/2022.
//

import Foundation
import AirIDDriver

class APDUTestOperation: APDUBaseOperation {
    struct Options: OptionSet, Codable {
        let rawValue: Int
        
        static let evaluateRegex  : Options  = Options(rawValue: 1 << 0)
        static let defaultOptions : Options = [.evaluateRegex]
    }
    
    let data: Data
    let expectedResponse: String
    let options: Options
    
    private unowned var device: DeviceProtocol!
    
    init(device: DeviceProtocol,
         data: Data,
         expectedResponse: String,
         options: Options = .defaultOptions) {
        self.device = device
        self.data = data
        self.expectedResponse = expectedResponse
        self.options = options
        super.init(type: .apduTest, deviceID: device.id, name: data.hexEncodedString())
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.data = try container.decode(Data.self, forKey: .data)
        self.expectedResponse = try container.decode(String.self, forKey: .expectedResponse)
        self.options = try container.decodeIfPresent(Options.self, forKey: .options) ?? .defaultOptions
        
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(data, forKey: .data)
        try container.encode(expectedResponse, forKey: .expectedResponse)
        try container.encode(options, forKey: .options)
    }
    
    override func setDevice(_ device: DeviceProtocol) {
        self.device = device
    }
    
    override func tryStart() async throws {
        try Task.checkCancellation()
        await self.state(to: .running)
        
        var response: Data?
        try await self.benchTimer.measure {
            response = try await self.device.sendAPDU(with: data)
        }.append(to: self.measurements)
        
        let lastTwoBytes = response![(response!.count - 2)...(response!.endIndex - 1)]
        
        if options.contains(.evaluateRegex) {
            let responseString = response!.hexEncodedString()
            let expectedString = expectedResponse
            
            guard responseString.range(of: expectedString,
                                       options: .regularExpression) != nil else {
                throw OperationError.invalidResponse(lastTwoBytes, expectedResponse.hexadecimal ?? Data())
            }
            
            return
        }
        
        guard let hexExpectedResponse = expectedResponse.hexadecimal else {
            throw OperationError.serializationError("Expected Response isn't hex format")
        }
        
        if expectedResponse.count == 2, lastTwoBytes != hexExpectedResponse {
            throw OperationError.invalidResponse(lastTwoBytes, hexExpectedResponse)
        } else if response != hexExpectedResponse {
            throw OperationError.invalidResponse(response!, hexExpectedResponse)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case data
        case expectedResponse
        case options
    }
}
