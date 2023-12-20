//
//  FirmwareUpdater.swift
//  AirIDDriver-iOS_dyn_nopods
//
//  Created by Viktor Krykun on 07.02.21.
//  Copyright © 2021 certgate GmbH. All rights reserved.
//

import Foundation
import os.log

/**
 Update metadata

 This structure is returned by `FirmwareUpdater`  when a new update was found. It is also accepted
 as an input parameter by `FirmwareUpdater.updateFirmwareOf(withItem:)`.

 Public  fields of  `UpdateItem` should be used by the application to display update notification
 to the user. This data structure also contains some internal fields which `FirmwareUpdater` needs
 to download and verify the update.
 */
public struct UpdateItem {
    /// Title of the update given by the publisher.
    ///
    /// example: `AirID version 2.1.0-beta7`
    public let title: String?
    
    /// URL to the release notes in HTML format.
    public let releaseNotes: URL?
    
    /// Update release date and timestamp.
    public let pubDate: Date
    
    /// Update version in semantic versioning format.
    ///
    /// example:  `2.1.0-beta7`
    public let version: String
    
    /// Minimal hardware revision required to install current update.
    ///
    /// Currently not used.
    public let requiredSystemVersion: String?
    
    /// Flag which indicates that the update was marked as "mandatory" by the publisher.
    ///
    /// It is usually an indication that the update includes important bug or security vulnerability fixed.
    public let forcedUpdate: Bool
    
    // URL which point to the update blob
    internal let appURL: URL
    // BASE-64 encoded Curve25519 signature of the update blob.
    internal let appSignature: String
    // Length of the update blob in bytes
    internal let appLength: Int?
}

/**
 A protocol that provides updates for the availability of firmware updates and firmware installation progress.
 
 
 ```
                            *--> firmwareUpdater(_, runningLatestVersion)
 updater.checkForUpdates()-/
                           \
                            *--> firmwareUpdater(_, onUpdateAvailableForItem, latestVersion, newVersion)
                                
 updater.updateFirmwareOf(_ device: AIDDevice, withItem item: UpdateItem)
                                \
                                 *--> firmwareUpdater(_, onDownloadDidStartForItem) --*
                                                                                      |
                                *-- firmwareUpdater(_, onDownloadDidFinishForItem) <--*
                                |
                    *-------->  *--> firmwareUpdater(_, onFlashProgress, forDevice)
                   /                  ...
                  /                  firmwareUpdater(_, onDownloadDidFinishForItem) --*
                 /                                                                    |
                /             firmwareUpdater(_, onDidSwitchToBootloaderForDevice) <--*
               /
              /
 updater.updateFirmwareOf(_ device: AIDDevice, firmwareBundlePath: URL)
 
 
  * --> firmwareUpdater(_, UpdaterError)
 ```
 */
public protocol FirmwareUpdaterDelegate {
    /**
     Tells the delegate the firmware updater found new firmware version at the update server.
     
     - Parameters:
        - _ : The firmware updater hat provides this information.
        - onUpdateAvailableForItem: Update information
        - latestVersion: Firmware version AirID is currently running
        - newVersion: New firmware version available to download.
     */
    func firmwareUpdater(_ firmwareUpdater: FirmwareUpdater,  onUpdateAvailableForItem: UpdateItem, latestVersion: String, newVersion: String)
    
    /**
     Tells the delegate that connected AIDDevice is running the latest version available.
     
     This method is called when `checkForUpdates()` was explicitly called by the client. It is not
     called when the firmware updater perform periodic checks, and there are no updates available.
     
     - Parameters:
        - _ : The firmware updater hat provides this information.
        - runningLatestVersion: Firmware version AirID is currently running
     */
    func firmwareUpdater(_ firmwareUpdater: FirmwareUpdater,  runningLatestVersion: String)
    
    /**
     Tells the delegate the firmware updater started downloading firmware update.
     
     - Parameters:
        - _ : The firmware updater hat provides this information.
        - onDownloadDidStartForItem: Update item for which the update was initiated.
     */
    func firmwareUpdater(_ firmwareUpdater: FirmwareUpdater, onDownloadDidStartForItem: UpdateItem)
    
    /**
     Tells the delegate the firmware updater finished downloading firmware update.
     
     - Parameters:
        - _ : The firmware updater hat provides this information.
        - onDownloadDidStartForItem: Update item for which the update was initiated.
     */
    func firmwareUpdater(_ firmwareUpdater: FirmwareUpdater, onDownloadDidFinishForItem: UpdateItem)
    
    /**
     Tells the delegate the firmware updater checked signature of the downloaded update.
     
     - Parameters:
        - _ : The firmware updater hat provides this information.
        - onSignatureDidVerifyForItem: Update item for which the update was initiated.
     */
    func firmwareUpdater(_ firmwareUpdater: FirmwareUpdater, onSignatureDidVerifyForItem: UpdateItem)
    
    /**
     Updates delegate on the progress of of transferring firmware update to AirID Device over Bluetooth.
     
     - Parameters:
        - _ : The firmware updater that provides this information.
        - onFlashProgress: Flashing progress. 1.0 means that firmware update completely transferred to the device.
        - forDevice: Device for which `updateFirmwareOf(_ device: AIDDevice, withItem item: UpdateItem)` was called.
     */
    func firmwareUpdater(_ firmwareUpdater: FirmwareUpdater, onFlashProgress: Float, forDevice: AIDDevice)
    
    /**
     Tells the delegate the firmware updater finished transferred firmware update to the device and triggered bootloader mode.
     
     After this method was called, AirID Device should reboot into bootloader mode, and firmware
     update should start on the device.
     
     - Parameters:
        - _ : The firmware updater that provides this information.
        - onDidSwitchToBootloaderForDevice: Device for which `updateFirmwareOf(_ device: AIDDevice, withItem item: UpdateItem)` was called.
     */
    func firmwareUpdater(_ firmwareUpdater: FirmwareUpdater, onDidSwitchToBootloaderForDevice: AIDDevice)
    
    /**
     Notifies delegate that error happened during the update process.
    */
    func firmwareUpdater(_ firmwareUpdater: FirmwareUpdater, error: UpdaterError)
}


/**
 A convenience interface to the AirID firmware updates server, and the primary mean of interacting with it.
 
 Firmware updater allows to check for updates, and install updates on connected AirID devices.
 ...
 */
public class FirmwareUpdater {
    
    // MARK: - Configuring a Firmware Updater
    
    /**
     The delegate that receives updater events.
     */
    public var delegate: FirmwareUpdaterDelegate?
    
    /**
     Firmware updater settings.
     */
    public let config: FirmwareUpdaterConfig
    
    /**
     Reference firmware version of currently used AirID device.
     
     `referenceFirmwareVersion` is compared against the firmware version available at the updates
     server to check if update is needed.
     This property is only used in combination with `checkForUpdatesOnResume()`.
     
     Intended use-case:
     * update this property when selected device is chnaged
     * call `checkForUpdatesOnResume()` every time when the host app switches to the foreground.
     */
    public var referenceFirmwareVersion: String?
    
    /// Updater state to maintain periodic check for updates
    internal var periodicState = PeriodicUpdatesState()
    
    /// Minimalistic implementation of Sparkle for iOS
    private let shine: Shine
    
    /// Strategy for installing firmware updates on the device
    private let installer = FirmwareInstaller()
    
    // MARK: - Creating a Firmware Updater
    
    /**
     Initializes the firmware updater with a specified delegate and configuration closure.
     
     - Parameters:
        - delegate : The delegate that receives updater events.
        - configClosure: Closure which is called by init() with default configuration and
            returns user-tweaked firmware updater config.
     */
    public init(delegate: FirmwareUpdaterDelegate?, configClosure: (FirmwareUpdaterConfig) -> Void) {
        self.delegate = delegate
        
        let defaultConfig = FirmwareUpdaterConfig()
        configClosure(defaultConfig)
        defaultConfig.validate()
        self.config = defaultConfig
                
        self.shine = Shine(config)
        self.shine.delegate = self
    }        
        
    // MARK: - Checking for Updates
    
    /**
     Check for updates.
     
     On calling this function, firmware updater connects to the update server specified in
     `FirmwareUpdaterConfig.feedURL`. Firmware version available at the server is compared against
     `currentVersion` and if version at the server is newer,
     `FirmwareUpdaterDelegate.firmwareUpdater(_:onUpdateAvailableForItem:latestVersion:newVersion:)`
     is called.
     
     - Parameters:
       - currentVersion: Firmware version of the currently used device. e.g. `device.firmwareVersion`
     */
    public func checkForUpdates(currentVersion: String) {
        os_log("Check for firmware updates was triggered by the user. Reference firmware version %{public}@",
               log: UpdaterLog, type: .info, currentVersion)
        shine.checkForUpdates(currentVersion: currentVersion, forceNotify: true)
    }
    
    /**    
     Emulates periodic check for updates.
     
     Call this method on `UIApplication.NSNotification.Name.UIApplicationDidBecomeActive` and it
     will emulate periodic check for updates. If time since the last check is greater than
     `FirmwareUpdaterConfig.updateCheckInterval`, behavior of this call would be similar to
     `checkForUpdates(currentVersion:)`.
     
     `checkForUpdatesOnResume()` uses `referenceFirmwareVersion` to determine if the update server
     has the newer version. Therefore, `referenceFirmwareVersion` **must** be set before calling this
     function.
     
     Intended use-case:
     * set `referenceFirmwareVersion` on application start and keep it updated when selected device chnaged
     * call `checkForUpdatesOnResume()` every time when the host app switches to the foreground.
     */
    public func checkForUpdatesOnResume() {
        if let currentVersion = referenceFirmwareVersion {
            os_log("Periodic check for updates was fired. Reference firmware version %{public}@",
                   log: UpdaterLog, type: .debug, currentVersion)
            shine.appDidResume(currentVersion: currentVersion)
        }
        else {
            self.delegate?.firmwareUpdater(self,
                error: UpdaterError.apiMisuse("`referenceFirmwareVersion` must be set before calling `checkForUpdatesOnResume()`"))
        }
    }
    
    // MARK: - Installing updates on AirID device
    
    /**
     Download and update firmware of the connected AirID device.
     
     This function download firmware from the location specified in the `item`, checks signature,
     and extracts it into `FirmwareUpdaterConfig.updateDownloadLocation`. Downloaded firmware
     then installed on the `device`. The `device` must be in "initialized" state.
     
     - Parameters:
       - device: The device to update firmware.
       - withItem: Update item returned by `FirmwareUpdaterDelegate.firmwareUpdater(_, onUpdateAvailableForItem:, latestVersion:, newVersion:)`
     */
    public func updateFirmwareOf(_ device: AIDDevice, withItem item: UpdateItem) {
        os_log("User initiated firmware update for %@ to %{public}@ from %{public}@.",
               log: UpdaterLog, type: .info,
               device, item.version, item.appURL.path)
        self.downloadAndVerifyUpdate(item: item) { firmwareBundlePath in
            self.updateFirmwareOf(device, firmwareBundlePath: firmwareBundlePath)
        }
    }
    
    /**
     Update firmware of the connected AirID device.
     
     This method checks signature of the firmware at `firmwareBundlePath`. If signature is valid,
     firmware is extracted into `FirmwareUpdaterConfig.updateDownloadLocation`, and installed
     on the `device`. The `device` must be in "initialized" state.
     
     This varian of firmware update can be coupled with an alternative firmware delivery channels
     (without using `checkForUpdates()`).
     
     - Parameters:
       - device: The device to update firmware.
       - firmwareBundlePath: Path to the signed firmware bundle.
     */
    public func updateFirmwareOf(_ device: AIDDevice, firmwareBundlePath: URL) {
        os_log("User initiated firmware update for %{public}@ from local bundle %{public}@.",
               log: UpdaterLog, type: .info,
               device, firmwareBundlePath.path)
        var lastReportedProgress = 0
        let progressReportStep = 5
        self.installer.onFlashProgress = { device, progress in
            if (Int(progress*100) - lastReportedProgress >= progressReportStep) {
                lastReportedProgress = Int(progress*100)
                os_log("Flashing %@. %0.2f complete.",
                       log: UpdaterLog, type: .info, device, progress)
            }
            self.delegate?.firmwareUpdater(self, onFlashProgress: progress, forDevice: device)
        }
        self.installer.onDidSwitchToBootloader = {device in
            os_log("Firmware flashing complete for %@. The device reboot with the new firmware.",
                   log: UpdaterLog, type: .info, device)
            self.delegate?.firmwareUpdater(self, onDidSwitchToBootloaderForDevice: device)
        }
        do {
            try self.installer.installFirmware(firmwareBundlePath, onDevice: device)
        }
        catch {
            let updaterError = error as? UpdaterError ?? UpdaterError.osError(error)
            os_log("Failed to install firmware %{public}@ on %@. %{public}@",
                   log: UpdaterLog, type: .error,
                   firmwareBundlePath.path, device, updaterError.errorDescription ?? "Unknown error.")
            return self.reportError(updaterError)
        }
    }
    
    // TODO: Add function to install specific version of the firmware from data buffer.
}

// Internal API

extension FirmwareUpdater {
    
    func downloadAndVerifyUpdate(item: UpdateItem, completion: @escaping (URL)->()) {
        let downloadTargetPath = self.cachePathForItem(item)
        self.delegate?.firmwareUpdater(self, onDownloadDidStartForItem: item)
        
        self.downloadUpdate(item: item, to: downloadTargetPath) { (location, error) in
            guard let updateFileLocation = location else {
                os_log("Unable to download firmware update from %{public}@ to %{public}@. %{public}@",
                       log: UpdaterLog, type: .error,
                       item.appURL.path, downloadTargetPath.path, error!.errorDescription ?? "Unknown error.")
                return self.reportError(error!)
            }
            
            os_log("The update was successfully downloaded to %@.",
                   log: UpdaterLog, type: .info, updateFileLocation.path)
            
            self.delegate?.firmwareUpdater(self, onDownloadDidFinishForItem: item)
            
            do {
                try self.checkSignature(updateFileLocation: updateFileLocation, itemAppSignature: item.appSignature)
            }
            catch {
                try? FileManager.default.removeItem(at: updateFileLocation)
                
                let updaterError = error as? UpdaterError ?? UpdaterError.osError(error)
                os_log("Failed to verify signature on %{public}@. %{public}@",
                       log: UpdaterLog, type: .error,
                       downloadTargetPath.path, updaterError.errorDescription ?? "Unknown error.")
                return self.reportError(updaterError)
            }
            
            os_log("Signature on %@ is valid.",
                   log: UpdaterLog, type: .info, updateFileLocation.path)
            
            self.delegate?.firmwareUpdater(self, onSignatureDidVerifyForItem: item)
            
            completion(updateFileLocation)
        }
    }
    
    func downloadUpdate(item: UpdateItem, to downloadTargetPath:URL, completion: @escaping ((URL?, UpdaterError?) -> Void)) {
        // Remove previous with the same name if it exists. We should avoid the situation
        // when download fails, but old version is flashed.
        try? FileManager.default.removeItem(at: downloadTargetPath)
        
        let downloadTask = URLSession.shared.downloadTask(with: item.appURL) { (location, response, error) in
            guard error == nil else {
                completion(nil, UpdaterError.serverError(error!.localizedDescription))
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                guard httpResponse.statusCode == 200 else {
                    completion(nil, UpdaterError.serverError("Request failed with status code \(httpResponse.statusCode)"))
                    return
                }
            }
            
            if let downloadTmpPath = location {
                do {
                    try FileManager.default.copyItem(at: downloadTmpPath, to: downloadTargetPath)
                    completion(downloadTargetPath, nil)
                }
                catch {
                    completion(nil, UpdaterError.fileOperationFailed(error.localizedDescription))
                }
            }
        }
        downloadTask.resume()
    }
    
    func checkSignature(updateFileLocation: URL, itemAppSignature: String) throws {
        guard let firmwareBlob = try? Data(contentsOf: updateFileLocation) else {
            throw UpdaterError.updateNotFoundInTheCache(location: updateFileLocation.path)
        }
        
        guard let signature = Data(base64Encoded: itemAppSignature) else {
            throw UpdaterError.wrongSignature("Wrong signature format.")
        }
        
        guard let publicKeyString = self.config.publicEDKey, let publicKeyData = Data(base64Encoded: publicKeyString) else {
            throw UpdaterError.wrongSignature(self.config.publicEDKey == nil ? "Public key not found." : "Wrong encoding of public key.")
        }
        
        guard let signatureVerifier = try? SignatureVerifier(edPublicKeyData: publicKeyData) else {
            throw UpdaterError.wrongSignature("Wrong format of public key.")
        }
        
        guard (signatureVerifier.verifySignature(signature, for: firmwareBlob) == true) else {
            throw UpdaterError.wrongSignature("Signature is invalid.")
        }
    }
    
    func cachePathForItem(_ item: UpdateItem) -> URL {
        var dst = self.config.updateDownloadLocation
        dst.appendPathComponent(item.appURL.lastPathComponent)
        return dst
    }
    
    func reportError(_ error: UpdaterError) {
        self.delegate?.firmwareUpdater(self, error: error)
    }
}

extension FirmwareUpdater: ShineDelegate {
    func updateFailedWithError(_ error: Error) {
        os_log("Check for firmware updates failed. %{public}@ .",
               log: UpdaterLog, type: .error, error.localizedDescription)
        let updaterError = UpdaterError.serverError(error.localizedDescription)
        self.delegate?.firmwareUpdater(self, error: updaterError)
    }
    
    func updateAvailable(forItem item: UpdateItem, fromVersion oldVersion: String, toVersion newVersion: String) {
        os_log("Firmware update from %{public}@ to %{public}@ was found at the update server.",
               log: UpdaterLog, type: .info, oldVersion, newVersion)
        self.delegate?.firmwareUpdater(self, onUpdateAvailableForItem: item, latestVersion: oldVersion, newVersion: newVersion)
    }
    
    func updateNotAvailable(currentVersion: String) {
        os_log("Firmware update was not found. %{public}@ is the latest version available.",
               log: UpdaterLog, type: .info, currentVersion)
        self.delegate?.firmwareUpdater(self, runningLatestVersion: currentVersion)
    }
}

// @optional
extension FirmwareUpdaterDelegate {
    func firmwareUpdater(_ firmwareUpdater: FirmwareUpdater,  onUpdateAvailableForItem: UpdateItem, latestVersion: String, newVersion: String) {}
    func firmwareUpdater(_ firmwareUpdater: FirmwareUpdater,  runningLatestVersion: String) {}
    func firmwareUpdater(_ firmwareUpdater: FirmwareUpdater, onDownloadDidStartForItem: UpdateItem) {}
    func firmwareUpdater(_ firmwareUpdater: FirmwareUpdater, onDownloadDidFinishForItem: UpdateItem) {}
    func firmwareUpdater(_ firmwareUpdater: FirmwareUpdater, onSignatureDidVerifyForItem: UpdateItem) {}
    func firmwareUpdater(_ firmwareUpdater: FirmwareUpdater, onFlashProgress: Float, forDevice: AIDDevice) {}
    func firmwareUpdater(_ firmwareUpdater: FirmwareUpdater, onDidSwitchToBootloaderForDevice: AIDDevice) {}
    func firmwareUpdater(_ firmwareUpdater: FirmwareUpdater, error: UpdaterError) {}
}
