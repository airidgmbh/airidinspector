// SPDX-License-Identifier: MIT
//
//  DevicesManager.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 15/09/2022.
//

import Foundation
import Combine
import AirIDDriver

class DevicesManager: NSObject, DevicesManagerProtocol {
    typealias Device = DeviceWrapper
    
    var devices: AnyPublisher<[DeviceWrapper], Never> { devicesSubject.eraseToAnyPublisher() }
    var savedDevice: AnyPublisher<DeviceWrapper?, Never> { savedDeviceSubject.eraseToAnyPublisher() }
    var error: AnyPublisher<Error?, Never> { errorSubject.eraseToAnyPublisher() }
    var connectedDevices: AnyPublisher<[Device], Never> { connectedDevicesSubject.eraseToAnyPublisher() }
    
    fileprivate var devicesSubject: CurrentValueSubject<[DeviceWrapper], Never>
    fileprivate var connectedDevicesSubject: CurrentValueSubject<[DeviceWrapper], Never>
    fileprivate var savedDeviceSubject: CurrentValueSubject<DeviceWrapper?, Never>
    fileprivate var errorSubject: CurrentValueSubject<Error?, Never>
    
    private var manager: AIDDeviceManager = .shared()
    private var kvos: [NSKeyValueObservation] = []
    private var previousScanFlag = false
    private var isRunningDisconnectOperation = false
    private var connectionContinuation: CheckedContinuation<Void, Error>?
    
    override init() {
        self.devicesSubject = .init([])
        self.connectedDevicesSubject = .init([])
        
        self.savedDeviceSubject = .init(nil)
        self.errorSubject = .init(nil)
        self.previousScanFlag = manager.scanForPeripherals
        
        super.init()
        
        let devicesKVO = self.manager.observe(\.devices) { manager, change in
            self.devicesSubject.send(manager.devices.deviceWrappers(self))
            self.checkforSavedDevice()
        }
        
        let connectedKVO = self.manager.observe(\.connectedDevices) { manager, change in
            self.connectedDevicesSubject.send(manager.connectedDevices.deviceWrappers(self))
            self.checkforSavedDevice()
        }
        
         let savedDeviceKVO = self.manager.observe(\.savedDevice) { manager, change in
             self.checkforSavedDevice()
        }
        
        self.kvos = [devicesKVO, connectedKVO, savedDeviceKVO]
        self.manager.autoConnectSavedDevice = false
        self.manager.delegate = self
        self.manager.useDriverDeviceManagement = true
        
        self.manager.start(withAccessGroup: nil)
        self.manager.scanForPeripherals = true
    }
    
    deinit {
        kvos.forEach { $0.invalidate() }
        manager.scanForPeripherals = previousScanFlag
    }
    
    private func checkforSavedDevice() {
        guard let saved = manager.savedDevice else {
            self.savedDeviceSubject.send(nil)
            return
        }
        
        if let existing = (self.devicesSubject.value.first { $0.device.identifier == saved.identifier }) {
            self.savedDeviceSubject.send(existing)
        } else {
            self.savedDeviceSubject.send(.init(device: saved, manager: self))
        }
    }
    
    func connect(device: DeviceWrapper) async throws {
        guard connectionContinuation == nil else {
            return
        }
        
        self.isRunningDisconnectOperation = false
        
        device.connectionSuccess = {
            self.connectionContinuation?.resume()
            self.connectionContinuation = nil
        }
        
        _ = try await withCheckedThrowingContinuation { continuation in
            self.connectionContinuation = continuation
            manager.connectDevice(device.device)
        }
    }
    
    func disconnect(device: DeviceWrapper) async throws {
        guard connectionContinuation == nil else {
            return
        }
        
        self.isRunningDisconnectOperation = true
        device.connectionSuccess = {
            self.connectionContinuation?.resume()
            self.connectionContinuation = nil
        }
        
        _ = try await withCheckedThrowingContinuation { continuation in
            self.connectionContinuation = continuation
            manager.disconnectDevice(device.device)
        }
    }
}

private extension Array {
    func deviceWrappers(_ manager: DevicesManager) -> [DeviceWrapper] {
        self.compactMap { $0 as? AIDDevice }.map { .init(device: $0, manager: manager) }
    }
}


extension DevicesManager: AIDDeviceManagerDelegate {
    func deviceManager(_ manager: AIDDeviceManager, didConnect device: AIDDevice) {
        print("******** \(#function)")
    }

    func deviceManager(_ manager: AIDDeviceManager, didDisconnectDevice device: AIDDevice, error: Error?) {
        print("******** \(#function)")
        if let connectionContinuation, let error {
            connectionContinuation.resume(throwing: error)
            self.connectionContinuation = nil
        }
        
        if self.isRunningDisconnectOperation {
            self.connectionContinuation?.resume()
            self.connectionContinuation = nil
        }
    }
    
    func deviceManager(_ manager: AIDDeviceManager, didFailToConnect device: AIDDevice, error: Error?) {
        print("******** \(#function)")
        if let connectionContinuation, let error {
            connectionContinuation.resume(throwing: error)
            self.connectionContinuation = nil
        }
    }
    
    func deviceManagerDidForgetUserSelectedDevice(_ manager: AIDDeviceManager) {
        print("******** \(#function)")
    }
    
    func deviceManager(_ manager: AIDDeviceManager, willChangeUserSelectedDevice device: AIDDevice) {
        print("******** \(#function)")
    }
}

extension DeviceWrapper {
    var isSaved: Bool {
        manager.savedDeviceSubject.value?.id == self.id
    }
}
