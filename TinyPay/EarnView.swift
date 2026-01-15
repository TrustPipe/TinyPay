//
//  EarnView.swift
//  TinyPay
//
//  Created by Harold on 2025/12/4.
//

import SwiftUI

struct EarnView: View {
    @State private var totalBalance = "5,678.90"
    @State private var dailyEarnings = "12.45"
    @State private var apy = "5.2"
    @State private var isStaking = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Balance Card
                    VStack(spacing: 15) {
                        Text(LocalizedStrings.totalBalance)
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text(totalBalance)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                        
                        Text(LocalizedStrings.currencyUSDT)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.themePurple.opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Earnings Info
                    HStack(spacing: 20) {
                        VStack(spacing: 8) {
                            Text(LocalizedStrings.dailyEarnings)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(dailyEarnings)
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(16)
                        
                        VStack(spacing: 8) {
                            Text("APY")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(apy + "%")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(16)
                    }
                    .padding(.horizontal)
                    
                    // DeFi Products
                    VStack(alignment: .leading, spacing: 15) {
                        Text(LocalizedStrings.defiProducts)
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        // Staking Product
                        DefiProductCard(
                            title: LocalizedStrings.flexibleStaking,
                            apy: "5.2",
                            minAmount: "100",
                            lockPeriod: LocalizedStrings.flexible,
                            risk: LocalizedStrings.lowRisk,
                            action: {
                                isStaking = true
                            }
                        )
                        
                        // Fixed Staking Product
                        DefiProductCard(
                            title: LocalizedStrings.fixedStaking,
                            apy: "12.5",
                            minAmount: "1000",
                            lockPeriod: "30 " + LocalizedStrings.days,
                            risk: LocalizedStrings.mediumRisk,
                            action: {
                                isStaking = true
                            }
                        )
                        
                        // Liquidity Mining
                        DefiProductCard(
                            title: LocalizedStrings.liquidityMining,
                            apy: "25.8",
                            minAmount: "5000",
                            lockPeriod: LocalizedStrings.flexible,
                            risk: LocalizedStrings.highRisk,
                            action: {
                                isStaking = true
                            }
                        )
                    }
                    .padding(.top, 10)
                    
                    // Transaction History
                    VStack(alignment: .leading, spacing: 15) {
                        Text(LocalizedStrings.earningsHistory)
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            EarningsHistoryRow(
                                type: LocalizedStrings.flexibleStaking,
                                amount: "+12.50",
                                date: "2024-01-15"
                            )
                            Divider()
                            EarningsHistoryRow(
                                type: LocalizedStrings.fixedStaking,
                                amount: "+45.80",
                                date: "2024-01-14"
                            )
                            Divider()
                            EarningsHistoryRow(
                                type: LocalizedStrings.liquidityMining,
                                amount: "+128.90",
                                date: "2024-01-13"
                            )
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: .gray.opacity(0.2), radius: 5)
                        .padding(.horizontal)
                    }
                    .padding(.top, 10)
                }
                .padding(.vertical)
            }
            .navigationTitle(LocalizedStrings.tabEarn)
            .sheet(isPresented: $isStaking) {
                StakingView()
            }
        }
    }
}

struct DefiProductCard: View {
    let title: String
    let apy: String
    let minAmount: String
    let lockPeriod: String
    let risk: String
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(risk)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(riskColor.opacity(0.2))
                        .foregroundColor(riskColor)
                        .cornerRadius(5)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("APY")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(apy + "%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(LocalizedStrings.minimumAmount)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(minAmount + " USDT")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 3) {
                    Text(LocalizedStrings.lockPeriod)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(lockPeriod)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            
            Button(action: action) {
                Text(LocalizedStrings.stake)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.2), radius: 5)
        .padding(.horizontal)
    }
    
    private var riskColor: Color {
        switch risk {
        case LocalizedStrings.lowRisk:
            return .green
        case LocalizedStrings.mediumRisk:
            return .orange
        case LocalizedStrings.highRisk:
            return .red
        default:
            return .gray
        }
    }
}

struct EarningsHistoryRow: View {
    let type: String
    let amount: String
    let date: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(type)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(amount + " USDT")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.green)
        }
        .padding()
    }
}

struct StakingView: View {
    @State private var stakeAmount = ""
    @State private var selectedProduct = 0
    @Environment(\.dismiss) var dismiss
    
    let products = [
        LocalizedStrings.flexibleStaking,
        LocalizedStrings.fixedStaking,
        LocalizedStrings.liquidityMining
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                Picker(LocalizedStrings.selectProduct, selection: $selectedProduct) {
                    ForEach(0..<products.count, id: \.self) { index in
                        Text(products[index]).tag(index)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text(LocalizedStrings.amount)
                        .font(.headline)
                    TextField(LocalizedStrings.enterAmount, text: $stakeAmount)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title2)
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 15) {
                    StakingInfoRow(label: "APY", value: getAPY())
                    StakingInfoRow(label: LocalizedStrings.minimumAmount, value: getMinAmount())
                    StakingInfoRow(label: LocalizedStrings.lockPeriod, value: getLockPeriod())
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                
                Button(action: {
                    // TODO: Implement staking
                    dismiss()
                }) {
                    Text(LocalizedStrings.confirmStake)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(stakeAmount.isEmpty)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle(LocalizedStrings.stake)
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
    
    private func getAPY() -> String {
        switch selectedProduct {
        case 0: return "5.2%"
        case 1: return "12.5%"
        case 2: return "25.8%"
        default: return "0%"
        }
    }
    
    private func getMinAmount() -> String {
        switch selectedProduct {
        case 0: return "100 USDT"
        case 1: return "1000 USDT"
        case 2: return "5000 USDT"
        default: return "0 USDT"
        }
    }
    
    private func getLockPeriod() -> String {
        switch selectedProduct {
        case 0: return LocalizedStrings.flexible
        case 1: return "30 " + LocalizedStrings.days
        case 2: return LocalizedStrings.flexible
        default: return ""
        }
    }
}

struct StakingInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    EarnView()
}
