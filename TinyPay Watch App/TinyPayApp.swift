//
//  TinyPayApp.swift
//  TinyPay Watch App
//
//  Created by Harold on 2025/9/18.
//

import SwiftUI

@main
struct PayEveryWhere_Watch_AppApp: App {
    init() {
        // Init WatchConnectivity
        _ = WatchConnectivityManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
