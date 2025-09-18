//
//  WatchConnectivityManager.swift
//  TinyPay Watch App
//
//  Created by Harold on 2025/9/18.
//

import WatchConnectivity
import Foundation

class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    // 发送unusedIndex到iPhone
    func sendUnusedIndex(_ index: Int) {
        do {
            try WCSession.default.updateApplicationContext(["unusedIndex": index])
            print("Watch unusedIndex \(index) sent to iPhone")
        } catch {
            print("Failed to send unusedIndex from watch: \(error)")
        }
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Watch WCSession activation: \(activationState.rawValue)")
        if let error = error {
            print("Watch WCSession error: \(error)")
        }
        
        // 连接成功后，发送当前的unusedIndex以便同步检查
        // iOS会根据大小关系决定是否需要更新
        if activationState == .activated {
            let currentIndex = UserDefaults.standard.integer(forKey: "unusedIndex")
            print("Watch session activated, sending current index: \(currentIndex)")
            sendUnusedIndex(currentIndex)
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("Watch received application context from iOS")
        
        let hasHashData = applicationContext["hashDict"] as? [String: String] != nil
        
        if let hashData = applicationContext["hashDict"] as? [String: String] {
            print("Watch received hash data with \(hashData.count) entries - this is a new root calculation")
            
            // 保存数据
            if let data = try? JSONSerialization.data(withJSONObject: hashData, options: []) {
                UserDefaults.standard.set(data, forKey: "indexHashMap")
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastSyncTimestamp")
            }
        }
        
        // 处理 payer address 数据
        if let payerAddr = applicationContext["payer_addr"] as? String {
            print("Watch received payer address: \(payerAddr)")
            UserDefaults.standard.set(payerAddr, forKey: "payer_addr")
        }
        
        if let receivedUnusedIndex = applicationContext["unusedIndex"] as? Int {
            let currentUnusedIndex = UserDefaults.standard.integer(forKey: "unusedIndex")
            print("Watch current unusedIndex: \(currentUnusedIndex), received: \(receivedUnusedIndex)")
            
            if hasHashData {
                // 如果包含hash数据，说明是重新计算root，直接接受新的index
                UserDefaults.standard.set(receivedUnusedIndex, forKey: "unusedIndex")
                print("Watch unusedIndex updated from \(currentUnusedIndex) to \(receivedUnusedIndex) (new root calculation)")
                
                // 通知UI更新
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("IndexUpdated"), object: nil)
                }
            } else {
                // 如果只是index同步，使用原来的逻辑（只有自己index更大才更新）
                if currentUnusedIndex > receivedUnusedIndex {
                    UserDefaults.standard.set(receivedUnusedIndex, forKey: "unusedIndex")
                    print("Watch unusedIndex updated from \(currentUnusedIndex) to \(receivedUnusedIndex) (Watch had larger index)")
                    
                    // 通知UI更新
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: NSNotification.Name("IndexUpdated"), object: nil)
                    }
                } else if currentUnusedIndex < receivedUnusedIndex {
                    print("Watch unusedIndex kept at \(currentUnusedIndex) (Watch had smaller index, iOS should update)")
                } else {
                    print("Both devices have same unusedIndex: \(currentUnusedIndex)")
                }
            }
        }
        
        // 只有在包含hash数据时才通知UI数据已更新
        if hasHashData {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("DataUpdated"), object: nil)
            }
        }
    }
}
