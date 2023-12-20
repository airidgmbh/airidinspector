// SPDX-License-Identifier: MIT
//
//  DevicesListViewModel.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 13/09/2022.
//

import Foundation
import SwiftUI
import Combine
import AirIDDriver

@MainActor
class DevicesListViewModel<DevicesManager: DevicesManagerProtocol>: ObservableObject {
    
    @Published var connectedDevices: [DeviceViewModel] = []
    @Published var devices: [DeviceViewModel] = []
    @Published var savedDevice: DeviceViewModel? = nil
    @Published var error: Error?
    
    private var _deviceManager: DevicesManager
    private var cancellables: [AnyCancellable] = []
    
    init(devicesManager: DevicesManager) {
        _deviceManager = devicesManager
        setup()
    }
    
    func setup() {
        _deviceManager.connectedDevices.receive(on: DispatchQueue.main).sink {
            self.connectedDevices = $0.map { device in DeviceViewModel.init(device: device) }
        }.store(in: &cancellables)
        
        _deviceManager.devices.receive(on: DispatchQueue.main).sink {
            self.devices = $0.map { device in DeviceViewModel.init(device: device) }
        }.store(in: &cancellables)
        
        _deviceManager.savedDevice.receive(on: DispatchQueue.main).sink { device in
            self.savedDevice = self.devices.first { d in d.id == device?.id } ?? self.connectedDevices.first { d in d.id == device?.id }
        }.store(in: &cancellables)
        
        _deviceManager.error.receive(on: DispatchQueue.main).sink {
            self.error = $0
        }.store(in: &cancellables)
    }
}
