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
    
    // Send unusedIndex to iPhone
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
        
        // After connection, send current unusedIndex for sync checking
        // iOS will decide whether to update based on size comparison
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
            
            // Save data
            if let data = try? JSONSerialization.data(withJSONObject: hashData, options: []) {
                UserDefaults.standard.set(data, forKey: "indexHashMap")
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastSyncTimestamp")
            }
        }
        
        // Handle payer address data
        if let payerAddr = applicationContext["payer_addr"] as? String {
            print("Watch received payer address: \(payerAddr)")
            UserDefaults.standard.set(payerAddr, forKey: "payer_addr")
        }
        
        if let receivedUnusedIndex = applicationContext["unusedIndex"] as? Int {
            let currentUnusedIndex = UserDefaults.standard.integer(forKey: "unusedIndex")
            print("Watch current unusedIndex: \(currentUnusedIndex), received: \(receivedUnusedIndex)")
            
            if hasHashData {
                // If contains hash data, it means root recalculation, accept new index directly
                UserDefaults.standard.set(receivedUnusedIndex, forKey: "unusedIndex")
                print("Watch unusedIndex updated from \(currentUnusedIndex) to \(receivedUnusedIndex) (new root calculation)")
                
                // Notify UI to update
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("IndexUpdated"), object: nil)
                }
            } else {
                // If only index sync, use original logic (only update if own index is larger)
                if currentUnusedIndex > receivedUnusedIndex {
                    UserDefaults.standard.set(receivedUnusedIndex, forKey: "unusedIndex")
                    print("Watch unusedIndex updated from \(currentUnusedIndex) to \(receivedUnusedIndex) (Watch had larger index)")
                    
                    // Notify UI to update
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
        
        // Only notify UI data updated when hash data is included
        if hasHashData {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("DataUpdated"), object: nil)
            }
        }
    }
}
