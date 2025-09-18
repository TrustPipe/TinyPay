//
//  WatchConnectivityManager.swift
//  TinyPay
//
//  Created by Harold on 2025/9/18.
//

//
//  WatchConnectivityManager.swift
//  AptosEveryWhere
//
//  Created by Harold on 2025/9/17.
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
    
    // 发送hash字典、unusedIndex和payer address到手表（合并发送以确保原子性）
    func sendDataToWatch(hashDict: [Int: String], unusedIndex: Int, payerAddr: String = "") {
        let stringKeyDict = Dictionary(uniqueKeysWithValues: hashDict.map { (String($0.key), $0.value) })
        
        var context: [String: Any] = [
            "hashDict": stringKeyDict,
            "unusedIndex": unusedIndex,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // 如果有 payer address，添加到传输数据中
        if !payerAddr.isEmpty {
            context["payer_addr"] = payerAddr
        }
        
        do {
            try WCSession.default.updateApplicationContext(context)
            print("Data sent to watch (hash: \(hashDict.count) entries, index: \(unusedIndex), payer: \(payerAddr.isEmpty ? "none" : "included"))")
        } catch {
            print("Failed to send data to watch: \(error)")
        }
    }
    
    // 发送hash字典到手表
    func sendHashDict(_ dict: [Int: String]) {
        let stringKeyDict = Dictionary(uniqueKeysWithValues: dict.map { (String($0.key), $0.value) })
        
        do {
            try WCSession.default.updateApplicationContext(["hashDict": stringKeyDict])
            print("Hash dict sent to watch")
        } catch {
            print("Failed to send hash dict: \(error)")
        }
    }
    
    // 发送unusedIndex到手表
    func sendUnusedIndex(_ index: Int) {
        guard WCSession.default.isReachable else {
            print("Watch not reachable, cannot send unusedIndex")
            return
        }
        
        let context = ["unusedIndex": index] as [String : Any]
        
        do {
            try WCSession.default.updateApplicationContext(context)
            print("UnusedIndex sent to watch: \(index)")
        } catch {
            print("Failed to send unusedIndex to watch: \(error)")
        }
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("iOS WCSession activation: \(activationState.rawValue)")
        if let error = error {
            print("iOS WCSession error: \(error)")
        }
        
        // 连接成功后，发送当前的unusedIndex以便同步检查
        // Watch会根据大小关系决定是否需要更新
        if activationState == .activated {
            let currentIndex = UserDefaults.standard.integer(forKey: "unusedIndex")
            print("iOS session activated, sending current index: \(currentIndex)")
            sendUnusedIndex(currentIndex)
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("iOS WCSession became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("iOS WCSession deactivated")
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("iOS received application context: \(applicationContext)")
        
        if let receivedUnusedIndex = applicationContext["unusedIndex"] as? Int {
            let currentUnusedIndex = UserDefaults.standard.integer(forKey: "unusedIndex")
            print("iOS current unusedIndex: \(currentUnusedIndex), received: \(receivedUnusedIndex)")
            
            // 如果当前iOS的unusedIndex更大，则更新为较小的值
            if currentUnusedIndex > receivedUnusedIndex {
                UserDefaults.standard.set(receivedUnusedIndex, forKey: "unusedIndex")
                print("iOS unusedIndex updated from \(currentUnusedIndex) to \(receivedUnusedIndex) (iOS had larger index)")
                
                // 通知UI更新
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("IndexUpdated"), object: nil)
                }
            } else if currentUnusedIndex < receivedUnusedIndex {
                print("iOS unusedIndex kept at \(currentUnusedIndex) (iOS had smaller index, watch should update)")
            } else {
                print("Both devices have same unusedIndex: \(currentUnusedIndex)")
            }
        }
    }
}

