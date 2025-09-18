//
//  ContentView.swift
//  TinyPay
//
//  Created by Harold on 2025/9/18.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            QRCodeView()
                .tabItem {
                    Image(systemName: "qrcode")
                    Text("Show to Pay")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
    }
}

#Preview {
    ContentView()
}
