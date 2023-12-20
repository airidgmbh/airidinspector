// SPDX-License-Identifier: MIT
//
//  MainViewModel.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 13/09/2022.
//

import Foundation
import SwiftUI
import Combine
import AirIDDriver

class MainViewModel: NSObject, ObservableObject {
    
    @Published var error: Error?
    @Published var connection: ConnectionStatus
    
    private let devicesManager = AIDDeviceManager.shared()
    private var scanOldValue = false

    
    override init() {
        self.connection = .off
        super.init()
       
        devicesManager.autoConnectSavedDevice = true
        devicesManager.scanForPeripherals = true
        devicesManager.useDriverDeviceManagement = true
        devicesManager.delegate = self
        devicesManager.start(withAccessGroup: "com.airid.AirIDInspector")
        
        scanOldValue = devicesManager.scanForPeripherals
        devicesManager.scanForPeripherals = true
    }
    
    deinit {
        devicesManager.scanForPeripherals = scanOldValue
    }
}

extension MainViewModel: AIDDeviceManagerDelegate {
    func deviceManagerStatePower(on manager: AIDDeviceManager) {
        self.connection = .on
    }
    
    func deviceManagerStatePowerOff(_ manager: AIDDeviceManager) {
        self.connection = .off
    }
    
    func deviceManager(_ manager: AIDDeviceManager, didDisconnectDevice device: AIDDevice, error: Error?) {
        self.error = error
    }
    
    func deviceManager(_ manager: AIDDeviceManager, didFailToConnect device: AIDDevice, error: Error?) {
        self.error = error
    }
}
