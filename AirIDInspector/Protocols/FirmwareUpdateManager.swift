// SPDX-License-Identifier: MIT
//
//  FirmwareUpdateManager.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 23/09/2022.
//

import Foundation
import AirIDDriver
import Combine

enum DeviceUpdateError: Error {
    case firmwareVersionUnavailable
    case updateIsAlreadyRunning
    case explicit(UpdaterError)
}

enum DeviceUpdateStatus {
    case unknown
    case checking
    case readyToInstall
    case progressing(Float)
    case failed(DeviceUpdateError)
    case upToDate
}


class FirmwareUpdateManager: ObservableObject {
    static var shared: FirmwareUpdateManager?
    
    private var updater: FirmwareUpdater!
    private var updateCache: [UUID: DeviceUpdateStatus] = [:]
    private var cancellables: Set<AnyCancellable> = []
    private var updateItem: UpdateItem?
    
    var currentDeviceOperation: UUID?
    var device: AIDDevice?
    
    private unowned var devicesManager: DevicesManager
    
    /**
     The firmware updater waits for an initialized device to become connnected with the iOS in order to tell if it's active
     */
    @Published var isCurrentlyActive: Bool = false
    @Published var latestVersion: String?
    @Published var isLoading: Bool = false
    @Published var currentVersion: String?
    
    @Published var updateStatus: DeviceUpdateStatus? {
        didSet {
            switch updateStatus {
            case .unknown: self.isLoading = false
            case .checking: self.isLoading = true
            case .progressing: self.isLoading = true
            case .readyToInstall: self.isLoading = false
            case .upToDate: self.isLoading = false
            case .failed: self.isLoading = false
            case .none: self.isLoading = false
            }
        }
    }
    
    var canUpdate: Bool {
        currentDeviceOperation == nil
    }
    
    var activeDevice: AIDDevice? {
        AIDDeviceManager.shared().connectedDevices.compactMap { $0 as? AIDDevice }.first { $0.status == .initialized }
    }
    
    init(devicesManager: DevicesManager) {
        self.devicesManager = devicesManager
        self.updater = .init(delegate: self, configClosure: { config in
            config.automaticallyChecksForUpdates = true
        })
        
        Self.shared = self
    }
    
    func start() {
        self.listenForChanges()
        self.checkNewerVersions()
    }
    
    private func listenForChanges() {
        self.devicesManager.connectedDevices.receive(on: DispatchQueue.main).sink { _ in
            self.isCurrentlyActive = self.activeDevice != nil
            self.latestVersion = nil
            self.currentVersion = self.activeDevice?.firmwareVersion
            self.checkNewerVersions()
        }.store(in: &cancellables)
    }
    
    func startUpdatingCurrentDevice() {
        guard let updateItem = self.updateItem, let device = self.activeDevice else {
            return
        }
        
        self.updater.updateFirmwareOf(device, withItem: updateItem)
    }
    
    func checkNewerVersions() {
        guard let currentVersion = self.activeDevice?.firmwareVersion else {
            self.updateStatus = .unknown
            return
        }
        
        self.updateStatus = .checking
        self.updater.checkForUpdates(currentVersion: currentVersion)
    }
}

extension FirmwareUpdateManager: FirmwareUpdaterDelegate {
    func firmwareUpdater(_ firmwareUpdater: AirIDDriver.FirmwareUpdater, runningLatestVersion: String) {
        
        DispatchQueue.main.async {
            self.latestVersion = runningLatestVersion
            self.updateStatus = .upToDate
        }
    }
    
    func firmwareUpdater(_ firmwareUpdater: AirIDDriver.FirmwareUpdater, onDownloadDidStartForItem: AirIDDriver.UpdateItem) {
        
        DispatchQueue.main.async {
            self.updateStatus = .progressing(0)
        }
    }
    
    func firmwareUpdater(_ firmwareUpdater: AirIDDriver.FirmwareUpdater, onDownloadDidFinishForItem: AirIDDriver.UpdateItem) {
        DispatchQueue.main.async {
            self.updateStatus = .progressing(1)
        }
    }
    
    func firmwareUpdater(_ firmwareUpdater: AirIDDriver.FirmwareUpdater, onSignatureDidVerifyForItem: AirIDDriver.UpdateItem) {
        
    }
    
    func firmwareUpdater(_ firmwareUpdater: AirIDDriver.FirmwareUpdater, onFlashProgress: Float, forDevice: AIDDevice) {
        DispatchQueue.main.async {
            self.updateStatus = .progressing(onFlashProgress)
        }
    }
    
    func firmwareUpdater(_ firmwareUpdater: FirmwareUpdater, error: UpdaterError) {
        DispatchQueue.main.async {
            self.updateStatus = .failed(.explicit(error))
        }
    }
    
    func firmwareUpdater(_ firmwareUpdater: FirmwareUpdater,
                         onUpdateAvailableForItem: UpdateItem,
                         latestVersion: String,
                         newVersion: String) {
        DispatchQueue.main.async {
            self.latestVersion = latestVersion
            self.updateItem = onUpdateAvailableForItem
            self.updateStatus = .readyToInstall
        }
    }
    
    func firmwareUpdater(_ firmwareUpdater: AirIDDriver.FirmwareUpdater, onDidSwitchToBootloaderForDevice: AIDDevice) {
    }
}
