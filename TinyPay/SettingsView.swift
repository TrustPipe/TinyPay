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
    @AppStorage("unusedIndex") private var unusedIndex: Int = 998  // The first available index is the one before tail
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
                    // Payer Address
                    VStack(spacing: 12) {
                        HStack {
                            Text("Payer Address")
                                .font(.headline)
                            Spacer()
                        }
                        
                        HStack {
                            TextField("Type your payer address here", text: $inputPayerAddr)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .focused($isPayerAddrFieldFocused)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .keyboardType(.asciiCapable)
                            
                            Button("SAVE") {
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
                                    Text("Current Address:")
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
                    
                    // Hash Calculation/OTP generation
                    VStack(spacing: 12) {
                        HStack {
                            Text("OTP generation")
                                .font(.headline)
                            Spacer()
                        }
                        
                        TextField("Please input the root of OTPs", text: $inputRoot)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($isRootFieldFocused)
                        
                        Button("Start Calculation") {
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
                        ProgressView("Calculating...")
                            .padding()
                    }
                    
                    if calculationDone, let finalHash = hashDict[999] {
                        VStack(spacing: 10) {
                            Text("The tail of the OTP list:")
                                .font(.headline)
                            
                            Text(finalHash)
                                .font(.system(.caption, design: .monospaced))
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .textSelection(.enabled)
                            
                            Button("COPY") {
                                UIPasteboard.general.string = finalHash
                            }
                            .buttonStyle(.bordered)
                            
                            Text("Next available: Index \(unusedIndex)")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal)
                    }
                    
                    if calculationDone && !hashDict.isEmpty {
                        Button("sync to watch") {
                            syncToWatch()
                        }
                        .buttonStyle(.bordered)
                        .padding(.horizontal)
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // App Info and Help
                    VStack(spacing: 15) {
                        HStack {
                            Text("App Information")
                                .font(.headline)
                            Spacer()
                        }
                        
                        VStack(spacing: 8) {
                            InfoRow(title: "Version", value: "1.0.0")
                            InfoRow(title: "Developer", value: "TrustPipe")
                            InfoRow(title: "Platform", value: "iOS & watchOS")
                        }
                        
                        NavigationLink(destination: HelpView()) {
                            HStack {
                                Image(systemName: "questionmark.circle.fill")
                                    .foregroundColor(.blue)
                                Text("User Guide")
                                    .fontWeight(.medium)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 100)
                }
            }
            .navigationTitle("Setting")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: NavigationLink(destination: HelpView()) {
                    Image(systemName: "questionmark.circle")
                        .font(.title3)
                }
            )
            .onTapGesture {
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
                self.unusedIndex = 998
                
                // Sync data to watch (background transfer, watch will receive automatically when opened)
                WatchConnectivityManager.shared.sendDataToWatch(hashDict: dict, unusedIndex: self.unusedIndex, payerAddr: self.payerAddr)
                print("Hash data, unusedIndex and PayerAddr sent to watch (background transfer)")
            }
        }
    }
    
    private func calculateHashes(root: String) -> [Int: String] {
        var dict: [Int: String] = [:]
        var currentString = root
        
        print("Cal hash link list, the root is: \(root)")
        
        for i in 0..<1000 {
            let data = Data(currentString.utf8)
            let hash = SHA256.hash(data: data)
            let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
            
            dict[i] = hashString
            currentString = hashString
        }
        
        print("Cal Done! tail(index 999) is: \(dict[999] ?? "Not found")")
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
        
        // load payer address
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
            print("Manual sync hash link list, unusedIndex and PayerAddr to iWatch")
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

#Preview {
    SettingsView()
}

