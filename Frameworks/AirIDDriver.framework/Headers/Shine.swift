//
//  Shine.swift
//  Shine
//
//  Created by Cory Imdieke on 4/6/18.
//  Copyright © 2018 Eighty Three Creative, Inc. All rights reserved.
//

import UIKit
import os.log

protocol ShineDelegate {
    func updateAvailable(forItem: UpdateItem, fromVersion: String, toVersion: String)
    func updateNotAvailable(currentVersion: String)
    func updateFailedWithError(_ error: Error)
}

@objcMembers class Shine: NSObject {
    var config = FirmwareUpdaterConfig()
    var host = PeriodicUpdatesState()
    var delegate: ShineDelegate?
    private let backgroundQueue = DispatchQueue.init(label: "com.certgate.aid.updaterqueue")
    
    init(_ config: FirmwareUpdaterConfig) {
        self.config = config
    }
    
    func checkForUpdates(currentVersion: String, forceNotify: Bool = false) {
        self.config.validate()
        
        self.backgroundQueue.async {
            do {
                let feedXML = try Data(contentsOf: self.config.feedURL)
                let appcastParser = AppcastParser(data: feedXML)
                let items = try appcastParser.parse()
                                
                var newItem: UpdateItem? = nil
                for potentialNewItem in items {
                    if potentialNewItem.version.isNewerThanVersion(currentVersion) &&
                        potentialNewItem.version.isNewerThanVersion(newItem?.version ?? "0.0.0") {
                        newItem = potentialNewItem
                    }
                }
                
                if newItem != nil {
                    // We have an update available
                    self.notifyUserOfUpdateFrom(currentVersion, toVersion: newItem!, force: forceNotify || newItem!.forcedUpdate)
                    
                } else {
                    // No update available
                    if forceNotify {
                        self.notifyUserOfNoUpdate(latestAvailableVersion: currentVersion)
                    }
                }
                
                // Update completed and user notified, mark this time and version for the next time
                self.host.lastCheckDate = Date()
                self.host.lastCheckLatestVersion = newItem?.version ?? currentVersion
                self.host.lastCheckWasForcedUpdate = newItem?.forcedUpdate ?? false
                
            } catch let error {
                self.delegate?.updateFailedWithError(error)
                return
            }
        }
    }
    
    func appDidResume(currentVersion: String) {
        let timeSinceLastCheck = abs(self.host.lastCheckDate.timeIntervalSinceNow)
        let beenLongEnoughToCheckAgain = timeSinceLastCheck > self.config.updateCheckInterval
        
        os_log("App did resume. %d seconds passed, %d seconds between checks. (lastForced=%{bool}d  enabled=%{bool}d )",
               log: UpdaterLog, type: .debug,
               Int(timeSinceLastCheck), self.config.updateCheckInterval,
               self.host.lastCheckWasForcedUpdate, /*self.host.completedFirstCheck,*/ self.config.automaticallyChecksForUpdates)
        
        //print(Array(UserDefaults.standard.dictionaryRepresentation().keys).count)
        
        if self.host.lastCheckWasForcedUpdate || /*(self.host.completedFirstCheck &&*/ self.config.automaticallyChecksForUpdates && beenLongEnoughToCheckAgain {
            self.checkForUpdates(currentVersion: currentVersion, forceNotify: false)
        } else if !beenLongEnoughToCheckAgain {
            os_log("Too soon to check for update. %d seconds passed, %d seconds between checks.",
                    log: UpdaterLog, type: .info, Int(timeSinceLastCheck), self.config.updateCheckInterval)
        }
        
        //self.host.completedFirstCheck = true
    }
    
    private func notifyUserOfUpdateFrom(_ currentVersion: String, toVersion newVersion: UpdateItem, force: Bool) {
        // Check to see if we should notify for this version
        guard force || self.host.lastCheckLatestVersion != newVersion.version else {
            os_log("""
                Firmware update from %{public}@ to %{public}@ was found at the update server
                BUT it will not be reported. force=%{bool}d , lastCheckLatestVersion=%{public}@
                """,
                   log: UpdaterLog, type: .info,
                   currentVersion, newVersion.version, force, self.host.lastCheckLatestVersion ?? "Unknown")
            return
        }
                
        self.delegate?.updateAvailable(forItem: newVersion, fromVersion: currentVersion, toVersion: newVersion.version)
    }
    
    private func notifyUserOfNoUpdate(latestAvailableVersion: String) {
        self.delegate?.updateNotAvailable(currentVersion: latestAvailableVersion)
    }
}

fileprivate extension String {
    func isNewerThanVersion(_ v: String) -> Bool {
        do {
            return try self.versionCompare(v) == .orderedDescending
        }
        catch {
            os_log("Unexpected error during comparing firmware versions %{public}@ and %{public}@. %{public}@",
                   log: UpdaterLog, type: .info, self, v, error.localizedDescription)
            
            return false
        }
    }
}
