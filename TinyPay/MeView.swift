//
//  MeView.swift
//  TinyPay
//
//  Created by Harold on 2025/12/4.
//

import SwiftUI
import CryptoKit

struct MeView: View {
    @ObservedObject private var walletManager = WalletManager.shared
    @AppStorage("root") private var root: String = ""
    @AppStorage("unusedIndex") private var unusedIndex: Int = 998
    @AppStorage("app_language") private var appLanguage: String = "en"
    @State private var hashDict: [Int: String] = [:]
    @State private var calculationDone = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Profile Header
                    VStack(spacing: 15) {
                        Circle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                            )
                        
                        if !walletManager.currentAddress.isEmpty {
                            VStack(spacing: 5) {
                                Text(walletManager.currentAddress.prefix(12) + "..." + walletManager.currentAddress.suffix(6))
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.secondary)
                                
                                Button(action: {
                                    UIPasteboard.general.string = walletManager.currentAddress
                                }) {
                                    HStack(spacing: 5) {
                                        Image(systemName: "doc.on.doc")
                                        Text(LocalizedStrings.copy)
                                    }
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .background(Color.gray.opacity(0.05))
                    
                    // Settings List
                    VStack(spacing: 0) {
                        // Account Settings
                        SettingsSection(title: LocalizedStrings.accountSettings) {
                            NavigationLink(destination: WalletManagementView()) {
                                SettingsRow(
                                    icon: "wallet.pass.fill",
                                    iconColor: .blue,
                                    title: "Wallet Management" // Updated from Address
                                )
                            }
                            
                            NavigationLink(destination: OTPSettingsView()) {
                                SettingsRow(
                                    icon: "lock.shield.fill",
                                    iconColor: .green,
                                    title: LocalizedStrings.otpGeneration
                                )
                            }
                        }
                        
                        // General Settings
                        SettingsSection(title: LocalizedStrings.generalSettings) {
                            NavigationLink(destination: LanguageSettingsView()) {
                                SettingsRow(
                                    icon: "globe",
                                    iconColor: .orange,
                                    title: LocalizedStrings.language,
                                    value: appLanguage == "zh" ? "中文" : "English"
                                )
                            }
                            
                            NavigationLink(destination: Text("Notification Settings")) {
                                SettingsRow(
                                    icon: "bell.fill",
                                    iconColor: .red,
                                    title: LocalizedStrings.notifications
                                )
                            }
                            
                            NavigationLink(destination: Text("Security Settings")) {
                                SettingsRow(
                                    icon: "shield.fill",
                                    iconColor: .purple,
                                    title: LocalizedStrings.security
                                )
                            }
                        }
                        
                        // About
                        SettingsSection(title: LocalizedStrings.about) {
                            NavigationLink(destination: HelpView()) {
                                SettingsRow(
                                    icon: "questionmark.circle.fill",
                                    iconColor: .blue,
                                    title: LocalizedStrings.help
                                )
                            }
                            
                            SettingsRow(
                                icon: "info.circle.fill",
                                iconColor: .gray,
                                title: LocalizedStrings.version,
                                value: "1.0.0"
                            )
                        }
                        
                        // Sync to Watch
                        if calculationDone && !hashDict.isEmpty {
                            Button(action: syncToWatch) {
                                HStack {
                                    Image(systemName: "applewatch")
                                        .foregroundColor(.blue)
                                    Text(LocalizedStrings.syncToWatch)
                                        .foregroundColor(.blue)
                                    Spacer()
                                }
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle(LocalizedStrings.tabMe)
            .onAppear {
                loadHashDict()
            }
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
        
        calculationDone = !hashDict.isEmpty
    }
    
    private func syncToWatch() {
        if !hashDict.isEmpty {
            WatchConnectivityManager.shared.sendDataToWatch(hashDict: hashDict, unusedIndex: unusedIndex, payerAddr: walletManager.currentAddress)
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 20)
            .padding(.bottom, 8)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color.white)
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var value: String?
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(iconColor)
                .cornerRadius(8)
            
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            if let value = value {
                Text(value)
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
    }
}

struct WalletManagementView: View {
    @ObservedObject private var walletManager = WalletManager.shared
    @State private var showingPrivateKey = false
    @State private var inputPrivateKey = ""
    @State private var showCopiedToast = false
    
    var body: some View {
        Form {
            // Section 1: Current Account Info
            Section(header: Text("Current Account")) {
                if !walletManager.currentAddress.isEmpty {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(LocalizedStrings.currentAddress)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(walletManager.currentAddress)
                            .font(.system(.subheadline, design: .monospaced))
                            .textSelection(.enabled)
                    }
                    .padding(.vertical, 4)
                    
                    if let privateKey = walletManager.getPrivateKey() {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text("Private Key")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button(action: {
                                    showingPrivateKey.toggle()
                                }) {
                                    Image(systemName: showingPrivateKey ? "eye.slash" : "eye")
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            if showingPrivateKey {
                                Text(privateKey)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.red)
                                    .textSelection(.enabled)
                                
                                Button(action: {
                                    UIPasteboard.general.string = privateKey
                                    showCopiedToast = true
                                }) {
                                    Label(LocalizedStrings.copy, systemImage: "doc.on.doc")
                                        .font(.caption)
                                }
                            } else {
                                Text("••••••••••••••••••••••••••••••••")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    } else {
                         Text("Private Key not saved (Address Only Mode)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                } else {
                    Text(LocalizedStrings.noAddressSet)
                        .foregroundColor(.secondary)
                }
            }
            
            // Section 2: Import / Set Private Key
            Section(header: Text("Import Account")) {
                SecureField("Enter Private Key (Hex)", text: $inputPrivateKey)
                    .font(.system(.body, design: .monospaced))
                
                Button("Import Private Key") {
                    if !inputPrivateKey.isEmpty {
                        walletManager.saveWallet(privateKey: inputPrivateKey)
                        inputPrivateKey = ""
                    }
                }
                .disabled(inputPrivateKey.count != 64)
            }
            
            // Section 3: Generate
            Section {
                Button(action: {
                    let newWallet = walletManager.generateWallet()
                    walletManager.saveWallet(privateKey: newWallet.privateKey)
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Generate New Mantle Account")
                    }
                    .foregroundColor(.blue)
                }
            }
            
            if !walletManager.currentAddress.isEmpty {
                Section {
                    Button(role: .destructive, action: {
                       walletManager.deleteWallet()
                    }) {
                        Text("Remove Account")
                    }
                }
            }
        }
        .navigationTitle("Wallet Management")
        .alert("Copied!", isPresented: $showCopiedToast) {
            Button("OK", role: .cancel) { }
        }
    }
}

// Old AddressSettingsView kept just in case, but unused now
struct AddressSettingsView: View {
    @Binding var currentAddress: String
    @State private var inputAddress = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section(header: Text(LocalizedStrings.currentAddress)) {
                if !currentAddress.isEmpty {
                    Text(currentAddress)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                } else {
                    Text(LocalizedStrings.noAddressSet)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text(LocalizedStrings.newAddress)) {
                TextField(LocalizedStrings.enterAddress, text: $inputAddress)
                    .font(.system(.body, design: .monospaced))
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                Button(LocalizedStrings.save) {
                    if !inputAddress.isEmpty {
                        currentAddress = inputAddress
                        dismiss()
                    }
                }
                .disabled(inputAddress.isEmpty)
            }
        }
        .navigationTitle(LocalizedStrings.address)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            inputAddress = currentAddress
        }
    }
}

// OTP Settings View
struct OTPSettingsView: View {
    @AppStorage("root") private var root: String = ""
    @AppStorage("currentAddress") private var currentAddress = ""
    @AppStorage("unusedIndex") private var unusedIndex: Int = 998
    @State private var inputRoot: String = ""
    @State private var isCalculating = false
    @State private var calculationDone = false
    @State private var hashDict: [Int: String] = [:]
    
    var body: some View {
        Form {
            Section(header: Text(LocalizedStrings.otpRoot)) {
                TextField(LocalizedStrings.enterOTPRoot, text: $inputRoot)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                Button(LocalizedStrings.startCalculation) {
                    if !inputRoot.isEmpty {
                        root = inputRoot
                        startCalculation()
                    }
                }
                .disabled(isCalculating || inputRoot.isEmpty)
            }
            
            if isCalculating {
                Section {
                    HStack {
                        ProgressView()
                        Text(LocalizedStrings.calculating)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if calculationDone, let finalHash = hashDict[999] {
                Section(header: Text(LocalizedStrings.otpTail)) {
                    Text(finalHash)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                    
                    Button(LocalizedStrings.copy) {
                        UIPasteboard.general.string = finalHash
                    }
                    
                    Text("\(LocalizedStrings.nextAvailable): \(LocalizedStrings.index) \(unusedIndex)")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .navigationTitle(LocalizedStrings.otpGeneration)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadExistingData()
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
                
                WatchConnectivityManager.shared.sendDataToWatch(
                    hashDict: dict,
                    unusedIndex: self.unusedIndex,
                    payerAddr: self.currentAddress
                )
            }
        }
    }
    
    private func calculateHashes(root: String) -> [Int: String] {
        var dict: [Int: String] = [:]
        var currentString = root
        
        for i in 0..<1000 {
            let data = Data(currentString.utf8)
            let hash = SHA256.hash(data: data)
            let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
            
            dict[i] = hashString
            currentString = hashString
        }
        
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
}

// Language Settings View
struct LanguageSettingsView: View {
    @AppStorage("appLanguage") private var appLanguage: String = "english"
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            Button(action: {
                appLanguage = "english"
                dismiss()
            }) {
                HStack {
                    Text("English")
                    Spacer()
                    if appLanguage == "english" {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
            }
            .foregroundColor(.primary)
            
            Button(action: {
                appLanguage = "chinese"
                dismiss()
            }) {
                HStack {
                    Text("中文")
                    Spacer()
                    if appLanguage == "chinese" {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
            }
            .foregroundColor(.primary)
        }
        .navigationTitle(LocalizedStrings.language)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    MeView()
}
