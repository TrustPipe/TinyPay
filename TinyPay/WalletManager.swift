//
//  WalletManager.swift
//  TinyPay
//
//  Created by Harold on 2026/1/15.
//

import Foundation
import web3 // Dependency: https://github.com/ArgentLabs/web3.swift
import BigInt
import CryptoKit // Add CryptoKit import

class WalletManager: ObservableObject {
    static let shared = WalletManager()
    
    @Published var currentAddress: String = ""
    private let keychainKey = "com.tinypay.privateKey"
    
    init() {
        loadWallet()
    }
    
    func generateWallet() -> (privateKey: String, address: String) {
        // Generate a random 32-byte private key
        var bytes = [UInt8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard status == errSecSuccess else { return ("", "") }
        
        let privateKeyHex = bytes.map { String(format: "%02x", $0) }.joined()
        let address = deriveAddress(from: privateKeyHex)
        
        return (privateKeyHex, address)
    }
    
    func saveWallet(privateKey: String) {
        // Normalize hex string (remove 0x)
        let cleanKey = privateKey.hasPrefix("0x") ? String(privateKey.dropFirst(2)) : privateKey
        
        // Validate length
        guard cleanKey.count == 64 && cleanKey.allSatisfy({ $0.isHexDigit }) else { return }
        
        UserDefaults.standard.set(cleanKey, forKey: keychainKey)
        
        let address = deriveAddress(from: cleanKey)
        UserDefaults.standard.set(address, forKey: "currentAddress")
        
        self.currentAddress = address
    }
    
    func loadWallet() {
        if let pk = UserDefaults.standard.string(forKey: keychainKey) {
            self.currentAddress = deriveAddress(from: pk)
        } else if let legacyAddr = UserDefaults.standard.string(forKey: "currentAddress"), !legacyAddr.isEmpty {
            self.currentAddress = legacyAddr
        }
    }
    
    func getPrivateKey() -> String? {
        return UserDefaults.standard.string(forKey: keychainKey)
    }
    
    func deleteWallet() {
        UserDefaults.standard.removeObject(forKey: keychainKey)
        UserDefaults.standard.removeObject(forKey: "currentAddress")
        self.currentAddress = ""
    }
    
    // MARK: - Transaction
    
    func sendTransaction(to recipient: String, amount: String, token: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let privateKey = getPrivateKey() else {
            completion(.failure(NSError(domain: "WalletManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Wallet not found"])))
            return
        }
        
        // Use .sepolia as a placeholder network, but we will override the chainId in the transaction.
        // Mantle Sepolia Chain ID is 5003.
        let client = EthereumHttpClient(url: URL(string: "https://mantle-sepolia.drpc.org")!, network: .sepolia)
        
        // Remove 0x if present
        let cleanKey = privateKey.hasPrefix("0x") ? String(privateKey.dropFirst(2)) : privateKey
        guard let keyData = Data(hex: cleanKey) else {
            completion(.failure(NSError(domain: "WalletManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid private key"])))
            return
        }
        
        Task {
            do {
                let storage = InMemoryKeyStorage(privateKey: keyData)
                let account = try EthereumAccount(keyStorage: storage)
                let toAddress = EthereumAddress(recipient)
                
                guard let amountValue = Double(amount) else {
                    completion(.failure(NSError(domain: "WalletManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid amount"])))
                    return
                }
                
                // Prepare Transaction Data
                var txTo: EthereumAddress
                var txValue: BigUInt
                var txData: Data
                
                if token == "MNT" {
                    txTo = toAddress
                    txValue = BigUInt(amountValue * 1e18)
                    txData = Data()
                } else { // USDT
                    // TODO: Replace with actual Mantle Sepolia USDT Contract Address
                    let usdtContractAddress = EthereumAddress("0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef")
                    txTo = usdtContractAddress
                    // Function call value is 0 ETH
                    txValue = BigUInt(0)
                    
                    let tokenAmount = BigUInt(amountValue * 1e6)
                    let function = ERC20Transfer(
                        contract: usdtContractAddress,
                        from: account.address,
                        to: toAddress,
                        value: tokenAmount
                    )
                    
                    let tempTx = try function.transaction()
                    txData = tempTx.data ?? Data()
                }
                
                // Fetch Network State
                async let nonceAsync = client.eth_getTransactionCount(address: account.address, block: .Latest)
                async let gasPriceAsync = client.eth_gasPrice()
                
                let nonce = try await nonceAsync
                let gasPrice = try await gasPriceAsync
                
                // Estimate Gas
                let estimateTx = EthereumTransaction(
                    from: account.address,
                    to: txTo,
                    value: txValue,
                    data: txData,
                    nonce: nonce,
                    gasPrice: gasPrice,
                    gasLimit: nil,
                    chainId: 5003
                )
                
                let gasLimit = try await client.eth_estimateGas(estimateTx)
                
                // Build Final Transaction
                let finalTx = EthereumTransaction(
                    from: account.address,
                    to: txTo,
                    value: txValue,
                    data: txData,
                    nonce: nonce,
                    gasPrice: gasPrice,
                    gasLimit: gasLimit,
                    chainId: 5003
                )
                
                let txHash = try await client.eth_sendRawTransaction(finalTx, withAccount: account)
                completion(.success(txHash))
                
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func estimateGasFee(to recipient: String, amount: String, token: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Reuse similar logic to prepare transaction and estimate gas
        guard let privateKey = getPrivateKey() else {
            completion(.failure(NSError(domain: "WalletManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Wallet not found"])))
            return
        }
        
        let client = EthereumHttpClient(url: URL(string: "https://mantle-sepolia.drpc.org")!, network: .sepolia)
        
        let cleanKey = privateKey.hasPrefix("0x") ? String(privateKey.dropFirst(2)) : privateKey
        guard let keyData = Data(hex: cleanKey) else {
            completion(.failure(NSError(domain: "WalletManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid private key"])))
            return
        }
        
        Task {
            do {
                let storage = InMemoryKeyStorage(privateKey: keyData)
                let account = try EthereumAccount(keyStorage: storage)
                let toAddress = EthereumAddress(recipient)
                
                guard let amountValue = Double(amount) else {
                    completion(.failure(NSError(domain: "WalletManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid amount"])))
                    return
                }
                
                // Prepare Transaction Data
                var txTo: EthereumAddress
                var txValue: BigUInt
                var txData: Data
                
                if token == "MNT" {
                    txTo = toAddress
                    txValue = BigUInt(amountValue * 1e18)
                    txData = Data()
                } else { // USDT
                    let usdtContractAddress = EthereumAddress("0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef")
                    txTo = usdtContractAddress
                    txValue = BigUInt(0)
                    let tokenAmount = BigUInt(amountValue * 1e6)
                    let function = ERC20Transfer(
                        contract: usdtContractAddress,
                        from: account.address,
                        to: toAddress,
                        value: tokenAmount
                    )
                    let tempTx = try function.transaction()
                    txData = tempTx.data ?? Data()
                }
                
                // Fetch Gas Price
                let gasPrice = try await client.eth_gasPrice()
                
                // Estimate Gas
                let estimateTx = EthereumTransaction(
                    from: account.address,
                    to: txTo,
                    value: txValue,
                    data: txData,
                    nonce: nil, // nullable for estimation
                    gasPrice: gasPrice,
                    gasLimit: nil,
                    chainId: 5003
                )
                
                let gasLimit = try await client.eth_estimateGas(estimateTx)
                
                // Calculate Fee in Ether (MNT)
                let feeWei = gasLimit * gasPrice
                let feeEth = Double(feeWei) / 1e18
                
                completion(.success(String(format: "%.6f MNT", feeEth)))
                
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Contract Interactions
    
    func depositToContract(amount: String, otp: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let privateKey = getPrivateKey() else {
            completion(.failure(NSError(domain: "WalletManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Wallet not found"])))
            return
        }
        
        let client = EthereumHttpClient(url: URL(string: "https://mantle-sepolia.drpc.org")!, network: .sepolia)
        
        let cleanKey = privateKey.hasPrefix("0x") ? String(privateKey.dropFirst(2)) : privateKey
        guard let keyData = Data(hex: cleanKey) else {
            completion(.failure(NSError(domain: "WalletManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid private key"])))
            return
        }
        
        Task {
            do {
                let storage = InMemoryKeyStorage(privateKey: keyData)
                let account = try EthereumAccount(keyStorage: storage)
                
                guard let amountValue = Double(amount) else {
                    completion(.failure(NSError(domain: "WalletManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid amount"])))
                    return
                }
                
                // Calculate Tail (1000x SHA256 of OTP)
                guard let otpData = otp.data(using: .utf8) else {
                    completion(.failure(NSError(domain: "WalletManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid OTP"])))
                    return
                }
                
                var tail = otpData
                for _ in 0..<1000 {
                    let hash = SHA256.hash(data: tail)
                    tail = Data(hash)
                }
                
                // Contract Details
                let contractAddress = EthereumAddress("0x6bb3f5f08b5042ec9e2f898f26254596b3985bb2")
                let nativeToken = EthereumAddress("0x0000000000000000000000000000000000000000")
                let weiAmount = BigUInt(amountValue * 1e18)
                
                let function = ContractDeposit(
                    contract: contractAddress,
                    token: nativeToken,
                    amount: weiAmount,
                    tail: tail
                )
                
                // Transaction setup
                let tempTx = try function.transaction()
                
                var transaction = EthereumTransaction(
                    from: account.address,
                    to: contractAddress,
                    value: weiAmount,
                    data: tempTx.data ?? Data(),
                    nonce: try await client.eth_getTransactionCount(address: account.address, block: .Latest),
                    gasPrice: try await client.eth_gasPrice(),
                    gasLimit: nil,
                    chainId: 5003
                )
                
                // Estimate gas
                let gasLimit = try await client.eth_estimateGas(transaction)
                
                // Re-create transaction with correct gas limit
                transaction = EthereumTransaction(
                    from: account.address,
                    to: contractAddress,
                    value: weiAmount,
                    data: tempTx.data ?? Data(),
                    nonce: transaction.nonce,
                    gasPrice: transaction.gasPrice,
                    gasLimit: gasLimit,
                    chainId: 5003
                )
                
                // Send
                let txHash = try await client.eth_sendRawTransaction(transaction, withAccount: account)
                completion(.success(txHash))
                
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func getOfflineBalance(completion: @escaping (Result<String, Error>) -> Void) {
        let client = EthereumHttpClient(url: URL(string: "https://mantle-sepolia.drpc.org")!, network: .sepolia)
        
        // Use current address or user's address
        guard let currentAddrStr = UserDefaults.standard.string(forKey: "currentAddress"), !currentAddrStr.isEmpty else {
            completion(.success("0.0000"))
            return
        }
        
        Task {
            do {
                let contractAddress = EthereumAddress("0x6bb3f5f08b5042ec9e2f898f26254596b3985bb2")
                let userAddress = EthereumAddress(currentAddrStr)
                let nativeToken = EthereumAddress("0x0000000000000000000000000000000000000000")
                
                let function = ContractGetBalance(
                    contract: contractAddress,
                    user: userAddress,
                    token: nativeToken
                )
                
                let transaction = try function.transaction()
                
                // eth_call
                let data = try await client.eth_call(transaction, resolution: .noOffchain(failOnExecutionError: true))
                
                // Decode output (uint256)
                if let balanceWei = BigUInt(hex: data) {
                    let balanceEth = Double(balanceWei) / 1e18
                    completion(.success(String(format: "%.4f", balanceEth)))
                } else {
                    // Try decoding using ABI decoder if simple hex init fails
                    // ABIFunctionDecoder is cleaner but manual BigUInt init often works for single return
                    // Let's assume standard 32 bytes return
                    completion(.success("0.0000"))
                }
            } catch {
                // If call fails (e.g. invalid opcode or revert), return 0 or error
                print("Get offline balance error: \(error)")
                completion(.failure(error))
            }
        }
    }

    // MARK: - Helper
    
    private func deriveAddress(from privateKey: String) -> String {
        // Use web3.swift for correct Ethereum address derivation (Keccak256 + Secp256k1)
        do {
            let cleanKey = privateKey.hasPrefix("0x") ? String(privateKey.dropFirst(2)) : privateKey
            guard let data = Data(hex: cleanKey) else { return "" }
             
            // Initialize account with the existing private key using a temporary storage
            let storage = InMemoryKeyStorage(privateKey: data)
            let account = try EthereumAccount(keyStorage: storage)
            return account.address.asString()
        } catch {
            print("Error deriving address: \(error)")
            return ""
        }
    }
}

// Minimal implementation of EthereumSingleKeyStorageProtocol
class InMemoryKeyStorage: EthereumSingleKeyStorageProtocol {
    private var privateKey: Data
    
    init(privateKey: Data) {
        self.privateKey = privateKey
    }
    
    func storePrivateKey(key: Data) throws {
        self.privateKey = key
    }
    
    func loadPrivateKey() throws -> Data {
        return privateKey
    }
}

extension Data {
    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        var i = hexString.startIndex
        for _ in 0..<len {
            let j = hexString.index(i, offsetBy: 2)
            let bytes = hexString[i..<j]
            if let num = UInt8(bytes, radix: 16) {
                data.append(num)
            } else {
                return nil
            }
            i = j
        }
        self = data
    }
}

// ERC20 Transfer ABI
struct ERC20Transfer: ABIFunction {
    static let name = "transfer"
    let gasPrice: BigUInt? = nil
    let gasLimit: BigUInt? = nil
    var contract: EthereumAddress
    let from: EthereumAddress?
    let to: EthereumAddress
    let value: BigUInt

    init(contract: EthereumAddress,
         from: EthereumAddress? = nil,
         to: EthereumAddress,
         value: BigUInt) {
        self.contract = contract
        self.from = from
        self.to = to
        self.value = value
    }

    func encode(to encoder: ABIFunctionEncoder) throws {
        try encoder.encode(to)
        try encoder.encode(value)
    }
}

// ABI Structs

struct ContractDeposit: ABIFunction {
    static let name = "deposit"
    let gasPrice: BigUInt? = nil
    let gasLimit: BigUInt? = nil
    var contract: EthereumAddress
    let from: EthereumAddress? = nil
    
    let token: EthereumAddress
    let amount: BigUInt
    let tail: Data
    
    init(contract: EthereumAddress, token: EthereumAddress, amount: BigUInt, tail: Data) {
        self.contract = contract
        self.token = token
        self.amount = amount
        self.tail = tail
    }
    
    func encode(to encoder: ABIFunctionEncoder) throws {
        try encoder.encode(token)
        try encoder.encode(amount)
        try encoder.encode(tail)
    }
}

struct ContractGetBalance: ABIFunction {
    static let name = "getBalance"
    let gasPrice: BigUInt? = nil
    let gasLimit: BigUInt? = nil
    var contract: EthereumAddress
    let from: EthereumAddress? = nil
    
    let user: EthereumAddress
    let token: EthereumAddress
    
    init(contract: EthereumAddress, user: EthereumAddress, token: EthereumAddress) {
        self.contract = contract
        self.user = user
        self.token = token
    }
    
    func encode(to encoder: ABIFunctionEncoder) throws {
        try encoder.encode(user)
        try encoder.encode(token)
    }
}
