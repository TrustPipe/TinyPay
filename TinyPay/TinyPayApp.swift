//
//  TinyPayApp.swift
//  TinyPay
//
//  Created by Harold on 2025/9/18.
//

import SwiftUI

@main
struct PayEveryWhereApp: App {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome: Bool = false
    
    init() {
        // Init WatchConnectivity
        _ = WatchConnectivityManager.shared
        print("iOS WatchConnectivity initialized")
    }
    
    var body: some Scene {
        WindowGroup {
            MainAppView(hasSeenWelcome: $hasSeenWelcome)
        }
    }
}

struct MainAppView: View {
    @Binding var hasSeenWelcome: Bool
    @State private var showWelcome = false
    
    var body: some View {
        ContentView()
            .sheet(isPresented: $showWelcome) {
                WelcomeView(showWelcome: $showWelcome)
            }
            .onAppear {
                if !hasSeenWelcome {
                    showWelcome = true
                }
            }
    }
}
