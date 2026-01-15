//
//  ChainService.swift
//  TinyPay
//
//  Created by Harold on 2026/1/15.
//

import Foundation

class ChainService {
    static let shared = ChainService()
    private let rpcURL = URL(string: "https://mantle-sepolia.drpc.org")!
    private let explorerAPI = "https://api-sepolia.mantlescan.xyz/api"
    
    struct RPCRequest: Codable {
        let jsonrpc: String
        let method: String
        let params: [String]
        let id: Int
    }
    
    struct RPCResponse: Codable {
        let jsonrpc: String
        let id: Int
        let result: String?
    }
    
    struct ExplorerResponse: Codable {
        let status: String
        let message: String
        let result: [ExplorerTransaction]
    }
    
    struct ExplorerTransaction: Codable {
        let hash: String
        let from: String
        let to: String
        let value: String
        let timeStamp: String
        let isError: String
    }
    
    func getTransactions(address: String, completion: @escaping (Result<[ExplorerTransaction], Error>) -> Void) {
        var components = URLComponents(string: explorerAPI)!
        components.queryItems = [
            URLQueryItem(name: "module", value: "account"),
            URLQueryItem(name: "action", value: "txlist"),
            URLQueryItem(name: "address", value: address)
        ]
        
        guard let url = components.url else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(ExplorerResponse.self, from: data)
                if response.status == "1" {
                    completion(.success(response.result))
                } else if response.message == "No transactions found" {
                    completion(.success([]))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: response.message])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func getBalance(address: String, completion: @escaping (Result<String, Error>) -> Void) {
        let requestBody = RPCRequest(
            jsonrpc: "2.0",
            method: "eth_getBalance",
            params: [address, "latest"],
            id: 1
        )
        
        var request = URLRequest(url: rpcURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }
            
            do {
                let rpcResponse = try JSONDecoder().decode(RPCResponse.self, from: data)
                if let hexBalance = rpcResponse.result {
                    let balanceInWei = self.hexToDouble(hex: hexBalance)
                    let balanceInEth = balanceInWei / 1e18
                    completion(.success(String(format: "%.4f", balanceInEth)))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func hexToDouble(hex: String) -> Double {
        let cleanHex = hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex
        var result: Double = 0
        for char in cleanHex {
            if let digit = Int(String(char), radix: 16) {
                result = result * 16 + Double(digit)
            }
        }
        return result
    }
}
