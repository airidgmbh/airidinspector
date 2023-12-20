// SPDX-License-Identifier: MIT
//
//  ContentView.swift
//  AirIDDemo
//
//  Created by Viktor Krykun on 05.02.21.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("Hello, world!")
            .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension Color {
    static var secondaryBackground: Color {
        Color(uiColor: UIColor.tertiarySystemBackground)
    }
}
