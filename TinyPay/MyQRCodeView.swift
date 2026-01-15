//
//  MyQRCodeView.swift
//  TinyPay
//
//  Created by Harold on 2025/12/4.
//

import SwiftUI
import CryptoKit

enum QRCodeType {
    case pay    // 付款码 (address + OTP)
    case receive // 收款码 (address + amount)
}

enum Currency: String, CaseIterable {
    case usdt = "USDT"
    case rmb = "RMB"
    case usd = "USD"
    case eur = "EUR"
    
    var symbol: String {
        switch self {
        case .usdt: return "USDT"
        case .rmb: return "¥"
        case .usd: return "$"
        case .eur: return "€"
        }
    }
}

struct MyQRCodeView: View {
    @AppStorage("currentAddress") private var currentAddress = ""
    @AppStorage("hashDictionary") private var hashDictionaryData = Data()
    @State private var qrCodeType: QRCodeType = .pay
    @State private var currentOTP = ""
    @State private var receiveAmount = ""
    @State private var selectedCurrency: Currency = .rmb
    @State private var numberOfPeople: Int = 1
    @State private var hashDictionary: [String: String] = [:]
    @Environment(\.dismiss) var dismiss
    
    // Mock exchange rate (RMB to USDT)
    private let exchangeRate: Double = 7.0
    
    private var calculatedUSDT: String {
        guard let amount = Double(receiveAmount), amount > 0 else { return "0.00" }
        let perPerson = amount / Double(numberOfPeople)
        
        switch selectedCurrency {
        case .usdt:
            return String(format: "%.2f", perPerson)
        case .rmb:
            return String(format: "%.2f", perPerson / exchangeRate)
        case .usd:
            return String(format: "%.2f", perPerson)
        case .eur:
            return String(format: "%.2f", perPerson * 1.1)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                // QR Code Type Picker
                Picker("", selection: $qrCodeType) {
                    Text(LocalizedStrings.payCode).tag(QRCodeType.pay)
                    Text(LocalizedStrings.receiveCode).tag(QRCodeType.receive)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // QR Code Display
                if let qrCodeImage = generateQRCode() {
                    Image(uiImage: qrCodeImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                        .padding()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 250, height: 250)
                        .overlay(
                            Text(LocalizedStrings.qrCodeGenerationFailed)
                                .foregroundColor(.red)
                        )
                }
                
                // QR Code Content Info
                VStack(alignment: .leading, spacing: 10) {
                    if qrCodeType == .pay {
                        HStack {
                            Text(LocalizedStrings.address + ":")
                                .foregroundColor(.secondary)
                            Text(currentAddress.prefix(10) + "..." + currentAddress.suffix(6))
                                .font(.system(.body, design: .monospaced))
                        }
                        
                        HStack {
                            Text(LocalizedStrings.currentOTP + ":")
                                .foregroundColor(.secondary)
                            Text(currentOTP)
                                .font(.system(.title2, design: .monospaced))
                                .fontWeight(.bold)
                        }
                        
                        Text(LocalizedStrings.payCodeDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 5)
                    } else {
                        VStack(spacing: 15) {
                            // Currency Selection
                            VStack(alignment: .leading, spacing: 8) {
                                Text(LocalizedStrings.billCurrency)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Picker("", selection: $selectedCurrency) {
                                    ForEach(Currency.allCases, id: \.self) { currency in
                                        Text(currency.rawValue).tag(currency)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                            
                            // Amount Input
                            VStack(alignment: .leading, spacing: 8) {
                                Text(LocalizedStrings.billAmount)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Text(selectedCurrency.symbol)
                                        .font(.title3)
                                        .foregroundColor(.secondary)
                                    TextField(LocalizedStrings.enterAmount, text: $receiveAmount)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .font(.title3)
                                }
                            }
                            
                            // Number of People
                            VStack(alignment: .leading, spacing: 8) {
                                Text(LocalizedStrings.splitBetween)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 15) {
                                    Button(action: {
                                        if numberOfPeople > 1 {
                                            numberOfPeople -= 1
                                        }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(numberOfPeople > 1 ? Color(red: 0.56, green: 0.31, blue: 0.85) : .gray)
                                    }
                                    .disabled(numberOfPeople <= 1)
                                    
                                    Text("\(numberOfPeople)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .frame(minWidth: 40)
                                    
                                    Button(action: {
                                        numberOfPeople += 1
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(Color(red: 0.56, green: 0.31, blue: 0.85))
                                    }
                                    
                                    Text(LocalizedStrings.people)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // Calculated Amount
                            if !receiveAmount.isEmpty, let amount = Double(receiveAmount), amount > 0 {
                                VStack(spacing: 5) {
                                    Divider()
                                    
                                    HStack {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(LocalizedStrings.perPerson)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            Text(calculatedUSDT + " USDT")
                                                .font(.title3)
                                                .fontWeight(.bold)
                                                .foregroundColor(Color(red: 0.56, green: 0.31, blue: 0.85))
                                        }
                                        
                                        Spacer()
                                        
                                        if selectedCurrency != .usdt {
                                            VStack(alignment: .trailing, spacing: 3) {
                                                Text(LocalizedStrings.exchangeRate)
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                Text("1 USDT ≈ " + selectedCurrency.symbol + String(format: "%.2f", exchangeRate))
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            Text(LocalizedStrings.receiveCodeDescription)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Refresh Button (for Pay Code)
                if qrCodeType == .pay {
                    Button(action: {
                        generateNewOTP()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text(LocalizedStrings.refreshOTP)
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle(LocalizedStrings.myQRCode)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStrings.close) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadHashDictionary()
                generateNewOTP()
            }
            .contentShape(Rectangle()) // Change contentShape to Rectangle so touches are detected
            .onTapGesture {
                hideKeyboard()
            }
        }
    }
    
    private func generateQRCode() -> UIImage? {
        let qrContent: String
        
        if qrCodeType == .pay {
            // 付款码: address + OTP
            qrContent = "tinypay://pay?address=\(currentAddress)&otp=\(currentOTP)"
        } else {
            // 收款码: address + amount
            let amount = receiveAmount.isEmpty ? "0" : receiveAmount
            qrContent = "tinypay://receive?address=\(currentAddress)&amount=\(amount)"
        }
        
        let data = qrContent.data(using: .ascii)
        
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        
        guard let output = filter.outputImage?.transformed(by: transform) else { return nil }
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(output, from: output.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
    
    private func loadHashDictionary() {
        if let decoded = try? JSONDecoder().decode([String: String].self, from: hashDictionaryData) {
            hashDictionary = decoded
        }
    }
    
    private func generateNewOTP() {
        if let latestHash = hashDictionary.keys.sorted().last {
            currentOTP = String(latestHash.prefix(6))
        }
    }
}

#Preview {
    MyQRCodeView()
}
