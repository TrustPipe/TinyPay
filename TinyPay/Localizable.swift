//
//  Localizable.swift
//  TinyPay
//
//  Created by Harold on 2025/12/4.
//

import Foundation

enum AppLanguage: String, CaseIterable {
    case english = "en"
    case chinese = "zh"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "中文"
        }
    }
}

struct LocalizedStrings {
    static var current: AppLanguage {
        get {
            if let langCode = UserDefaults.standard.string(forKey: "app_language"),
               let lang = AppLanguage(rawValue: langCode) {
                return lang
            }
            return .english
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "app_language")
        }
    }
    
    // Tab Bar
    static var tabHome: String {
        current == .chinese ? "首页" : "Home"
    }
    
    static var tabEarn: String {
        current == .chinese ? "收益" : "Earn"
    }
    
    static var tabContact: String {
        current == .chinese ? "朋友" : "Friends"
    }
    
    static var tabMe: String {
        current == .chinese ? "我的" : "Me"
    }
    
    // Home
    static var myQRCode: String {
        current == .chinese ? "我的二维码" : "My QR Code"
    }
    
    static var scan: String {
        current == .chinese ? "扫一扫" : "Scan"
    }
    
    static var payCode: String {
        current == .chinese ? "付款码" : "Pay Code"
    }
    
    static var receiveCode: String {
        current == .chinese ? "收款码" : "Receive Code"
    }
    
    static var switchToReceiveCode: String {
        current == .chinese ? "切换到收款码" : "Switch to Receive Code"
    }
    
    static var switchToPayCode: String {
        current == .chinese ? "切换到付款码" : "Switch to Pay Code"
    }
    
    static var refreshCode: String {
        current == .chinese ? "刷新二维码" : "Refresh QR Code"
    }
    
    static var enterAmount: String {
        current == .chinese ? "输入金额" : "Enter Amount"
    }
    
    static var generateCode: String {
        current == .chinese ? "生成二维码" : "Generate Code"
    }
    
    // QR Code Info
    static var paymentAddress: String {
        current == .chinese ? "付款地址" : "Payment Address"
    }
    
    static var receiveAddress: String {
        current == .chinese ? "收款地址" : "Receive Address"
    }
    
    static var amount: String {
        current == .chinese ? "金额" : "Amount"
    }
    
    static var otpValue: String {
        current == .chinese ? "OTP值" : "OTP Value"
    }
    
    static var currentIndex: String {
        current == .chinese ? "当前索引" : "Current Index"
    }
    
    // Scan
    static var scanQRCode: String {
        current == .chinese ? "扫描二维码" : "Scan QR Code"
    }
    
    static var scanToReceive: String {
        current == .chinese ? "扫码收款" : "Scan to Receive"
    }
    
    static var scanToPay: String {
        current == .chinese ? "扫码付款" : "Scan to Pay"
    }
    
    static var confirmPayment: String {
        current == .chinese ? "确认付款" : "Confirm Payment"
    }
    
    static var confirmReceive: String {
        current == .chinese ? "确认收款" : "Confirm Receive"
    }
    
    // Me/Settings
    static var settings: String {
        current == .chinese ? "设置" : "Settings"
    }
    
    static var addressManagement: String {
        current == .chinese ? "地址管理" : "Address Management"
    }
    
    static var otpManagement: String {
        current == .chinese ? "OTP管理" : "OTP Management"
    }
    
    static var language: String {
        current == .chinese ? "语言" : "Language"
    }
    
    static var help: String {
        current == .chinese ? "帮助" : "Help"
    }
    
    static var about: String {
        current == .chinese ? "关于" : "About"
    }
    
    // Messages
    static var pleaseSetupAddress: String {
        current == .chinese ? "请先设置支付地址" : "Please setup payment address"
    }
    
    static var pleaseSetupOTP: String {
        current == .chinese ? "请先设置OTP根密钥" : "Please setup OTP root key"
    }
    
    static var processing: String {
        current == .chinese ? "处理中..." : "Processing..."
    }
    
    static var success: String {
        current == .chinese ? "成功" : "Success"
    }
    
    static var failed: String {
        current == .chinese ? "失败" : "Failed"
    }
    
    static var cancel: String {
        current == .chinese ? "取消" : "Cancel"
    }
    
    static var confirm: String {
        current == .chinese ? "确认" : "Confirm"
    }
    
    static var save: String {
        current == .chinese ? "保存" : "Save"
    }
    
    static var close: String {
        current == .chinese ? "关闭" : "Close"
    }
    
    static var address: String {
        current == .chinese ? "地址" : "Address"
    }
    
    static var currentOTP: String {
        current == .chinese ? "当前OTP" : "Current OTP"
    }
    
    static var payCodeDescription: String {
        current == .chinese ? "向收款方出示此付款码，收款方扫描后输入金额即可完成付款" : "Show this pay code to the recipient, who can scan and enter the amount to complete payment"
    }
    
    static var receiveCodeDescription: String {
        current == .chinese ? "向付款方出示此收款码，付款方扫描后即可按固定金额付款" : "Show this receive code to the payer, who can scan and pay the fixed amount"
    }
    
    static var refreshOTP: String {
        current == .chinese ? "刷新OTP" : "Refresh OTP"
    }
    
    static var qrCodeGenerationFailed: String {
        current == .chinese ? "二维码生成失败" : "QR Code Generation Failed"
    }
    
    static var scanResult: String {
        current == .chinese ? "扫描结果" : "Scan Result"
    }
    
    static var confirmCollection: String {
        current == .chinese ? "确认收款" : "Confirm Collection"
    }
    
    // Earn/DeFi
    static var totalBalance: String {
        current == .chinese ? "总余额" : "Total Balance"
    }
    
    static var dailyEarnings: String {
        current == .chinese ? "今日收益" : "Daily Earnings"
    }
    
    static var defiProducts: String {
        current == .chinese ? "DeFi产品" : "DeFi Products"
    }
    
    static var flexibleStaking: String {
        current == .chinese ? "活期质押" : "Flexible Staking"
    }
    
    static var fixedStaking: String {
        current == .chinese ? "定期质押" : "Fixed Staking"
    }
    
    static var liquidityMining: String {
        current == .chinese ? "流动性挖矿" : "Liquidity Mining"
    }
    
    static var minimumAmount: String {
        current == .chinese ? "最低金额" : "Minimum Amount"
    }
    
    static var lockPeriod: String {
        current == .chinese ? "锁定期限" : "Lock Period"
    }
    
    static var flexible: String {
        current == .chinese ? "灵活" : "Flexible"
    }
    
    static var days: String {
        current == .chinese ? "天" : "days"
    }
    
    static var lowRisk: String {
        current == .chinese ? "低风险" : "Low Risk"
    }
    
    static var mediumRisk: String {
        current == .chinese ? "中风险" : "Medium Risk"
    }
    
    static var highRisk: String {
        current == .chinese ? "高风险" : "High Risk"
    }
    
    static var stake: String {
        current == .chinese ? "质押" : "Stake"
    }
    
    static var earningsHistory: String {
        current == .chinese ? "收益记录" : "Earnings History"
    }
    
    static var selectProduct: String {
        current == .chinese ? "选择产品" : "Select Product"
    }
    
    static var confirmStake: String {
        current == .chinese ? "确认质押" : "Confirm Stake"
    }
    
    // Contact
    static var noContacts: String {
        current == .chinese ? "暂无联系人" : "No Contacts"
    }
    
    static var addContact: String {
        current == .chinese ? "添加联系人" : "Add Contact"
    }
    
    static var searchContacts: String {
        current == .chinese ? "搜索联系人" : "Search Contacts"
    }
    
    static var delete: String {
        current == .chinese ? "删除" : "Delete"
    }
    
    static var contactInfo: String {
        current == .chinese ? "联系人信息" : "Contact Info"
    }
    
    static var name: String {
        current == .chinese ? "姓名" : "Name"
    }
    
    static var note: String {
        current == .chinese ? "备注" : "Note"
    }
    
    static var optional: String {
        current == .chinese ? "可选" : "Optional"
    }
    
    static var noteOptional: String {
        current == .chinese ? "备注(可选)" : "Note (Optional)"
    }
    
    static var scanAddress: String {
        current == .chinese ? "扫描地址" : "Scan Address"
    }
    
    static var contactDetail: String {
        current == .chinese ? "联系人详情" : "Contact Detail"
    }
    
    
    static var copy: String {
        current == .chinese ? "复制" : "Copy"
    }
    
    // Me/Settings
    static var accountSettings: String {
        current == .chinese ? "账户设置" : "Account Settings"
    }
    
    static var generalSettings: String {
        current == .chinese ? "通用设置" : "General Settings"
    }
    
    static var notifications: String {
        current == .chinese ? "通知" : "Notifications"
    }
    
    static var security: String {
        current == .chinese ? "安全" : "Security"
    }
    
    static var version: String {
        current == .chinese ? "版本" : "Version"
    }
    
    static var syncToWatch: String {
        current == .chinese ? "同步到手表" : "Sync to Watch"
    }
    
    static var currentAddress: String {
        current == .chinese ? "当前地址" : "Current Address"
    }
    
    static var noAddressSet: String {
        current == .chinese ? "未设置地址" : "No Address Set"
    }
    
    static var newAddress: String {
        current == .chinese ? "新地址" : "New Address"
    }
    
    static var enterAddress: String {
        current == .chinese ? "输入地址" : "Enter Address"
    }
    
    static var otpGeneration: String {
        current == .chinese ? "OTP生成" : "OTP Generation"
    }
    
    static var otpRoot: String {
        current == .chinese ? "OTP根密钥" : "OTP Root"
    }
    
    static var enterOTPRoot: String {
        current == .chinese ? "输入OTP根密钥" : "Enter OTP Root"
    }
    
    static var startCalculation: String {
        current == .chinese ? "开始计算" : "Start Calculation"
    }
    
    static var calculating: String {
        current == .chinese ? "计算中..." : "Calculating..."
    }
    
    static var otpTail: String {
        current == .chinese ? "OTP链尾" : "OTP Tail"
    }
    
    static var nextAvailable: String {
        current == .chinese ? "下一个可用" : "Next Available"
    }
    
    static var index: String {
        current == .chinese ? "索引" : "Index"
    }
    
    // Home - Balance & Actions
    static var balance: String {
        current == .chinese ? "余额" : "Balance"
    }
    
    static var fund: String {
        current == .chinese ? "充值" : "Fund"
    }
    
    static var deposit: String {
        current == .chinese ? "充值" : "Deposit"
    }
    
    static var transfer: String {
        current == .chinese ? "转账" : "Transfer"
    }
    
    static var recentTransactions: String {
        current == .chinese ? "最近交易" : "Recent Transactions"
    }
    
    static var viewAll: String {
        current == .chinese ? "查看全部" : "View All"
    }
    
    static var noTransactions: String {
        current == .chinese ? "暂无交易记录" : "No Transactions"
    }
    
    static var transactionHistory: String {
        current == .chinese ? "交易记录" : "Transaction History"
    }
    
    static var received: String {
        current == .chinese ? "收到" : "Received"
    }
    
    static var sent: String {
        current == .chinese ? "发送" : "Sent"
    }
    
    static var today: String {
        current == .chinese ? "今天" : "Today"
    }
    
    static var yesterday: String {
        current == .chinese ? "昨天" : "Yesterday"
    }
    
    static var confirmFund: String {
        current == .chinese ? "确认充值" : "Confirm Fund"
    }
    
    static var confirmDeposit: String {
        current == .chinese ? "确认充值" : "Confirm Deposit"
    }
    
    static var confirmTransfer: String {
        current == .chinese ? "确认转账" : "Confirm Transfer"
    }
    
    static var recipientAddress: String {
        current == .chinese ? "接收地址" : "Recipient Address"
    }
    
    // QR Payment Feature
    static var qrPayment: String {
        current == .chinese ? "扫码支付" : "QR Payment"
    }
    
    static var showQRCode: String {
        current == .chinese ? "出示二维码" : "Show QR Code"
    }
    
    static var toReceive: String {
        current == .chinese ? "收款" : "To Receive"
    }
    
    static var toPay: String {
        current == .chinese ? "付款" : "To Pay"
    }
    
    static var offlineAvailable: String {
        current == .chinese ? "离线可用" : "Offline"
    }
    
    static var requiresNetwork: String {
        current == .chinese ? "需要网络" : "Online"
    }
    
    static var offlineMode: String {
        current == .chinese ? "离线模式 - 您仍可通过显示二维码完成收付款" : "Offline Mode - You can still finish any payment with your QR code"
    }
    
    // Friends / Transfer
    static var transferToAnyone: String {
        current == .chinese ? "转账给任何人" : "Transfer to Anyone"
    }
    
    static var enterOrScanAddress: String {
        current == .chinese ? "输入或扫描地址" : "Enter or Scan Address"
    }
    
    static var pasteAddress: String {
        current == .chinese ? "粘贴地址" : "Paste"
    }
    
    static var scanAddressQR: String {
        current == .chinese ? "扫描地址二维码" : "Scan Address QR"
    }
    
    static var myFriends: String {
        current == .chinese ? "我的朋友" : "My Friends"
    }
    
    static var quickTransfer: String {
        current == .chinese ? "快速转账" : "Quick Transfer"
    }
    
    // Bill Split
    static var billCurrency: String {
        current == .chinese ? "账单币种" : "Bill Currency"
    }
    
    static var billAmount: String {
        current == .chinese ? "账单金额" : "Bill Amount"
    }
    
    static var splitBetween: String {
        current == .chinese ? "分摊人数" : "Split Between"
    }
    
    static var people: String {
        current == .chinese ? "人" : "People"
    }
    
    static var perPerson: String {
        current == .chinese ? "每人支付" : "Per Person"
    }
    
    static var exchangeRate: String {
        current == .chinese ? "汇率" : "Exchange Rate"
    }
    
    static var send: String {
        current == .chinese ? "发送" : "Send"
    }
    
    static var request: String {
        current == .chinese ? "请求" : "Request"
    }
    
    static var groupPayment: String {
        current == .chinese ? "群收款" : "Group"
    }
    
    static var sendToSelected: String {
        current == .chinese ? "发送给选中的人" : "Send to Selected"
    }
    
    static var requestFromSelected: String {
        current == .chinese ? "向选中的人请求" : "Request from Selected"
    }
    
    static var createGroupPayment: String {
        current == .chinese ? "创建群收款" : "Create Group Payment"
    }
    
    static var selectedContacts: String {
        current == .chinese ? "选中的联系人" : "Selected Contacts"
    }
    
    static var sendPayment: String {
        current == .chinese ? "发送付款" : "Send Payment"
    }
    
    static var requestPayment: String {
        current == .chinese ? "请求付款" : "Request Payment"
    }
    
    static var confirmSend: String {
        current == .chinese ? "确认发送" : "Confirm Send"
    }
    
    static var confirmRequest: String {
        current == .chinese ? "确认请求" : "Confirm Request"
    }
    
    static var createRequest: String {
        current == .chinese ? "创建请求" : "Create Request"
    }
    
    static var continueAction: String {
        current == .chinese ? "继续" : "Continue"
    }
    
    // Common
    static var currencyUSDT: String {
        "USDT"
    }
}
