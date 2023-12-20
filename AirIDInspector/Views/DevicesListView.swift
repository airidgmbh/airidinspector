// SPDX-License-Identifier: MIT
//
//  DevicesListView.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 13/09/2022.
//

import SwiftUI

struct DevicesListView<Manager: DevicesManagerProtocol>: View {
    @ObservedObject var viewModel: DevicesListViewModel<Manager>
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack {
                    if let selectedDevice = viewModel.savedDevice {
                        Section(header: SectionLabel(text: "Saved Device")) {
                            NavigationLink(destination: DeviceDetailsView(viewModel: selectedDevice, operationsViewModel: selectedDevice.testsViewModel)) {
                                DeviceView(viewModel: selectedDevice)
                            }
                        }
                    }
                    
                    if !viewModel.connectedDevices.isEmpty {
                        Section(header: SectionLabel(text: "Connected Devices")) {
                            ForEach(viewModel.connectedDevices) { device in
                                NavigationLink(destination: DeviceDetailsView(viewModel: device, operationsViewModel: device.testsViewModel)) {
                                    DeviceView(viewModel: device)
                                }
                            }
                        }
                    }

                    
                    if !viewModel.devices.isEmpty {
                        Section(header: SectionLabel(text: "Devices")) {
                            ForEach(viewModel.devices) { device in
                                NavigationLink(destination: DeviceDetailsView(viewModel: device, operationsViewModel: device.testsViewModel)) {
                                    DeviceView(viewModel: device)
                                }
                            }
                        }
                    }
                }
            }.navigationTitle("Devices")
        }
    }
}

struct DevicesListView_Previews: PreviewProvider {
    static var previews: some View {
        DevicesListView(viewModel: .init(devicesManager: MockedDevicesManager()))
    }
}

