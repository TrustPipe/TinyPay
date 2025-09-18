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
                    
                    Text("等待数据同步...")
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
                    
                    Text("等待地址同步...")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let currentHash = hashDict[unusedIndex] {
                VStack(spacing: 0) {
                    // 顶部区域：固定高度且贴顶
                    Text("Index: \(unusedIndex)")
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Color.black)
                    
                    // 中间区域：自动扩展
                    Spacer(minLength: 2)
                    if let qrCode = generateQRCode(from: generateQRCodeContent(payerAddr: payerAddr, hash: currentHash)) {
                        Image(uiImage: qrCode)
                            .interpolation(.none)
                            .resizable()
                            .aspectRatio(1, contentMode: .fit)
                            .padding(.horizontal, 4)
                            .padding(.bottom, 4) // 增加底部间距，与按钮上边缘保持距离
                    }
                    Spacer(minLength: 0) // 减少最小空间，让按钮更贴近底部
                    
                    // 底部区域：贴底对齐
                    ZStack(alignment: .bottom) { // 使用ZStack确保底部对齐
                        Rectangle() // 创建一个矩形作为按钮背景
                            .fill(Color.clear)
                            .frame(height: 36) // 增加高度以包含按钮及其内部padding
                            .edgesIgnoringSafeArea(.bottom) // 确保延伸到屏幕底部
                                    
                        Button("refresh") {
                            if unusedIndex > 0 {
                                unusedIndex -= 1
                                WatchConnectivityManager.shared.sendUnusedIndex(unusedIndex)
                            }
                        }
                        .buttonStyle(.plain) // 使用plain样式保持控制
                        .font(.caption2) // 明确设置字体大小
                        .foregroundColor(.white) // 白色文字更明显
                        .padding(.vertical, 6) // 垂直方向增加内边距
                        .padding(.horizontal, 18) // 水平方向增加内边距
                        .background(Color.orange.opacity(0.8)) // 更鲜明的蓝色背景
                        .cornerRadius(16) // 更大的圆角
                        .overlay( // 添加边框使按钮更突出
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.orange, lineWidth: 1)
                        )
                        .disabled(unusedIndex <= 0)
                        .frame(maxWidth: 240) // 稍微宽一点
                        .padding(.bottom, 2)
                        // .buttonStyle(.plain) // 使用plain样式移除内置的大边距
                        // .foregroundColor(.blue)
                        // .padding(.bottom, 4) // 使用小得多的自定义内边距
                        // .background(Color.blue.opacity(0.2))
                        // .cornerRadius(4)
                        // .disabled(unusedIndex <= 0)
                        // .scaleEffect(1.2) // 整体缩放按钮
                        // .frame(height: 20) // 固定高度
                        // .frame(maxWidth: 80) // 较小的最大宽度
                    }
                }
                .edgesIgnoringSafeArea(.all)
            } else {
                Text("当前索引无Hash数据")
                    .font(.caption)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            // 初始化WatchConnectivity
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
            // unusedIndex会自动更新，因为使用了@AppStorage
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
        return "addr:\(payerAddr) opt:0x\(hash)"
    }
    
    func generateQRCode(from string: String) -> UIImage? {
        do {
            let doc = try QRCode.Document(utf8String: string)
            
            // 设置样式
            doc.design.backgroundColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
            doc.design.foregroundColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
            
            // 更高分辨率的尺寸，适合手表屏幕扫描
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
