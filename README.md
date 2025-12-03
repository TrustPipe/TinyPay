# TinyPay

Secure offline payment app using OTP technology.

## Features

- Generate unique payment QR codes using SHA256 hash chains
- Each payment code can only be used once
- Works on iPhone and Apple Watch
- Auto-sync between devices
- No internet required

## Quick Start

### First Time Setup

1. Enter your payment address
2. Enter your OTP root key
3. Wait for hash chain generation (1000 codes)
4. Show QR code to receive payment

### Daily Use

1. Open "Show to Pay" tab
2. Show QR code to payer
3. Tap "Refresh" after each payment

## Requirements

- iOS 14.0+
- watchOS 7.0+ (optional)

## Technical Details

- Language: Swift
- Framework: SwiftUI
- Algorithm: SHA256
- Storage: Local only

## Notes

- Backup your OTP root key
- Regenerate chain when depleted
- Keep devices paired for sync

## Developer

Harold, 2025