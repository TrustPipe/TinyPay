//
//  TinyPayApp.swift
//  TinyPay
//
//  Created by Harold on 2025/9/18.
//

import SwiftUI

@main
struct AptosEveryWhereApp: App {
    init() {
        // 初始化WatchConnectivity
        _ = WatchConnectivityManager.shared
        print("iOS WatchConnectivity initialized")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
