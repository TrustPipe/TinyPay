//
//  SettingsView.swift
//  TinyPay
//
//  Created by Harold on 2025/9/18.
//

import SwiftUI
import CryptoKit

struct SettingsView: View {
    @AppStorage("root") private var root: String = ""
    @AppStorage("payer_addr") private var payerAddr: String = ""
    @AppStorage("unusedIndex") private var unusedIndex: Int = 998  // 从倒数第二个开始
    @State private var inputRoot: String = ""
    @State private var inputPayerAddr: String = ""
    @State private var isCalculating = false
    @State private var calculationDone = false
    @State private var hashDict: [Int: String] = [:]
    @FocusState private var isRootFieldFocused: Bool
    @FocusState private var isPayerAddrFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Payer Address 部分
                    VStack(spacing: 12) {
                        HStack {
                            Text("Payer Address")
                                .font(.headline)
                            Spacer()
                        }
                        
                        HStack {
                            TextField("输入或粘贴 payer address", text: $inputPayerAddr)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .focused($isPayerAddrFieldFocused)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .keyboardType(.asciiCapable)
                            
                            Button("保存") {
                                if !inputPayerAddr.isEmpty {
                                    isPayerAddrFieldFocused = false
                                    payerAddr = inputPayerAddr
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(inputPayerAddr.isEmpty)
                        }
                        
                        if !payerAddr.isEmpty {
                            VStack(spacing: 4) {
                                HStack {
                                    Text("当前地址:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                
                                Text(payerAddr)
                                    .font(.system(.caption2, design: .monospaced))
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(6)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Hash Calculation 部分
                    VStack(spacing: 12) {
                        HStack {
                            Text("Hash Calculation")
                                .font(.headline)
                            Spacer()
                        }
                        
                        TextField("输入 root 字符串", text: $inputRoot)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($isRootFieldFocused)
                        
                        Button("开始计算") {
                            if !inputRoot.isEmpty {
                                isRootFieldFocused = false
                                root = inputRoot
                                startCalculation()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isCalculating || inputRoot.isEmpty)
                    }
                    .padding(.horizontal)
                    
                    if isCalculating {
                        ProgressView("计算中...")
                            .padding()
                    }
                    
                    if calculationDone, let finalHash = hashDict[999] {
                        VStack(spacing: 10) {
                            Text("第1000次Hash结果:")
                                .font(.headline)
                            
                            Text("Index: 999 (第1000次) - 已使用")
                                .font(.caption)
                                .foregroundColor(.red)
                            
                            Text(finalHash)
                                .font(.system(.caption, design: .monospaced))
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .textSelection(.enabled)
                            
                            Button("拷贝") {
                                UIPasteboard.general.string = finalHash
                            }
                            .buttonStyle(.bordered)
                            
                            Text("下一个可用: Index \(unusedIndex)")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal)
                    }
                    
                    if calculationDone && !hashDict.isEmpty {
                        Button("同步到手表") {
                            syncToWatch()
                        }
                        .buttonStyle(.bordered)
                        .padding(.horizontal)
                    }
                    
                    // 底部间距，避免键盘遮挡
                    Spacer(minLength: 100)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .onTapGesture {
                // 点击空白区域收起键盘
                isRootFieldFocused = false
                isPayerAddrFieldFocused = false
            }
            .onAppear {
                loadExistingData()
            }
        }
    }
    
    private func startCalculation() {
        isCalculating = true
        calculationDone = false
        
        DispatchQueue.global(qos: .userInitiated).async {
            let dict = self.calculateHashes(root: self.inputRoot)
            
            DispatchQueue.main.async {
                self.hashDict = dict
                self.saveHashDict(dict)
                self.isCalculating = false
                self.calculationDone = true
                // 重置 unusedIndex 到倒数第二个，因为最后一个已经被默认使用了
                self.unusedIndex = 998
                
                // 同步数据到手表（后台传输，手表打开时会自动接收）
                WatchConnectivityManager.shared.sendDataToWatch(hashDict: dict, unusedIndex: 998, payerAddr: self.payerAddr)
                print("Hash数据、unusedIndex和PayerAddr已发送到手表（后台传输）")
            }
        }
    }
    
    private func calculateHashes(root: String) -> [Int: String] {
        var dict: [Int: String] = [:]
        var currentString = root
        
        print("开始链式计算1000次SHA256，root: \(root)")
        
        for i in 0..<1000 {
            let data = Data(currentString.utf8)
            let hash = SHA256.hash(data: data)
            let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
            
            dict[i] = hashString
            currentString = hashString  // 下一次计算使用这次的结果作为输入
            
            if i % 100 == 0 {
                print("第\(i+1)次计算: \(hashString.prefix(16))...")
            }
        }
        
        print("计算完成！第1000次hash(index 999): \(dict[999] ?? "未找到")")
        return dict
    }
    
    private func saveHashDict(_ dict: [Int: String]) {
        let stringKeyDict = Dictionary(uniqueKeysWithValues: dict.map { (String($0.key), $0.value) })
        let data = try? JSONSerialization.data(withJSONObject: stringKeyDict, options: [])
        UserDefaults.standard.set(data, forKey: "indexHashMap")
    }
    
    private func loadExistingData() {
        hashDict = loadHashDict()
        if !hashDict.isEmpty {
            calculationDone = true
        }
        
        // 加载已保存的 payer address
        inputPayerAddr = payerAddr
    }
    
    private func loadHashDict() -> [Int: String] {
        guard let data = UserDefaults.standard.data(forKey: "indexHashMap"),
              let stringKeyDict = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            return [:]
        }
        
        return Dictionary(uniqueKeysWithValues: stringKeyDict.compactMap {
            guard let intKey = Int($0.key) else { return nil }
            return (intKey, $0.value)
        })
    }
    
    private func syncToWatch() {
        if !hashDict.isEmpty {
            WatchConnectivityManager.shared.sendDataToWatch(hashDict: hashDict, unusedIndex: unusedIndex, payerAddr: payerAddr)
            print("手动同步数据、unusedIndex和PayerAddr到手表")
        }
    }
}

#Preview {
    SettingsView()
}

