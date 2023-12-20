// SPDX-License-Identifier: MIT
//
//  DeviceView.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 13/09/2022.
//

import SwiftUI

struct DeviceView: View {
    
    @ObservedObject var viewModel: DeviceViewModel
    
    var body: some View {
        BackgroundView {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(viewModel.name)
                        .bold()
                        .foregroundColor(.accentColor)
                        .font(.headline)
                    Text(viewModel.signalStrength.name)
                        .foregroundColor(viewModel.signalStrength.color)
                        .font(.footnote)
                    Text(viewModel.status.description)
                        .foregroundColor(viewModel.status.color)
                        .font(.footnote)
                }
                
                Spacer()
            }
        }
    }
}

struct DeviceView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceView(viewModel: DeviceViewModel(device: MockedDevice.mocked()))
    }
}
