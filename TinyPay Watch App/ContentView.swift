//
//  ContentView.swift
//  TinyPay Watch App
//
//  Created by Harold on 2025/9/18.
//

import SwiftUI
import QRCode

struct ContentView: View {
    @AppStorage("unusedIndex") private var unusedIndex: Int = 998
    @AppStorage("payer_addr") private var payerAddr: String = ""
    @State private var hashDict: [Int: String] = [:]
    
    var body: some View {
        GeometryReader { geometry in
            if hashDict.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "wifi.slash")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Text("Waiting for data sync...")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if payerAddr.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                        .font(.title2)
                        .foregroundColor(.orange)
                    
                    Text("Waiting for address sync...")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let currentHash = hashDict[unusedIndex] {
                VStack(spacing: 0) {
                    // Top area: fixed height and stick to top
                    Text("Index: \(unusedIndex)")
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Color.black)
                    
                    // Middle area: auto expand
                    Spacer(minLength: 2)
                    if let qrCode = generateQRCode(from: generateQRCodeContent(payerAddr: payerAddr, hash: currentHash)) {
                        Image(uiImage: qrCode)
                            .interpolation(.none)
                            .resizable()
                            .aspectRatio(1, contentMode: .fit)
                            .padding(.horizontal, 4)
                            .padding(.bottom, 4) // Add bottom spacing to keep distance from button top edge
                    }
                    Spacer(minLength: 0) // Reduce minimum space to make button closer to bottom
                    
                    // Bottom area: stick to bottom
                    ZStack(alignment: .bottom) { // Use ZStack to ensure bottom alignment
                        Rectangle() // Create a rectangle as button background
                            .fill(Color.clear)
                            .frame(height: 36) // Increase height to include button and its internal padding
                            .edgesIgnoringSafeArea(.bottom) // Ensure extends to screen bottom
                                    
                        Button("Refresh") {
                            if unusedIndex > 0 {
                                unusedIndex -= 1
                                WatchConnectivityManager.shared.sendUnusedIndex(unusedIndex)
                            }
                        }
                        .buttonStyle(.plain) // Use plain style to maintain control
                        .font(.caption2) // Explicitly set font size
                        .foregroundColor(.white) // White text more visible
                        .padding(.vertical, 6) // Increase vertical padding
                        .padding(.horizontal, 18) // Increase horizontal padding
                        .background(Color.orange.opacity(0.8)) // More vivid orange background
                        .cornerRadius(16) // Larger corner radius
                        .overlay( // Add border to make button more prominent
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.orange, lineWidth: 1)
                        )
                        .disabled(unusedIndex <= 0)
                        .frame(maxWidth: 240) // Slightly wider
                        .padding(.bottom, 2)
                        // .buttonStyle(.plain) // Use plain style to remove built-in large margins
                        // .foregroundColor(.blue)
                        // .padding(.bottom, 4) // Use much smaller custom padding
                        // .background(Color.blue.opacity(0.2))
                        // .cornerRadius(4)
                        // .disabled(unusedIndex <= 0)
                        // .scaleEffect(1.2) // Scale entire button
                        // .frame(height: 20) // Fixed height
                        // .frame(maxWidth: 80) // Smaller maximum width
                    }
                }
                .edgesIgnoringSafeArea(.all)
            } else {
                Text("No hash data for current index")
                    .font(.caption)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            // Initialize WatchConnectivity
            _ = WatchConnectivityManager.shared
            print("Watch app opened - checking for data")
            loadHashDict()
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("DataUpdated"))) { _ in
            print("Watch UI received data update notification")
            loadHashDict()
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("IndexUpdated"))) { _ in
            print("Watch UI received index update notification")
            // unusedIndex will update automatically because @AppStorage is used
        }
    }
    
    func loadHashDict() {
        guard let data = UserDefaults.standard.data(forKey: "indexHashMap"),
              let stringKeyDict = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            return
        }
        
        hashDict = Dictionary(uniqueKeysWithValues: stringKeyDict.compactMap {
            guard let intKey = Int($0.key) else { return nil }
            return (intKey, $0.value)
        })
    }
    
    func generateQRCodeContent(payerAddr: String, hash: String) -> String {
        return "addr:\(payerAddr) otp:0x\(hash)"
    }
    
    func generateQRCode(from string: String) -> UIImage? {
        do {
            let doc = try QRCode.Document(utf8String: string)
            
            // Set style
            doc.design.backgroundColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
            doc.design.foregroundColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
            
            // Higher resolution size, suitable for watch screen scanning
            let generated = try doc.uiImage(dimension: 300)
            return generated
        } catch {
            print("QR Code generation failed: \(error)")
            return nil
        }
    }
}

#Preview {
    ContentView()
}
