// SPDX-License-Identifier: MIT
//
//  APDUSourcePicker.swift
//  AirIDDemo
//
//  Created by Hussein AlRyalat on 16/09/2022.
//

import SwiftUI

struct APDUSourcePicker: View {
    enum APDURunType: String, Identifiable, CaseIterable {
        case once
        case threeTimes
        case fiveTimes
        case tenTimes
        
        var id: String {
            return "\(runsCount)"
        }
        
        var runsCount: Int {
            switch self {
            case .once:
                return 1
            case .threeTimes:
                return 3
            case .fiveTimes:
                return 5
            case .tenTimes:
                return 10
            }
        }
        
        var name: String {
            return "Run \(runsCount) Times"
        }
    }
    
    @ObservedObject var viewModel: APDUTestsViewModel
    
    var body: some View {
        if self.viewModel.source == nil {
            BackgroundView {
                FilePicker(types: [.text]) { urls in
                    guard let url = urls.first else { return }
                    self.viewModel.source = APDUTestSourceFile(url: url)
                } label: {
                    Label("Pick APDU Tests File", systemImage: "tray.and.arrow.down")
                }
            }
        } else {
            BackgroundView {
                HStack {
                    Label("\(viewModel.operations.count) APDUs", systemImage: "filemenu.and.selection")
                        .font(.body.bold())
                    Spacer()
                    HStack {
                        optionsButtonView
                        runButtonView
                    }
                    .fixedSize(horizontal: true, vertical: true)
                    .frame(maxHeight: 100)
                }
            }
        }
    }
    
    var runButtonView: some View {
        Menu {
            ForEach(APDURunType.allCases) { option in
                Button {
                    self.viewModel.start(count: option.runsCount)
                } label: {
                    Text(option.name)
                }
            }
        } label: {
            Image(systemName: "play.fill")
        } primaryAction: {
            self.viewModel.start()
        }
        .controlSize(.large)
        .buttonStyle(.borderedProminent)
        .disabled(viewModel.isOperationsRunning)
    }
    
    var optionsButtonView: some View {
        Menu {
            Button("Export Test") {
                // export the test
            }
            
            Button("Delete Test", role: .destructive) {
                self.viewModel.source = nil
            }
        } label: {
            Image(systemName: "ellipsis")
        }
        .controlSize(.large)
        .buttonStyle(.bordered)
        .disabled(viewModel.isOperationsRunning)
    }
}
struct APDUSourcePicker_Previews: PreviewProvider {
    static var previews: some View {
        APDUSourcePicker(viewModel: .init(device: MockedDevice.mocked()))
    }
}
