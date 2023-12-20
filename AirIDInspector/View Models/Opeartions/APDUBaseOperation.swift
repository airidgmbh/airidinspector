// SPDX-License-Identifier: MIT
//
//  APDUBaseOperation.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 08/10/2022.
//

import Foundation

class APDUBaseOperation: APDUOperationProtocol, Codable {
    let deviceID: UUID
    let name: String
    
    /**
     A Unique identifier only valid at the runtime for the operation, generally don't assume the id will be the same for operations among multiple picks.
     
     Each subclass has it's own way of identifying itself.
     */
    let id: UUID
    
    /**
     Every operation must hold a type that identifies it.
     */
    let type: APDUOperationType
    
    var description: String {
        measurements.description
    }
    
    @Published var state: OperationState = .pending
    @Published var measurements: APDUMeasurement
    
    lazy var benchTimer: APDUBenchTimerProtocol = {
        if #available(iOS 16.0, *) {
            return APDUClockBenchTimer()
        } else {
            return APDULegacyBenchTimer()
        }
    }()
    
    var statePublisher: Published<OperationState>.Publisher { $state }
    
    init(id: UUID = UUID(), type: APDUOperationType, deviceID: UUID, name: String) {
        self.measurements = .init(operationID: id)
        self.id = id
        self.type = type
        self.deviceID = deviceID
        self.name = name
    }
    
    
    func setDevice(_ device: DeviceProtocol) { }

    func start() async {
        do {
            try await self.tryStart()
            await self.state(to: .success)
        } catch {
            if error is CancellationError {
                await self.state(to: .failed(.cancelled))
            } else {
                await self.state(to: .failed(.explicit(error.localizedDescription)))
            }
        }
    }
    
    func tryStart() async throws { }
    
    func state(to state: OperationState) async {
        await MainActor.run {
            self.state = state
        }
        
        switch state {
        case .pending:
            print("Returning \(name) to Pending")
        case .running:
            print("Running \(name)")
        case .failed(let operationError):
            print("\(name) has failed: \(operationError.localizedDescription)")
        case .success:
            print("\(name): Success")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(deviceID, forKey: .deviceID)
        try container.encode(name, forKey: .name)
        try container.encode(measurements, forKey: .measurements)
        try container.encode(state, forKey: .state)
        try container.encode(type, forKey: .type)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.deviceID = try container.decode(UUID.self, forKey: .deviceID)
        self.name = try container.decode(String.self, forKey: .name)
        self.measurements = try container.decode(APDUMeasurement.self, forKey: .measurements)
        self.state = try container.decode(OperationState.self, forKey: .state)
        self.type = try container.decode(APDUOperationType.self, forKey: .type)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case deviceID
        case name
        case measurements
        case state
    }
}
