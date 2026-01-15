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
            HomeView()
                .tabItem {
                    Label(LocalizedStrings.tabHome, systemImage: "house.fill")
                }
            
            EarnView()
                .tabItem {
                    Label(LocalizedStrings.tabEarn, systemImage: "chart.line.uptrend.xyaxis")
                }
            
            ContactView()
                .tabItem {
                    Label(LocalizedStrings.tabContact, systemImage: "heart.circle.fill")
                }
            
            MeView()
                .tabItem {
                    Label(LocalizedStrings.tabMe, systemImage: "person.fill")
                }
        }
    }
}

#Preview {
    ContentView()
}
