// SPDX-License-Identifier: MIT
//
//  Device.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 15/09/2022.
//

import Foundation
import Combine
import AirIDDriver

class DeviceWrapper: DeviceProtocol {
    struct NotFoundError: LocalizedError {
        var errorDescription: String? {
            "No Response"
        }
    }
    
    let device: AIDDevice
    let card: AIDCard
    
    private var kvos: [NSKeyValueObservation] = []
    private var signalSubject: CurrentValueSubject<DeviceSignalStrength, Never>
    private var nameSubject: CurrentValueSubject<String, Never>
    private var statusSubject: CurrentValueSubject<DeviceStatus, Never>
    private var cardStatusSubject: CurrentValueSubject<CardStatus, Never>
    
    var connectionSuccess: (() -> Void)?
    
    var signalStrength: AnyPublisher<DeviceSignalStrength, Never> {
        signalSubject.eraseToAnyPublisher()
    }
    
    var name: AnyPublisher<String, Never> {
        nameSubject.eraseToAnyPublisher()
    }
    
    var status: AnyPublisher<DeviceStatus, Never> {
        statusSubject.eraseToAnyPublisher()
    }
    
    var cardStatus: AnyPublisher<CardStatus, Never> {
        cardStatusSubject.eraseToAnyPublisher()
    }
    
    unowned var manager: DevicesManager
    
    var id: UUID {
        device.identifier
    }
    
    init(device: AIDDevice, manager: DevicesManager) {
        self.device = device
        self.card = .init(device: device)
        self.statusSubject = .init(.init(deviceStatus: device.status))
        self.signalSubject = .init(.init(strength: device.signalStrength.doubleValue))
        self.nameSubject = .init(device.name)
        self.cardStatusSubject = .init(device.cardStatus)
        self.manager = manager
        
        let statusKVO = device.observe(\.status) { device, change in
            self.statusSubject.send(.init(deviceStatus: device.status))
            if device.status == .connected || device.status == .initialized {
                self.connectionSuccess?()
            }
        }
        
        let cardStatusKVO = device.observe(\.cardStatus) { device, change in
            self.cardStatusSubject.send(device.cardStatus)
        }
        
        let signalKVO = device.observe(\.signalStrength) { device, change in
            self.signalSubject.send(.init(strength: device.signalStrength.doubleValue))
        }
        
        let nameKVO = device.observe(\.name) { device, change in
            self.nameSubject.send(device.name)
        }
        
        self.kvos = [statusKVO, signalKVO, nameKVO, cardStatusKVO]
    }
    
    deinit {
        kvos.forEach { $0.invalidate() }
    }
    
    func wakeUp() async throws -> Data {
        let response: Data = try await withCheckedThrowingContinuation { continuation in
            self.card.resetCard { response, error in
                guard let response = response else {
                    continuation.resume(throwing: error ?? NotFoundError())
                    return
                }
                
                continuation.resume(returning: response)
            }
        }
        
        return response
    }
    
    func sendAPDU(with data: Data) async throws -> Data {
        let response: Data = try await withCheckedThrowingContinuation { continuation in
            self.card.sendAPDU(with: data, withIORequest: nil) { response, _, error in
                guard let response = response else {
                    continuation.resume(throwing: error ?? NotFoundError())
                    return
                }
                
                continuation.resume(returning: response)
            }
        }

        return response
    }
    
    func selectProtocol(cardProtocol: AIPCardProtocol) async throws {
        let _: Void = try await withCheckedThrowingContinuation({ continuation in
            self.card.setProtocol(.T1) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                continuation.resume()
            }
        })
    }
    
    func shutDown() async throws {
        let _: Void = try await withCheckedThrowingContinuation { continuation in
            self.card.shutdownCard { error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                continuation.resume(returning: Void())
            }
        }
    }
    
    func connect() async throws {
        try await manager.connect(device: self)
    }
    
    func disconnect() async throws {
        try await manager.disconnect(device: self)
    }
}
