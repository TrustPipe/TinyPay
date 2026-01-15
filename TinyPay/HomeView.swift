//
//  HomeView.swift
//  TinyPay
//
//  Created by Harold on 2025/12/4.
//

import SwiftUI
import Network

struct Transaction: Identifiable {
    let id = UUID()
    let type: String // "receive" or "send"
    let amount: String
    let address: String
    let date: Date
    let status: String // "completed", "pending", "failed"
    let hash: String
}

struct HomeView: View {
    @AppStorage("currentAddress") private var currentAddress = ""
    @State private var showingQRCode = false
    @State private var showingScan = false
    @State private var showingFund = false
    @State private var isContractDeposit = false
    @State private var showFundOptions = false
    @State private var balance = "0.0000"
    @State private var offlineBalance = "0.0000"
    @State private var isOnline = true
    @State private var showingTransferToAnyone = false
    @State private var showToast = false
    @State private var toastMessage = ""
    
    // Mock transaction data
    @State private var recentTransactions: [Transaction] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 30) {
                        // Split Balance Display
                        HStack(spacing: 0) {
                            VStack(alignment: .leading, spacing: 12) {
                                // Total Balance
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Account Balance")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                                        Text(balance)
                                            .font(.system(size: 24, weight: .bold, design: .rounded))
                                        Text("MNT")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Divider()
                                
                                // Offline Balance
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Text("Contract Balance")
                                        Image(systemName: "wifi.slash")
                                            .font(.caption2)
                                    }
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    
                                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                                        Text(offlineBalance)
                                            .font(.system(size: 24, weight: .bold, design: .rounded))
                                            .foregroundColor(.purple)
                                        Text("MNT")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            // Fund Button
                            Button(action: {
                                showFundOptions = true
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(.themePurple)
                                    .shadow(color: .themePurple.opacity(0.3), radius: 5, y: 3)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .gray.opacity(0.1), radius: 8)
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .actionSheet(isPresented: $showFundOptions) {
                            ActionSheet(
                                title: Text("Add Funds"),
                                message: Text("Choose where you want to deposit funds"),
                                buttons: [
                                    .default(Text("Deposit to Address")) {
                                        isContractDeposit = false
                                        showingFund = true
                                    },
                                    .default(Text("Deposit to Contract (Offline Available)")) {
                                        isContractDeposit = true
                                        showingFund = true
                                    },
                                    .cancel()
                                ]
                            )
                        }
                        
                        // Hero QR Code Actions (主打功能)
                        VStack(spacing: 15) {
                            Text(LocalizedStrings.qrPayment)
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                            
                            HStack(spacing: 15) {
                                // Show QR Code - 收款 (始终可用)
                                Button(action: {
                                    showingQRCode = true
                                }) {
                                    VStack(spacing: 15) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.themePurple.opacity(isOnline ? 0.15 : 0.25))
                                                .frame(width: 80, height: 80)
                                            
                                            Image(systemName: "qrcode")
                                                .font(.system(size: 36, weight: .medium))
                                                .foregroundColor(.themePurple)
                                        }
                                        
                                        Text(LocalizedStrings.showQRCode)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 25)
                                    .background(Color.white)
                                    .cornerRadius(16)
                                    .shadow(color: Color.themePurple.opacity(isOnline ? 0.15 : 0.25), radius: 12, y: 4)
                                    .overlay(
                                        // 离线时显示高亮边框
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.themePurple, lineWidth: isOnline ? 0 : 2)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Scan QR Code - 付款 (需要网络)
                                Button(action: {
                                    if isOnline {
                                        showingScan = true
                                    }
                                }) {
                                    VStack(spacing: 15) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.themePurple.opacity(isOnline ? 0.15 : 0.05))
                                                .frame(width: 80, height: 80)
                                            
                                            Image(systemName: "camera.viewfinder")
                                                .font(.system(size: 36, weight: .medium))
                                                .foregroundColor(isOnline ? .themePurple : .gray)
                                        }
                                        
                                        Text(LocalizedStrings.scanQRCode)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(isOnline ? .primary : .secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 25)
                                    .background(Color.white)
                                    .cornerRadius(16)
                                    .shadow(color: Color.themePurple.opacity(isOnline ? 0.15 : 0.05), radius: isOnline ? 12 : 6, y: isOnline ? 4 : 2)
                                    .opacity(isOnline ? 1 : 0.6)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(!isOnline)
                            }
                            .padding(.horizontal)
                            
                            // Quick Transfer Button (New Feature)
                            Button(action: {
                                if isOnline {
                                    showingTransferToAnyone = true
                                }
                            }) {
                                HStack(spacing: 15) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.themePurple.opacity(isOnline ? 0.15 : 0.05))
                                            .frame(width: 50, height: 50)
                                        
                                        Image(systemName: "paperplane.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(isOnline ? .themePurple : .gray)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(LocalizedStrings.transferToAnyone)
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(isOnline ? .primary : .secondary)
                                        Text(LocalizedStrings.enterOrScanAddress)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: .gray.opacity(isOnline ? 0.1 : 0.05), radius: 8)
                                .opacity(isOnline ? 1.0 : 0.6)
                            }
                            .padding(.horizontal)
                            .disabled(!isOnline)
                            
                            // Network Status Indicator
                            if !isOnline {
                                HStack(spacing: 6) {
                                    Image(systemName: "wifi.slash")
                                        .font(.system(size: 12))
                                    Text(LocalizedStrings.offlineMode)
                                        .font(.caption)
                                }
                                .foregroundColor(.orange)
                                .padding(.horizontal)
                                .padding(.top, 5)
                            }
                        }
                        
                        // Recent Transactions
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Text(LocalizedStrings.recentTransactions)
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                
                                if recentTransactions.isEmpty {
                                    Button(action: {
                                        if !currentAddress.isEmpty, let url = URL(string: "https://sepolia.mantlescan.xyz/address/\(currentAddress)") {
                                            UIApplication.shared.open(url)
                                        }
                                    }) {
                                        Text(LocalizedStrings.viewAll)
                                            .font(.subheadline)
                                            .foregroundColor(.themePurple)
                                    }
                                } else {
                                    NavigationLink(destination: TransactionHistoryView(transactions: recentTransactions)) {
                                        Text(LocalizedStrings.viewAll)
                                            .font(.subheadline)
                                            .foregroundColor(.themePurple)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
                            if recentTransactions.isEmpty {
                                if !currentAddress.isEmpty {
                                    Button(action: {
                                        if let url = URL(string: "https://sepolia.mantlescan.xyz/address/\(currentAddress)") {
                                            UIApplication.shared.open(url)
                                        }
                                    }) {
                                        HStack {
                                            Text("View on Explorer")
                                                .fontWeight(.semibold)
                                            Image(systemName: "arrow.up.right")
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.white)
                                        .foregroundColor(.themePurple)
                                        .cornerRadius(16)
                                        .shadow(color: .gray.opacity(0.1), radius: 8)
                                    }
                                    .padding(.horizontal)
                                }
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(recentTransactions.prefix(5)) { transaction in
                                        TransactionRow(transaction: transaction)
                                        if transaction.id != recentTransactions.prefix(5).last?.id {
                                            Divider()
                                                .padding(.leading, 70)
                                        }
                                    }
                                }
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: .gray.opacity(0.08), radius: 8)
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top, 5)
                    }
                    .padding(.vertical)
                }
                .background(Color(.systemGroupedBackground))
                
                ToastView(message: toastMessage, isPresented: $showToast)
            }
            .navigationTitle("TinyPay")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingTransferToAnyone) {
                TransferToAnyoneView(onSuccess: { message in
                    showToast(message: message)
                    // Refresh balance and transactions after transfer
                    fetchBalance()
                    fetchTransactions()
                })
            }
            .sheet(isPresented: $showingQRCode) {
                MyQRCodeView()
            }
            .sheet(isPresented: $showingScan) {
                ScanView()
            }
            .sheet(isPresented: $showingFund) {
                FundView(receiverAddress: currentAddress, isContractDeposit: isContractDeposit) {
                    // Refresh balance after deposit
                    fetchBalance()
                    fetchTransactions()
                }
            }
            .onAppear {
                checkNetworkStatus()
                fetchBalance()
                fetchTransactions()
            }
        }
    }
    
    private func fetchTransactions() {
        guard !currentAddress.isEmpty else {
            recentTransactions = []
            return
        }
        
        ChainService.shared.getTransactions(address: currentAddress) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let txs):
                    self.recentTransactions = txs.prefix(10).map { tx in
                        let isReceive = tx.to.lowercased() == currentAddress.lowercased()
                        let amountInWei = Double(tx.value) ?? 0
                        let amountInEth = amountInWei / 1e18
                        let date = Date(timeIntervalSince1970: TimeInterval(tx.timeStamp) ?? 0)
                        
                        return Transaction(
                            type: isReceive ? "receive" : "send",
                            amount: String(format: "%.4f", amountInEth),
                            address: isReceive ? tx.from : tx.to,
                            date: date,
                            status: tx.isError == "0" ? "completed" : "failed",
                            hash: tx.hash
                        )
                    }
                case .failure(let error):
                    print("Error fetching transactions: \(error)")
                }
            }
        }
    }
    
    private func fetchBalance() {
        guard !currentAddress.isEmpty else {
            balance = "0.0000"
            offlineBalance = "0.0000"
            return
        }
        
        // Fetch Total Balance (Layer 1)
        ChainService.shared.getBalance(address: currentAddress) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let newBalance):
                    self.balance = newBalance
                case .failure(let error):
                    print("Error fetching balance: \(error)")
                }
            }
        }
        
        // Fetch Offline Balance (Contract)
        WalletManager.shared.getOfflineBalance { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let offInfo):
                    self.offlineBalance = offInfo
                case .failure(let error):
                    print("Error fetching offline balance: \(error)")
                }
            }
        }
    }
    
    private func showToast(message: String) {
        toastMessage = message
        showToast = true
        
        // Auto hide after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showToast = false
        }
    }

    private func checkNetworkStatus() {
        // Check network connectivity
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkMonitor")
        
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.isOnline = path.status == .satisfied
            }
        }
        
        monitor.start(queue: queue)
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        Button(action: {
            // Using sepolia.mantlescan.xyz as requested by user
            if let url = URL(string: "https://sepolia.mantlescan.xyz/tx/\(transaction.hash)") {
                UIApplication.shared.open(url)
            }
        }) {
            HStack(spacing: 15) {
                // Icon
                Circle()
                    .fill(transaction.type == "receive" ? Color(red: 0.56, green: 0.31, blue: 0.85).opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 45, height: 45)
                    .overlay(
                        Image(systemName: transaction.type == "receive" ? "arrow.down" : "arrow.up")
                            .foregroundColor(transaction.type == "receive" ? Color(red: 0.56, green: 0.31, blue: 0.85) : .gray)
                            .fontWeight(.semibold)
                    )
            
                VStack(alignment: .leading, spacing: 5) {
                    Text(transaction.type == "receive" ? LocalizedStrings.received : LocalizedStrings.sent)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(transaction.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .font(.system(.caption, design: .monospaced))
                    
                    Text(formatDate(transaction.date))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 5) {
                    Text((transaction.type == "receive" ? "+" : "-") + transaction.amount)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(transaction.type == "receive" ? Color.themePurple : .primary)
                    
                    Text("MNT")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    private static let fullFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter
    }()
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return LocalizedStrings.today + " " + Self.timeFormatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return LocalizedStrings.yesterday + " " + Self.timeFormatter.string(from: date)
        } else {
            return Self.fullFormatter.string(from: date)
        }
    }
}

struct FundView: View {
    @Environment(\.dismiss) var dismiss
    let receiverAddress: String
    var isContractDeposit: Bool = false
    var onDepositSuccess: (() -> Void)? = nil
    @State private var fundAmount = ""
    @State private var otpString = ""
    @State private var isProcessing = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                Spacer()
                
                Image(systemName: isContractDeposit ? "arrow.down.to.line.circle.fill" : "plus.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.themePurple)
                
                Text(isContractDeposit ? "Deposit to Contract" : LocalizedStrings.fund)
                    .font(.title)
                    .fontWeight(.bold)
                
                if isContractDeposit {
                    Text("Funds deposited here will be available for offline payments.")
                        .font(.custom("Body", size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    if isContractDeposit {
                         Text("One Time Password (OTP)")
                            .font(.headline)
                        
                        SecureField("Enter OTP (e.g. SecretPhrase)", text: $otpString)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.bottom, 10)
                    }
                    
                    Text(LocalizedStrings.amount)
                        .font(.headline)
                    
                    TextField(LocalizedStrings.enterAmount, text: $fundAmount)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    
                    Text("MNT")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                
                Button(action: {
                    if isContractDeposit {
                        isProcessing = true
                        WalletManager.shared.depositToContract(amount: fundAmount, otp: otpString) { result in
                            DispatchQueue.main.async {
                                isProcessing = false
                                switch result {
                                case .success(let txHash):
                                    print("Contract Deposit TX: \(txHash)")
                                    onDepositSuccess?()
                                    dismiss()
                                case .failure(let error):
                                    print("Deposit failed: \(error)")
                                }
                            }
                        }
                    } else {
                        // Existing Logic for Online Deposit (MetaMask Deep Link)
                        if let amount = Double(fundAmount) {
                            let amountInWei = amount * 1e18
                            let amountString = String(format: "%.0f", amountInWei)
                            
                            // Using EIP-681 format with https wrapper
                            if let url = URL(string: "https://metamask.app.link/send/\(receiverAddress)@5003?value=\(amountString)") {
                                UIApplication.shared.open(url) { success in
                                    if !success {
                                        if let ethUrl = URL(string: "ethereum:\(receiverAddress)@5003?value=\(amountString)") {
                                             UIApplication.shared.open(ethUrl)
                                        }
                                    }
                                }
                            }
                        }
                        dismiss()
                    }
                }) {
                    HStack {
                        if isProcessing {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(isContractDeposit ? "Confirm Deposit" : LocalizedStrings.confirmFund)
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.themePurple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(fundAmount.isEmpty || (isContractDeposit && otpString.isEmpty) || isProcessing)
                .padding(.horizontal)
                
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
            .navigationTitle(LocalizedStrings.fund)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStrings.close) {
                        dismiss()
                    }
                }
            }
        }
    }
}



struct TransactionHistoryView: View {
    let transactions: [Transaction]
    
    var body: some View {
        List(transactions) { transaction in
            TransactionRow(transaction: transaction)
        }
        .listStyle(PlainListStyle())
        .navigationTitle(LocalizedStrings.transactionHistory)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    HomeView()
}
