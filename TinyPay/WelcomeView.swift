//
//  WelcomeView.swift
//  TinyPay
//
//  Created by Harold on 2025/9/29.
//

import SwiftUI
import CryptoKit

struct WelcomeView: View {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome: Bool = false
    @AppStorage("payer_addr") private var payerAddr: String = ""
    @Binding var showWelcome: Bool
    @State private var currentPage = 0
    // Wallet Setup State
    @State private var importPrivateKey: String = ""
    @State private var generatedMnemonic: String = "" // For future use if needed, currently just PK
    @State private var generatedPrivateKey: String = ""
    @State private var generatedAddress: String = ""
    @State private var isImporting: Bool = false
    @State private var showWalletCreationSuccess: Bool = false
    
    @FocusState private var isAnyFieldFocused: Bool
    
    let pages = [
        WelcomePage(
            title: "Welcome to TinyPay",
            subtitle: "Secure Offline Payment Wallet",
            icon: "creditcard.circle.fill",
            description: "TinyPay allows you to make secure payments even without an internet connection."
        ),
        WelcomePage(
            title: "Offline Contract",
            subtitle: "Security via Smart Contract",
            icon: "lock.shield.fill",
            description: "We deploy a Vault smart contract for you. You can deposit funds into the contract and use our OTP technology to spend them offline securely. No internet required for payment!",
            needsInput: false
        ),
        WelcomePage(
            title: "Setup Wallet",
            subtitle: "Create or Import Account",
            icon: "wallet.pass.fill",
            description: "Choose how you want to set up your wallet.",
            needsInput: true,
            inputType: .walletSetup
        ),
        WelcomePage(
            title: "Generate Payment Code",
            subtitle: "Display QR Code for Payment",
            icon: "qrcode",
            description: "Display your QR code on the main page for others to scan. You can set up your OTP secure key later in settings."
        ),
        WelcomePage(
            title: "Apple Watch Sync",
            subtitle: "Pay from your Wrist",
            icon: "applewatch",
            description: "Sync your wallet to Apple Watch for quick access to payment codes."
        )
    ]
    
    var body: some View {
        VStack {
            // Page indicators
            HStack {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.blue : Color.gray.opacity(0.5))
                        .frame(width: 8, height: 8)
                        .scaleEffect(index == currentPage ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: currentPage)
                }
            }
            .padding(.top, 20)
            
            // Page content
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    WelcomePageView(
                        page: pages[index], 
                        importPrivateKey: $importPrivateKey,
                        generatedPrivateKey: $generatedPrivateKey,
                        generatedAddress: $generatedAddress,
                        isImporting: $isImporting,
                        showWalletCreationSuccess: $showWalletCreationSuccess,
                        currentPageIndex: index,
                        isAnyFieldFocused: _isAnyFieldFocused
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Bottom buttons
            HStack {
                if currentPage > 0 {
                    Button("Previous") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage -= 1
                        }
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                if currentPage < pages.count - 1 {
                    Button("Next") {
                        // Hide keyboard
                        isAnyFieldFocused = false
                        
                        // Validation for Wallet Page (Page 2)
                        if currentPage == 2 {
                            if !validateWalletSetup() {
                                return // Alert handled in UI or simple block
                            }
                        }
                        
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    // Disable next if on wallet page and no wallet set
                    .disabled(currentPage == 2 && generatedAddress.isEmpty && importPrivateKey.isEmpty)
                } else {
                    Button("Get Started") {
                        completeSetup()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
        }
        .background(Color(.systemBackground))
    }
    
    private func validateWalletSetup() -> Bool {
        // logic to save wallet if valid
        if !importPrivateKey.isEmpty && generatedAddress.isEmpty {
            // User entered a private key manually
            WalletManager.shared.saveWallet(privateKey: importPrivateKey)
            payerAddr = WalletManager.shared.currentAddress
            return true
        } else if !generatedPrivateKey.isEmpty {
            // User generated a wallet
            WalletManager.shared.saveWallet(privateKey: generatedPrivateKey)
            payerAddr = WalletManager.shared.currentAddress
            return true
        }
        return false
    }
    
    private func completeSetup() {
        // Final save just in case
        _ = validateWalletSetup() 
        hasSeenWelcome = true
        showWelcome = false
    }
}

enum WelcomeInputType {
    case walletSetup
}

struct WelcomePage {
    let title: String
    let subtitle: String
    let icon: String
    let description: String
    let needsInput: Bool
    let inputType: WelcomeInputType?
    
    init(title: String, subtitle: String, icon: String, description: String, needsInput: Bool = false, inputType: WelcomeInputType? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.description = description
        self.needsInput = needsInput
        self.inputType = inputType
    }
}

struct WelcomePageView: View {
    let page: WelcomePage
    @Binding var importPrivateKey: String
    @Binding var generatedPrivateKey: String
    @Binding var generatedAddress: String
    @Binding var isImporting: Bool
    @Binding var showWalletCreationSuccess: Bool
    
    let currentPageIndex: Int
    @FocusState var isAnyFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .padding(.bottom, 20)
            
            VStack(spacing: 15) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .padding(.top, 10)
                
                // Wallet Setup UI
                if page.inputType == .walletSetup {
                    VStack(spacing: 20) {
                        if generatedAddress.isEmpty && !isImporting {
                            // Initial Choice
                            Button(action: {
                                let wallet = WalletManager.shared.generateWallet()
                                generatedPrivateKey = wallet.privateKey
                                generatedAddress = wallet.address
                                showWalletCreationSuccess = true
                            }) {
                                Label("Create New Account", systemImage: "plus.circle.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            
                            Button(action: {
                                withAnimation {
                                    isImporting = true
                                }
                            }) {
                                Label("I have a Private Key", systemImage: "key.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .foregroundColor(.primary)
                                    .cornerRadius(10)
                            }
                        } else if showWalletCreationSuccess {
                            // Generated Success View
                            VStack(alignment: .leading, spacing: 10) {
                                Text("New Account Created!")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                
                                Text("Address:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(generatedAddress)
                                    .font(.system(.caption, design: .monospaced))
                                    .padding(8)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                
                                Text("Private Key (SAVE THIS!):")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                Text(generatedPrivateKey)
                                    .font(.system(.caption, design: .monospaced))
                                    .padding(8)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(8)
                                    .onTapGesture {
                                        UIPasteboard.general.string = generatedPrivateKey
                                    }
                                
                                Button("Reset / Cancel") {
                                    generatedAddress = ""
                                    generatedPrivateKey = ""
                                    showWalletCreationSuccess = false
                                }
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 5)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(radius: 2)
                        } else if isImporting {
                            // Import View
                            VStack(alignment: .leading) {
                                Text("Enter Private Key")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                SecureField("0x...", text: $importPrivateKey)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .focused($isAnyFieldFocused)
                                
                                Button("Cancel") {
                                    withAnimation {
                                        isImporting = false
                                        importPrivateKey = ""
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top)
                            }
                            .padding()
                        }
                    }
                    .padding(.horizontal, 30)
                }
            }
            
            Spacer()
        }
        .padding()
        .onTapGesture {
            isAnyFieldFocused = false
        }
    }
}

#Preview {
    WelcomeView(showWelcome: .constant(true))
}
