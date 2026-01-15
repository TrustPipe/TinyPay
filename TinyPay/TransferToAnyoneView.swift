import SwiftUI

struct TransferToAnyoneView: View {
    @Environment(\.dismiss) var dismiss
    var onSuccess: (String) -> Void
    @State private var recipientAddress = ""
    @State private var showingScanner = false
    @State private var navigateToInput = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                Spacer()
                
                Image(systemName: "paperplane.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.themePurple)
                
                Text(LocalizedStrings.transferToAnyone)
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Address Input
                VStack(alignment: .leading, spacing: 10) {
                    Text(LocalizedStrings.recipientAddress)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        TextField(LocalizedStrings.enterAddress, text: $recipientAddress)
                            .font(.system(.body, design: .monospaced))
                            .autocapitalization(.none)
                        
                        if !recipientAddress.isEmpty {
                            Button(action: { recipientAddress = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(16)
                    
                    HStack(spacing: 15) {
                        Button(action: {
                            if let pasteString = UIPasteboard.general.string {
                                recipientAddress = pasteString
                            }
                        }) {
                            Label(LocalizedStrings.pasteAddress, systemImage: "doc.on.clipboard")
                                .font(.caption)
                                .padding(8)
                                .background(Color.themePurple.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        Button(action: {
                            showingScanner = true
                        }) {
                            Label(LocalizedStrings.scanAddressQR, systemImage: "qrcode.viewfinder")
                                .font(.caption)
                                .padding(8)
                                .background(Color.themePurple.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
                
                NavigationLink(destination: TransactionInputView(
                    title: LocalizedStrings.sendPayment,
                    recipients: [],
                    recipientAddress: recipientAddress,
                    actionType: "send",
                    onSuccess: onSuccess,
                    onRootDismiss: { dismiss() }
                ), isActive: $navigateToInput) {
                    EmptyView()
                }
                
                // Next Button
                Button(action: {
                    navigateToInput = true
                }) {
                    Text(LocalizedStrings.continueAction)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.themePurple)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                .disabled(recipientAddress.count < 5)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle(LocalizedStrings.quickTransfer)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStrings.close) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingScanner) {
                AddressScannerView { scannedAddress in
                    recipientAddress = scannedAddress
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
        }
    }
}
