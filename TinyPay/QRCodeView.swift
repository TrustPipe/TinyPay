//
//  QRCodeView.swift
//  TinyPay
//
//  Created by Harold on 2025/9/18.
//

import SwiftUI
import CryptoKit

struct QRCodeView: View {
    @AppStorage("unusedIndex") private var unusedIndex: Int = 998  // The first available index is the one before tail
    @AppStorage("payer_addr") private var payerAddr: String = ""
    @State private var hashDict: [Int: String] = [:]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if hashDict.isEmpty {
                    Text("Pleas setup your OTP root")
                        .foregroundColor(.secondary)
                } else if payerAddr.isEmpty {
                    Text("Please setup your Payer Address")
                        .foregroundColor(.secondary)
                } else {
                    if let currentHash = hashDict[unusedIndex] {
                        let qrCodeContent = generateQRCodeContent(payerAddr: payerAddr, hash: currentHash)
                        
                        Text("Index: \(unusedIndex)")
                            .font(.headline)
                        
                        if let qrImage = generateQRCode(from: qrCodeContent) {
                            Image(uiImage: qrImage)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 250, height: 250)
                        }
                        
                        Button("Refresh QR Code") {
                            refreshQRCode()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(unusedIndex <= 0)
                        
                        // Dev only 显示当前二维码的数据
                        VStack(spacing: 10) {                            
                            VStack(spacing: 5) {
                                Text("Payer Address:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(payerAddr)
                                    .font(.system(.caption2, design: .monospaced))
                                    .padding(8)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(6)
                                    .textSelection(.enabled)
                            }
                            
                            VStack(spacing: 5) {
                                Text("Hash Value:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(currentHash)
                                    .font(.system(.caption2, design: .monospaced))
                                    .padding(8)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(6)
                                    .textSelection(.enabled)
                            }
                        }
                        
                        if unusedIndex <= 0 {
                            Text("All Hash used")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    } else {
                        Text("Hash not found for index \(unusedIndex)")
                            .foregroundColor(.red)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("QR Code")
            .onAppear {
                loadHashDict()
            }
        }
    }
    
    private func refreshQRCode() {
        if unusedIndex > 0 {
            unusedIndex -= 1
            // 只发送更新后的index到手表，不需要重新发送整个hashDict
            WatchConnectivityManager.shared.sendUnusedIndex(unusedIndex)
        }
    }
    
    private func loadHashDict() {
        guard let data = UserDefaults.standard.data(forKey: "indexHashMap"),
              let stringKeyDict = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            return
        }
        
        hashDict = Dictionary(uniqueKeysWithValues: stringKeyDict.compactMap {
            guard let intKey = Int($0.key) else { return nil }
            return (intKey, $0.value)
        })
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let data = Data(string.utf8)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)
            
            if let output = filter.outputImage?.transformed(by: transform) {
                let context = CIContext()
                if let cgImage = context.createCGImage(output, from: output.extent) {
                    return UIImage(cgImage: cgImage)
                }
            }
        }
        
        return nil
    }
    
    private func generateQRCodeContent(payerAddr: String, hash: String) -> String {
        return "addr:\(payerAddr) opt:0x\(hash)"
    }
    
    private func calculateSHA256(of string: String) -> String {
        let data = Data(string.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

#Preview {
    QRCodeView()
}
