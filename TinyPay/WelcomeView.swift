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
    @State private var tempPayerAddr: String = ""
    @State private var tempOTPRoot: String = ""
    @State private var isCalculating = false
    @State private var calculationDone = false
    @State private var hashDict: [Int: String] = [:]
    @FocusState private var isAnyFieldFocused: Bool
    
    let pages = [
        WelcomePage(
            title: "Welcome to TinyPay",
            subtitle: "Secure Payment App with OTP Technology",
            icon: "creditcard.circle.fill",
            description: "TinyPay helps users generate OTP for offline payments based on custom OTP-ROOT and converts them into QR codes."
        ),
        WelcomePage(
            title: "Setup Payment Address",
            subtitle: "Step 1: Configure Your Payment Address",
            icon: "location.circle.fill",
            description: "Enter your payment address below. This is the information others need when making charging from you. You can modify this address later in the Settings page.",
            needsInput: true,
            inputType: .paymentAddress
        ),
        WelcomePage(
            title: "Generate OTP Chain",
            subtitle: "Step 2: Create Security Key Chain",
            icon: "key.fill",
            description: "Enter your OTP root key below. When you click Next, the system will automatically generate 1000 consecutive secure hash values to ensure each payment is unique.",
            needsInput: true,
            inputType: .otpRoot
        ),
        WelcomePage(
            title: "Generate Payment Code",
            subtitle: "Step 3: Display QR Code for Payment",
            icon: "qrcode",
            description: "Display your QR code on the main page for others to scan and make payments. Remember to refresh for a new security code after each use."
        ),
        WelcomePage(
            title: "Apple Watch Sync",
            subtitle: "Secure Payment Anytime, Anywhere",
            icon: "applewatch",
            description: "Data automatically syncs to Apple Watch, allowing you to quickly display payment QR codes in any situation."
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
                        tempPayerAddr: $tempPayerAddr,
                        tempOTPRoot: $tempOTPRoot,
                        isCalculating: isCalculating,
                        calculationDone: calculationDone,
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
                        // Hide keyboard when moving to next page
                        isAnyFieldFocused = false
                        
                        // If we're on the OTP root page (page 2), start calculation
                        if currentPage == 2 && !tempOTPRoot.isEmpty {
                            startCalculation()
                        }
                        
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Get Started") {
                        // Save the temporary data to permanent storage
                        if !tempPayerAddr.isEmpty {
                            payerAddr = tempPayerAddr
                        }
                        if !tempOTPRoot.isEmpty {
                            UserDefaults.standard.set(tempOTPRoot, forKey: "root")
                        }
                        hasSeenWelcome = true
                        showWelcome = false
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
        }
        .background(Color(.systemBackground))
    }
    
    private func startCalculation() {
        isCalculating = true
        calculationDone = false
        
        DispatchQueue.global(qos: .userInitiated).async {
            let dict = self.calculateHashes(root: self.tempOTPRoot)
            
            DispatchQueue.main.async {
                self.hashDict = dict
                self.saveHashDict(dict)
                self.isCalculating = false
                self.calculationDone = true
                
                // Save the OTP root to permanent storage
                UserDefaults.standard.set(self.tempOTPRoot, forKey: "root")
                
                // Set unused index
                UserDefaults.standard.set(998, forKey: "unusedIndex")
                
                // Sync data to watch
                WatchConnectivityManager.shared.sendDataToWatch(hashDict: dict, unusedIndex: 998, payerAddr: self.payerAddr)
                print("Hash data calculated and sent to watch from WelcomeView")
                
                // Notify other views that data has been updated
                NotificationCenter.default.post(name: .init("HashDataUpdated"), object: nil)
            }
        }
    }
    
    private func calculateHashes(root: String) -> [Int: String] {
        var dict: [Int: String] = [:]
        var currentString = root
        
        print("Calculating hash chain from WelcomeView, root: \(root)")
        
        for i in 0..<1000 {
            let data = Data(currentString.utf8)
            let hash = SHA256.hash(data: data)
            let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
            
            dict[i] = hashString
            currentString = hashString
        }
        
        print("Calculation complete! Tail (index 999): \(dict[999] ?? "Not found")")
        return dict
    }
    
    private func saveHashDict(_ dict: [Int: String]) {
        let stringKeyDict = Dictionary(uniqueKeysWithValues: dict.map { (String($0.key), $0.value) })
        let data = try? JSONSerialization.data(withJSONObject: stringKeyDict, options: [])
        UserDefaults.standard.set(data, forKey: "indexHashMap")
    }
}

enum WelcomeInputType {
    case paymentAddress
    case otpRoot
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
    @Binding var tempPayerAddr: String
    @Binding var tempOTPRoot: String
    let isCalculating: Bool
    let calculationDone: Bool
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
                
                // Add input field based on input type
                if page.needsInput {
                    if page.inputType == .paymentAddress {
                        TextField("Enter your payment address", text: $tempPayerAddr)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($isAnyFieldFocused)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .keyboardType(.asciiCapable)
                            .padding(.horizontal, 30)
                            .padding(.top, 20)
                    } else if page.inputType == .otpRoot {
                        TextField("Enter your OTP root key", text: $tempOTPRoot)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($isAnyFieldFocused)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .keyboardType(.asciiCapable)
                            .padding(.horizontal, 30)
                            .padding(.top, 20)
                    }
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
