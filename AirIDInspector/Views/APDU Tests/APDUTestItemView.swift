// SPDX-License-Identifier: MIT
//
//  APDUTestItemView.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 16/09/2022.
//

import SwiftUI

struct APDUTestItemView: View {
    @ObservedObject var operation: APDUBaseOperation
    
    var body: some View {
        BackgroundView {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(operation.name)
                        .foregroundColor(.primary)
                        .font(.body.monospaced())
                        .bold()
                    Text(operation.description)
                        .font(.footnote.monospaced())
                        .foregroundColor(.gray)
                    Text(operation.state.name)
                        .foregroundColor(operation.state.color)
                        .font(.footnote.monospaced())
                        .bold()
                }
                
                Spacer()
                if operation.state.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
            }
        }
    }
}
struct APDUTestItemView_Previews: PreviewProvider {
    static var previews: some View {
        APDUTestItemView(operation: APDUTestOperation(device: MockedDevice.mocked(), data: "A1000".hexadecimal!, expectedResponse: "9000"))
    }
}

extension OperationState {
    var color: Color {
        switch self {
        case .pending: return .orange
        case .success: return .green
        case .running: return .blue
        case .failed: return .red
        }
    }
}
