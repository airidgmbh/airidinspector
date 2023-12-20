// SPDX-License-Identifier: MIT
//
//  LogsView.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 13/09/2022.
//

import SwiftUI

struct APDUTestsView: View {
    @ObservedObject var viewModel: APDUTestsViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack {
                APDUSourcePicker(viewModel: viewModel)
                
                if viewModel.source != nil  {
                    Spacer().frame(height: 20)
                    ForEach(viewModel.operations) { operation in
                        APDUTestItemView(operation: operation)
                    }
                }
            }
        }
    }
}

struct APDUTestsView_Previews: PreviewProvider {
    static var previews: some View {
        APDUTestsView(viewModel: .init(device: MockedDevice.mocked()))
    }
}
