//
//  ContactView.swift
//  TinyPay
//
//  Created by Harold on 2025/12/4.
//

import SwiftUI

struct Contact: Identifiable, Codable {
    var id = UUID()
    var name: String
    var address: String
    var note: String
}

struct ContactView: View {
    enum SelectionMode {
        case single
        case multiple
    }
    
    @AppStorage("contacts") private var contactsData = Data()
    @State private var contacts: [Contact] = [
        Contact(name: "Harold", address: "0x8c89c11e9aac1181be992136fdd561cc07f6911c", note: "Me"),
        Contact(name: "Togo", address: "0xEBcddFf6ECD3c3Ddc542a5DCB109ADd04b1eB7e9", note: "Friend"),
        Contact(name: "Lucian", address: "0xeE768232Ca197889610aC8f1B3307c74d39d0008", note: "Gym"),
    ]
    @State private var showingAddContact = false

    @State private var searchText = ""
    @State private var selectionMode: SelectionMode = .single
    @State private var selectedContacts: Set<UUID> = []
    @State private var showingActionPicker = false
    @State private var selectedContact: Contact?
    
    // Toast State
    @State private var showToast = false
    @State private var toastMessage = ""
    
    var filteredContacts: [Contact] {
        if searchText.isEmpty {
            return contacts
        } else {
            return contacts.filter { contact in
                contact.name.localizedCaseInsensitiveContains(searchText) ||
                contact.address.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {

                
                // Section 2: Contacts
                Section {
                    if contacts.isEmpty {
                        // Empty State handled by optional overlay or empty section footer
                        Text(LocalizedStrings.noContacts)
                            .foregroundColor(.secondary)
                    } else if filteredContacts.isEmpty {
                        Text("No results found")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(filteredContacts) { contact in
                            ContactRowView(
                                contact: contact,
                                selectionMode: selectionMode,
                                isSelected: selectedContacts.contains(contact.id)
                            ) {
                                handleContactTap(contact)
                            }
                            .simultaneousGesture(LongPressGesture().onEnded { _ in
                                if selectionMode == .single {
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                    withAnimation {
                                        selectionMode = .multiple
                                        selectedContacts.insert(contact.id)
                                    }
                                }
                            })
                        }
                        .onDelete(perform: delete)
                    }
                } header: {
                    if !contacts.isEmpty {
                        Text(LocalizedStrings.myFriends)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
            .navigationTitle(LocalizedStrings.tabContact)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 15) {
                        Button(action: {
                            withAnimation {
                                selectionMode = selectionMode == .single ? .multiple : .single
                                selectedContacts.removeAll()
                            }
                        }) {
                            Text(selectionMode == .single ? "Select" : "Done")
                                .foregroundColor(.themePurple)
                        }
                        
                        if selectionMode == .single {
                            Button(action: {
                                showingAddContact = true
                            }) {
                                Image(systemName: "plus")
                            }
                        }
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if selectionMode == .multiple && !selectedContacts.isEmpty {
                    Button(action: {
                        showingActionPicker = true
                    }) {
                        HStack {
                            Text(LocalizedStrings.continueAction)
                                .fontWeight(.semibold)
                            Text("(\(selectedContacts.count))")
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.themePurple)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                    .background(
                        LinearGradient(colors: [Color(UIColor.systemBackground).opacity(0), Color(UIColor.systemBackground)], startPoint: .top, endPoint: .bottom)
                            .frame(height: 100)
                    )
                }
            }
            .sheet(isPresented: $showingAddContact) {
                AddContactView { newContact in
                    contacts.append(newContact)
                    saveContacts()
                }
            }

            .sheet(item: $selectedContact) { contact in
                SingleContactActionPicker(contact: contact, onSuccess: { message in
                    showToast(message: message)
                }, onUpdate: { updatedContact in
                    if let index = contacts.firstIndex(where: { $0.id == updatedContact.id }) {
                        contacts[index] = updatedContact
                        saveContacts()
                    }
                })
            }
            .sheet(isPresented: $showingActionPicker) {
                MultipleContactActionPicker(
                    selectedContacts: contacts.filter { selectedContacts.contains($0.id) },
                    onDismiss: {
                        showingActionPicker = false
                        selectedContacts.removeAll()
                    },
                    onSuccess: { message in
                        showToast(message: message)
                    }
                )
            }
            .overlay(
                ToastView(message: toastMessage, isPresented: $showToast)
            )
            .onAppear {
                loadContacts()
            }
        }
    }
    
    private func showToast(message: String) {
        toastMessage = message
        showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showToast = false
        }
    }
    
    private func handleContactTap(_ contact: Contact) {
        if selectionMode == .single {
            selectedContact = contact
        } else {
            if selectedContacts.contains(contact.id) {
                selectedContacts.remove(contact.id)
            } else {
                selectedContacts.insert(contact.id)
            }
        }
    }
    
    private func loadContacts() {
        if let decoded = try? JSONDecoder().decode([Contact].self, from: contactsData) {
            contacts = decoded
        }
    }
    
    private func saveContacts() {
        if let encoded = try? JSONEncoder().encode(contacts) {
            contactsData = encoded
        }
    }
    
    private func delete(at offsets: IndexSet) {
        // Since we are filtering, we need to find the actual objects to delete
        let contactsToDelete = offsets.map { filteredContacts[$0] }
        for contact in contactsToDelete {
            if let index = contacts.firstIndex(where: { $0.id == contact.id }) {
                contacts.remove(at: index)
            }
        }
        saveContacts()
    }
    
    // Deprecated direct delete
    private func deleteContact(_ contact: Contact) {
        contacts.removeAll { $0.id == contact.id }
        saveContacts()
    }
}

struct ContactRowView: View {
    let contact: Contact
    let selectionMode: ContactView.SelectionMode
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 15) {
                if selectionMode == .multiple {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .themePurple : .gray)
                }
                
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 44, height: 44) // Slightly smaller for list
                    .overlay(
                        Text(String(contact.name.prefix(1)))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(contact.address.prefix(12) + "..." + contact.address.suffix(6))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .font(.system(.caption, design: .monospaced))
                }
                
                Spacer()
                
                if selectionMode == .single {
                    // chevron provided automatically by List if not custom
                    // But since we have a Button inside, List might not add chevron automatically
                    // Actually List adds chevron if NavigationLink is used.
                    // We are using sheet, so no chevron by default. Could add one.
                }
            }
            .padding(.vertical, 4)
             // Make the whole row tappable content
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain) // Important for List behavior
    }
}

struct AddContactView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var address = ""
    @State private var note = ""
    @State private var showingScanner = false
    
    let onSave: (Contact) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(LocalizedStrings.contactInfo)) {
                    TextField(LocalizedStrings.name, text: $name)
                    
                    HStack {
                        TextField(LocalizedStrings.address, text: $address)
                            .font(.system(.body, design: .monospaced))
                        
                        Button(action: {
                            showingScanner = true
                        }) {
                            Image(systemName: "qrcode.viewfinder")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    TextField(LocalizedStrings.note + " (\(LocalizedStrings.optional))", text: $note)
                }
            }
            .navigationTitle(LocalizedStrings.addContact)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedStrings.cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStrings.save) {
                        let newContact = Contact(name: name, address: address, note: note)
                        onSave(newContact)
                        dismiss()
                    }
                    .disabled(name.isEmpty || address.isEmpty)
                }
            }
            .sheet(isPresented: $showingScanner) {
                AddressScannerView { scannedAddress in
                    address = scannedAddress
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
        }
    }
}

struct AddressScannerView: View {
    @Environment(\.dismiss) var dismiss
    let onScan: (String) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                Text(LocalizedStrings.scanAddress)
                    .font(.headline)
                    .padding()
                
                // TODO: Implement QR scanner for address
                // Reuse CameraView from ScanView
                
                Button(action: {
                    // Temporary: simulate scan
                    onScan("0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb")
                    dismiss()
                }) {
                    Text(LocalizedStrings.close)
                        .padding()
                }
            }
            .navigationTitle(LocalizedStrings.scan)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ContactDetailView: View {
    let contact: Contact
    @State private var showingPayment = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Avatar
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(String(contact.name.prefix(1)))
                                .font(.system(size: 48))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                        .padding(.top, 30)
                    
                    Text(contact.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    // Address
                    VStack(alignment: .leading, spacing: 10) {
                        Text(LocalizedStrings.address)
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text(contact.address)
                                .font(.system(.body, design: .monospaced))
                                .lineLimit(1)
                                .truncationMode(.middle)
                            
                            Button(action: {
                                UIPasteboard.general.string = contact.address
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // Note
                    if !contact.note.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(LocalizedStrings.note)
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text(contact.note)
                                .font(.body)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    
                    // Actions
                    Button(action: {
                        showingPayment = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.up.circle.fill")
                            Text(LocalizedStrings.sendPayment)
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationTitle(LocalizedStrings.contactDetail)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStrings.close) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPayment) {
                PaymentView(recipientAddress: contact.address, recipientName: contact.name)
            }
        }
    }
}

struct PaymentView: View {
    let recipientAddress: String
    let recipientName: String
    @State private var amount = ""
    @State private var isProcessing = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                Spacer()
                
                // Recipient Info
                VStack(spacing: 10) {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(String(recipientName.prefix(1)))
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                    
                    Text(recipientName)
                        .font(.headline)
                    
                    Text(recipientAddress.prefix(10) + "..." + recipientAddress.suffix(6))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .font(.system(.caption, design: .monospaced))
                }
                
                // Amount Input
                VStack(alignment: .leading, spacing: 10) {
                    Text(LocalizedStrings.amount)
                        .font(.headline)
                    
                    TextField(LocalizedStrings.enterAmount, text: $amount)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    
                    Text("USDT")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Confirm Button
                Button(action: {
                    processPayment()
                }) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "checkmark")
                            Text(LocalizedStrings.confirmPayment)
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(amount.isEmpty || isProcessing)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle(LocalizedStrings.sendPayment)
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
    
    private func processPayment() {
        isProcessing = true
        
        // TODO: Implement blockchain transaction
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isProcessing = false
            dismiss()
        }
    }
}


struct ToastView: View {
    let message: String
    @Binding var isPresented: Bool
    
    var body: some View {
        if isPresented {
            VStack {
                Spacer()
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(message)
                        .foregroundColor(.primary)
                        .fontWeight(.medium)
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(25)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                .padding(.bottom, 60)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .animation(.spring(), value: isPresented)
            .zIndex(100)
        }
    }
}

struct TransactionInputView: View {
    let title: String
    let recipients: [Contact]
    let recipientAddress: String? // For "To Anyone" or single non-contact address
    let actionType: String // "send" or "request"
    let onSuccess: (String) -> Void
    @Environment(\.dismiss) var dismiss
    
    // We bind to a parent dismiss action if provided (to close the sheet)
    var onRootDismiss: (() -> Void)?
    
    @State private var amount = ""
    @State private var note = ""
    @State private var isProcessing = false
    @State private var selectedToken = "USDT"
    @State private var estimatedGas = "---"
    
    var body: some View {
        VStack(spacing: 25) {
            // Recipient Info
            VStack(spacing: 15) {
                if !recipients.isEmpty {
                    if recipients.count == 1, let contact = recipients.first {
                        // Single Contact
                        Circle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(String(contact.name.prefix(1)))
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                        
                        Text(contact.name)
                            .font(.headline)
                        
                        Text(contact.address.prefix(8) + "..." + contact.address.suffix(6))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .font(.system(.caption, design: .monospaced))
                            
                    } else {
                        // Multiple Contacts
                        HStack(spacing: -10) {
                            ForEach(recipients.prefix(3)) { contact in
                                Circle()
                                    .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Text(String(contact.name.prefix(1)))
                                            .foregroundColor(.white)
                                            .fontWeight(.bold)
                                    )
                                    .overlay(Circle().stroke(Color(UIColor.systemBackground), lineWidth: 2))
                            }
                            if recipients.count > 3 {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Text("+\(recipients.count - 3)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.secondary)
                                    )
                                    .overlay(Circle().stroke(Color(UIColor.systemBackground), lineWidth: 2))
                            }
                        }
                        
                        Text("\(recipients.count) " + LocalizedStrings.people)
                            .font(.headline)
                    }
                } else if let address = recipientAddress {
                    // Raw Address
                    Image(systemName: "wallet.pass.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.themePurple)
                        .padding()
                        .background(Color.themePurple.opacity(0.1))
                        .clipShape(Circle())
                    
                    Text(address.prefix(12) + "..." + address.suffix(6))
                        .font(.body)
                        .font(.system(.body, design: .monospaced))
                }
            }
            .padding(.top, 20)
            
            // Amount Input
            VStack(alignment: .leading, spacing: 10) {
                Text(LocalizedStrings.amount)
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack {
                    TextField("0.00", text: $amount)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                    
                    Menu {
                        Button("USDT") { selectedToken = "USDT" }
                        Button("MNT") { selectedToken = "MNT" }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedToken)
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                Divider()
            }
            .padding(.horizontal, 30)
            
            // Note Input
            VStack(alignment: .leading, spacing: 10) {
                Text(LocalizedStrings.note)
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                TextField(LocalizedStrings.noteOptional, text: $note)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            if actionType == "send" {
                HStack {
                    Text("Gas Fee:")
                        .foregroundColor(.secondary)
                    Spacer()
                    if estimatedGas == "---" {
                        Text("---")
                            .foregroundColor(.secondary)
                    } else {
                        Text(estimatedGas)
                            .foregroundColor(.primary)
                            .fontWeight(.medium)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 5)
            }
            
            // Confirm Button
            Button(action: {
                isProcessing = true
                
                if actionType == "send" {
                    var target = recipientAddress ?? ""
                    if target.isEmpty, let first = recipients.first {
                        target = first.address
                    }
                    
                    WalletManager.shared.sendTransaction(to: target, amount: amount, token: selectedToken) { result in
                        DispatchQueue.main.async {
                            isProcessing = false
                            switch result {
                            case .success(let txHash):
                                print("TX Sent: \(txHash)")
                                onSuccess(LocalizedStrings.sent + " " + LocalizedStrings.success)
                                if let rootDismiss = onRootDismiss {
                                    rootDismiss()
                                } else {
                                    dismiss()
                                }
                            case .failure(let error):
                                print("Transaction failed: \(error.localizedDescription)")
                                // Ideally show an error alert here
                            }
                        }
                    }
                } else {
                    // Simulate Request behavior
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        isProcessing = false
                        onSuccess(LocalizedStrings.request + " " + LocalizedStrings.success)
                        if let rootDismiss = onRootDismiss {
                            rootDismiss()
                        } else {
                            dismiss()
                        }
                    }
                }
            }) {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(actionType == "send" ? LocalizedStrings.confirmSend : LocalizedStrings.confirmRequest)
                            .fontWeight(.bold)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.themePurple)
                .cornerRadius(16)
            }
            .disabled(amount.isEmpty || isProcessing)
            .padding(.horizontal, 30)
            .padding(.bottom, 20)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            hideKeyboard()
        }
        .onChange(of: amount) { _ in calculateGas() }
        .onChange(of: selectedToken) { _ in calculateGas() }
        .onAppear { calculateGas() }
        .navigationTitle(actionType == "send" ? LocalizedStrings.sendPayment : LocalizedStrings.requestPayment)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func calculateGas() {
        guard actionType == "send", !amount.isEmpty, let _ = Double(amount) else {
            estimatedGas = "---"
            return
        }
        
        var target = recipientAddress ?? ""
        if target.isEmpty, let first = recipients.first {
            target = first.address
        }
        
        // Simple debounce could be added here, but for now direct call
        WalletManager.shared.estimateGasFee(to: target, amount: amount, token: selectedToken) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let fee):
                    self.estimatedGas = fee
                case .failure:
                    self.estimatedGas = "Error"
                }
            }
        }
    }
}

// Re-using SingleContactActionPicker name but redesigning it as Contact Detail
struct SingleContactActionPicker: View {
    let contact: Contact
    let onSuccess: (String) -> Void
    let onUpdate: (Contact) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var note: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Info Section
                VStack(spacing: 20) {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 90, height: 90)
                        .overlay(
                            Text(String(contact.name.prefix(1)))
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .shadow(color: .gray.opacity(0.2), radius: 10)
                    
                    VStack(spacing: 5) {
                        Text(contact.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Button(action: {
                            UIPasteboard.general.string = contact.address
                        }) {
                            HStack(spacing: 4) {
                                Text(contact.address)
                                    .font(.system(size: 13, design: .monospaced))
                                    .multilineTextAlignment(.center)
                                Image(systemName: "doc.on.doc")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    
                    VStack(spacing: 5) {
                        Text(LocalizedStrings.note)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            TextField(LocalizedStrings.noteOptional, text: $note)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .onChange(of: note) { newValue in
                                    var updated = contact
                                    updated.note = newValue
                                    onUpdate(updated)
                                }
                            
                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                        .padding(.horizontal, 40)
                    }
                }
                .padding(.vertical, 30)
                .onAppear {
                    note = contact.note
                }
                
                Spacer()
                
                // Unified Action Buttons
                VStack(spacing: 15) {
                    NavigationLink(destination: TransactionInputView(
                        title: LocalizedStrings.sendPayment,
                        recipients: [contact],
                        recipientAddress: nil,
                        actionType: "send",
                        onSuccess: onSuccess,
                        onRootDismiss: { dismiss() }
                    )) {
                        HStack {
                            Image(systemName: "arrow.up.right")
                            Text(LocalizedStrings.send)
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.themePurple)
                        .cornerRadius(16)
                    }
                    
                    NavigationLink(destination: TransactionInputView(
                        title: LocalizedStrings.requestPayment,
                        recipients: [contact],
                        recipientAddress: nil,
                        actionType: "request",
                        onSuccess: onSuccess,
                        onRootDismiss: { dismiss() }
                    )) {
                        HStack {
                            Image(systemName: "arrow.down.left")
                            Text(LocalizedStrings.request)
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.themePurple)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.themePurple.opacity(0.1))
                        .cornerRadius(16)
                    }
                }
                .padding(30)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
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


struct MultipleContactActionPicker: View {
    let selectedContacts: [Contact]
    let onDismiss: () -> Void
    let onSuccess: (String) -> Void
    @State private var actionType: String = "send"
    
    var body: some View {
        NavigationView {
            VStack {
                // Action Type Picker
                Picker("", selection: $actionType) {
                    Text(LocalizedStrings.send).tag("send")
                    Text(LocalizedStrings.request).tag("request")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Reuse TransactionInputView logic by embedding it
                // Since TransactionInputView takes parameters, we can just switch what we show
                
                TransactionInputView(
                    title: "",
                    recipients: selectedContacts,
                    recipientAddress: nil,
                    actionType: actionType,
                    onSuccess: onSuccess,
                    onRootDismiss: onDismiss
                )
            }
            .navigationTitle(LocalizedStrings.selectedContacts)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStrings.cancel) {
                        onDismiss()
                    }
                }
            }
        }
    }
}



#Preview {
    ContactView()
}
