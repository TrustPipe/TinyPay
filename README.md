# TinyPay - OTP-Based Payment App

TinyPay is a secure payment application based on One-Time Password (OTP) technology, supporting both iOS and Apple Watch platforms.

## 🚀 Features

- **Secure Payments**: Uses OTP (One-Time Password) technology to ensure uniqueness and security for each payment
- **QR Code Generation**: Automatically generates QR codes containing payment information
- **Dual Platform Support**: Supports both iOS and Apple Watch
- **Real-time Sync**: Real-time synchronization of payment data between iOS and Watch
- **Clean Interface**: Intuitive and user-friendly interface

## 📱 How to Use

### Initial Setup

1. **Set Payment Address**
   - Open the app and switch to the "Settings" tab
   - Enter your payment address in the "Payer Address" input field
   - Click "SAVE" to save

2. **Generate OTP Chain**
   - Enter your OTP root key in the "OTP generation" section
   - Click "Start Calculation" to begin calculation
   - Wait for completion (generates a chain of 1000 hash values)
   - The system will display the tail hash value of the OTP chain

3. **Sync to Apple Watch**
   - After calculation is complete, click "sync to watch"
   - Data will automatically sync to your Apple Watch

### Daily Usage

1. **Generate Payment QR Code**
   - Switch to the "Show to Pay" tab
   - The app will automatically display the current available QR code
   - The QR code contains your payment address and current OTP hash value

2. **Refresh QR Code**
   - After each use, click "Refresh QR Code" to generate a new QR code
   - The system will automatically use the next OTP value to ensure security

3. **Apple Watch Usage**
   - Open the app on your Watch
   - QR code displays directly without additional operations
   - Real-time sync with iPhone data

## 🔒 Security Mechanism

- **OTP Chain Structure**: Uses SHA256 algorithm to generate 1000 consecutive hash values
- **One-time Use**: Each OTP can only be used once and expires automatically after use
- **Index Tracking**: System automatically tracks used OTP indices
- **Encrypted Storage**: All data is stored locally with encryption

## ⚙️ Technical Specifications

- **Development Language**: Swift
- **Framework**: SwiftUI
- **Supported Platforms**: iOS 14.0+, watchOS 7.0+
- **Encryption Algorithm**: SHA256
- **Data Synchronization**: WatchConnectivity Framework

## 📝 Important Notes

- Initial setup must be completed before first use
- OTP chain needs to be regenerated when depleted
- Regular backup of OTP root key is recommended
- Apple Watch must be paired with iPhone for use

## 🛠️ Development Information

- **Developer**: Harold
- **Creation Date**: September 18, 2025
- **Project Type**: Native iOS/watchOS Application

## 📄 License

This project is for learning and research purposes only.