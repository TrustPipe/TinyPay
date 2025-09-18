//
//  TinyPayApp.swift
//  TinyPay Watch App
//
//  Created by Harold on 2025/9/18.
//

import SwiftUI

@main
struct AptosEveryWhere_Watch_AppApp: App {
    init() {
        // 初始化WatchConnectivity
        _ = WatchConnectivityManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
