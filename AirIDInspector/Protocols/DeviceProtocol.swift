// SPDX-License-Identifier: MIT
//
//  DeviceProtocol.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 14/09/2022.
//

import Foundation
import SwiftUI
import Combine
import AirIDDriver

protocol DeviceProtocol: AnyObject {
    
    var id: UUID { get }
    
    var signalStrength: AnyPublisher<DeviceSignalStrength, Never> { get }
    
    var name: AnyPublisher<String, Never> { get }
    
    var status: AnyPublisher<DeviceStatus, Never> { get }
    
    var cardStatus: AnyPublisher<CardStatus, Never> { get }
    
    /// returns the ATR of the card upon the wake up
    func wakeUp() async throws -> Data
    
    /// sends an APDU data to the card, and returns the resopnse
    func sendAPDU(with data: Data) async throws -> Data
    
    /// sends a method to select protocol
    func selectProtocol(cardProtocol: AIPCardProtocol) async throws
    
    /// shuts down the card upon finishing
    func shutDown() async throws
    
    /// connects the device to the iOS
    func connect() async throws
    
    /// disconnects the device if it's connected
    func disconnect() async throws
}

class MockedDevice: DeviceProtocol, ObservableObject {
    var id: UUID
    var signalStrength: AnyPublisher<DeviceSignalStrength, Never>
    var name: AnyPublisher<String, Never>
    var status: AnyPublisher<DeviceStatus, Never>
    var cardStatus: AnyPublisher<CardStatus, Never>
    
    var nameSubject: CurrentValueSubject<String, Never>
    var signalSubject: CurrentValueSubject<DeviceSignalStrength, Never>
    var statusSubject: CurrentValueSubject<DeviceStatus, Never>
    var cardStatusSubject: CurrentValueSubject<CardStatus, Never>
    
    private var nextExpectedResponse: Data?
        
    internal init(id: UUID, signalStrength: DeviceSignalStrength, name: String? = nil, status: DeviceStatus) {
        self.id = id
        self.signalSubject = CurrentValueSubject(signalStrength)
        self.nameSubject = CurrentValueSubject(name ?? id.uuidString)
        self.statusSubject = .init(status)
        self.cardStatusSubject = .init(.absent)
        
        self.signalStrength = signalSubject.eraseToAnyPublisher()
        self.name = nameSubject.eraseToAnyPublisher()
        self.status = statusSubject.eraseToAnyPublisher()
        self.cardStatus = cardStatusSubject.eraseToAnyPublisher()
        
        Task.detached(priority: .background) {
            try await Task.sleep(nanoseconds: 1_000_000_000 * UInt64.random(in: 1...4))
            self.signalSubject.send(.wellDone)
        }
    }
    
    func setNextExpectedResponse(_ response: Data) {
        nextExpectedResponse = response
    }
    
    func wakeUp() async throws -> Data {
        return Data()
    }
    
    func sendAPDU(with data: Data) async throws -> Data {
        try await Task.sleep(nanoseconds: 1_000_000_000 * UInt64.random(in: 1...5))
        return nextExpectedResponse ?? data
    }
    
    func selectProtocol(cardProtocol: AIPCardProtocol) async throws {
        
    }
    
    func shutDown() async throws {
        
    }
    
    static func mocked() -> MockedDevice {
        .init(id: UUID(), signalStrength: .medium, name: "Mocked Device", status: .absent)
    }
    
    func connect() async throws {
        self.statusSubject.send(.connected)
    }
    
    func disconnect() async throws {
        self.statusSubject.send(.present)
    }
}
