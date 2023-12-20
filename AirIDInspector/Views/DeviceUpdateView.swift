// SPDX-License-Identifier: MIT
//
//  DeviceUpdateView.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 23/09/2022.
//

import SwiftUI

struct DeviceUpdateView: View {
    @ObservedObject var updater: FirmwareUpdateManager
    
    var body: some View {
        BackgroundView {
            if let status = updater.updateStatus {
                HStack {
                    if let text = text(for: status) {
                        text
                    }
                    
                    if case .readyToInstall = status {
                        Button {
                            self.updater.startUpdatingCurrentDevice()
                        } label: {
                            Image(systemName: "display.and.arrow.down")
                                .font(.body.bold())
                        }
                        .controlSize(.large)
                        .buttonStyle(.borderedProminent)
                        .disabled(updater.isLoading)
                    }
                    
                    if case .failed = status {
                        Button {
                            self.updater.startUpdatingCurrentDevice()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.body.bold())
                        }
                        .controlSize(.large)
                        .buttonStyle(.borderedProminent)
                        .disabled(updater.isLoading)
                    }
                }
            } else {
                Text("Unable to detect update")
            }
        }.onAppear {
            self.updater.checkNewerVersions()
        }
    }
    
    func text(for status: DeviceUpdateStatus) -> Text? {
        let text: Text
        
        switch status {
        case .unknown:
//           text = Text("Unknown Status, either the device isn't visible, or the cats has controlled the world")
//                .foregroundColor(.yellow)
            return nil
        case .checking:
            text = Text("Checking for update for (\(self.updater.currentVersion ?? ""))..")
                .foregroundColor(.yellow)
        case .readyToInstall:
            text = Text("Update is ready to install, tap the button to begin to install")
                .foregroundColor(.green)
        case .progressing(let progress):
            text = Text("Downloading and Installing the Update... \(String(format: "%.2f", progress))%")
        case .failed(let error):
            text = Text(error.localizedDescription)
                .foregroundColor(.red)
        case .upToDate:
            text = Text("Firmware is up to date (\(self.updater.latestVersion ?? ""))")
                .foregroundColor(.green)
        }
        
        return text.font(.body.bold())
    }
    
}
