// SPDX-License-Identifier: MIT
//
//  DevicesManagerProtocol.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 14/09/2022.
//

import Foundation
import Combine

protocol DevicesManagerProtocol {
    associatedtype Device: DeviceProtocol
    
    var devices: AnyPublisher<[Device], Never> { get }
    var connectedDevices: AnyPublisher<[Device], Never> { get }
    
    var savedDevice: AnyPublisher<Device?, Never> { get }
    var error: AnyPublisher<Error?, Never> { get }
    
    func connect(device: Device) async throws
    func disconnect(device: Device) async throws
}

class MockedDevicesManager: DevicesManagerProtocol {
    typealias Device = MockedDevice
    
    var devices: AnyPublisher<[MockedDevice], Never> {
        devicesSubject.eraseToAnyPublisher()
    }
    
    var savedDevice: AnyPublisher<MockedDevice?, Never> {
        savedDeviceSubject.eraseToAnyPublisher()
    }
    
    var error: AnyPublisher<Error?, Never> {
        errorSubject.eraseToAnyPublisher()
    }
    
    var connectedDevices: AnyPublisher<[Device], Never> {
        connectedDevicesSubject.eraseToAnyPublisher()
    }
    
    var devicesSubject: CurrentValueSubject<[MockedDevice], Never>
    var connectedDevicesSubject: CurrentValueSubject<[MockedDevice], Never>
    var savedDeviceSubject: CurrentValueSubject<MockedDevice?, Never>
    var errorSubject: CurrentValueSubject<Error?, Never>
    
    private var devicesList: [Device] = []
    
    init() {
        self.devicesSubject = .init([])
        self.savedDeviceSubject = .init(nil)
        self.errorSubject = .init(nil)
        self.connectedDevicesSubject = .init([])
        
        var array: [MockedDevice] = []
        var connected: [MockedDevice] = []
        (0...10).forEach { index in
            let device = MockedDevice(id: UUID(), signalStrength: .medium, status: .absent)
            array.append(device)
            
            if index.isMultiple(of: 2) {
                connected.append(device)
            }
        }
        
        devicesSubject.send(array)
        connectedDevicesSubject.send(connected)
    }
    
    func connect(device: MockedDevice) async throws {
        try await Task.sleep(nanoseconds: 100_000_000 * 2)
    }
    
    func disconnect(device: MockedDevice) async throws {
        try await Task.sleep(nanoseconds: 100_000_000 * 2)
    }
    
    func generateNewRandomElementIfNeeded() async -> Device? {
        if devicesList.count < 10 {
            return Device(id: UUID(), signalStrength: .medium, name: "Device \(devicesList.count)", status: .present)
        } else {
            return nil
        }
    }
}
