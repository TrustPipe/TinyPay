//
//  HelpView.swift
//  TinyPay
//
//  Created by Harold on 2025/9/29.
//

import SwiftUI

struct HelpView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // App Introduction
                    HelpSection(
                        title: "App Introduction",
                        icon: "info.circle.fill",
                        color: .blue
                    ) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("TinyPay is a secure payment app based on OTP (One-Time Password) technology.")
                            Text("• Please deposit and setup your otp root at www.tinypay.top")
                            Text("• Supports both iOS and Apple Watch platforms")
                            Text("• Each payment code can only be used once, ensuring security")
                        }
                    }
                    
                    // Initial Setup
                    HelpSection(
                        title: "Initial Setup",
                        icon: "gearshape.fill",
                        color: .orange
                    ) {
                        VStack(alignment: .leading, spacing: 15) {
                            StepView(
                                step: "1",
                                title: "Set Payment Address",
                                description: "Enter your payment address in the settings page and save"
                            )
                            
                            StepView(
                                step: "2",
                                title: "Generate OTP Chain",
                                description: "Enter OTP root key, click 'Start Calculation' to generate your OTP"
                            )
                            
                            StepView(
                                step: "3",
                                title: "Sync to Watch",
                                description: "Click 'sync to watch' to synchronize data to Apple Watch"
                            )
                        }
                    }
                    
                    // Daily Usage
                    HelpSection(
                        title: "Daily Usage",
                        icon: "qrcode",
                        color: .green
                    ) {
                        VStack(alignment: .leading, spacing: 15) {
                            FeatureView(
                                icon: "qrcode.viewfinder",
                                title: "Display Payment Code",
                                description: "Show QR code on 'Show to Pay' page for others to scan and pay"
                            )
                            
                            FeatureView(
                                icon: "arrow.clockwise",
                                title: "Refresh Payment Code",
                                description: "Click 'Refresh QR Code' after each use to get a new security code"
                            )
                            
                            FeatureView(
                                icon: "applewatch",
                                title: "Watch Quick Payment",
                                description: "Display QR code directly on Apple Watch with real-time data sync"
                            )
                        }
                    }
                    
                    // Security Tips
                    HelpSection(
                        title: "Security Tips",
                        icon: "shield.fill",
                        color: .red
                    ) {
                        VStack(alignment: .leading, spacing: 10) {
                            SecurityTipView(text: "Each OTP can only be used once and expires automatically after use")
                            SecurityTipView(text: "OTP chain needs to be regenerated when depleted")
                            SecurityTipView(text: "Regularly backup your OTP root key")
                            SecurityTipView(text: "Never share your root key with others")
                        }
                    }
                    
                    // Frequently Asked Questions
                    HelpSection(
                        title: "Frequently Asked Questions",
                        icon: "questionmark.circle.fill",
                        color: .purple
                    ) {
                        VStack(spacing: 15) {
                            FAQView(
                                question: "Why can't the QR code be displayed?",
                                answer: "Please ensure that you have set up your payment address and generated the OTP chain. If the problem persists, please regenerate the OTP chain."
                            )
                            
                            FAQView(
                                question: "How do I know how many OTPs are available?",
                                answer: "The current index is displayed on the QR code page, counting down from 998 to 0."
                            )
                            
                            FAQView(
                                question: "Apple Watch cannot sync data?",
                                answer: "Make sure iPhone and Apple Watch are properly paired and both devices are connected to the network."
                            )
                            
                            FAQView(
                                question: "What to do when OTP chain is exhausted?",
                                answer: "You need to re-enter the root key and click 'Start Calculation' to regenerate the OTP chain."
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("User Guide")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct HelpSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content
    
    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            content
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StepView: View {
    let step: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 25, height: 25)
                
                Text(step)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct FeatureView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .font(.title3)
                .frame(width: 25)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct SecurityTipView: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.caption)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

struct FAQView: View {
    let question: String
    let answer: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(question)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            
            if isExpanded {
                Text(answer)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 10)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

#Preview {
    HelpView()
}