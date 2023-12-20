// SPDX-License-Identifier: MIT
//
//  DeviceDetailsView.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 13/09/2022.
//

import Foundation
import SwiftUI
import Combine

struct DeviceDetailsView: View {
    @ObservedObject var viewModel: DeviceViewModel
    @ObservedObject var operationsViewModel: APDUTestsViewModel
    
    var body: some View {
        ScrollView {
            VStack {
                BackgroundView {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(viewModel.name)
                                .font(.title2)
                                .bold()
                                .foregroundColor(.accentColor)
                            Text(viewModel.signalStrength.name)
                                .foregroundColor(viewModel.signalStrength.color)
                                .font(.subheadline)
                            Text(viewModel.status.description)
                                .foregroundColor(viewModel.status.color)
                            Text(viewModel.cardStatus.name)
                                .font(.footnote)
                        }
                        Spacer()
                        if viewModel.status.isConnected {
                            disconnectButton
                        } else {
                            connectButton
                        }
                    }
                }
                
                if let updateManager = FirmwareUpdateManager.shared {
                    DeviceUpdateView(updater: updateManager)
                }
                
                APDUTestsView(viewModel: operationsViewModel)
            }.errorAlert(error: $viewModel.error)
        }
    }
    
    var connectButton: some View {
        Button {
            self.viewModel.connect()
        } label: {
            Image(systemName: "iphone.and.arrow.forward")
                .font(.body.bold())
        }
        .controlSize(.large)
        .buttonStyle(.borderedProminent)
        .disabled(viewModel.status.isConnected)
    }
    
    var disconnectButton: some View {
        Button {
            self.viewModel.disconnect()
        } label: {
            Image(systemName: "iphone.slash")
                .font(.body.bold())
        }
        .tint(.red)
        .controlSize(.large)
        .buttonStyle(.borderedProminent)
        .disabled(!viewModel.status.isConnected)
    }
}

struct DevicesDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceDetailsView(viewModel: .init(device: MockedDevice.mocked()), operationsViewModel: .init(device: MockedDevice.mocked()))
    }
}
