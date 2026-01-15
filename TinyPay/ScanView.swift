//
//  ScanView.swift
//  TinyPay
//
//  Created by Harold on 2025/12/4.
//

import SwiftUI
import AVFoundation

struct ScanView: View {
    @State private var scannedCode = ""
    @State private var showingResult = false
    @State private var scanResult: ScanResult?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Camera View
                CameraView(scannedCode: $scannedCode, showingResult: $showingResult, scanResult: $scanResult)
                    .edgesIgnoringSafeArea(.all)
                
                // Scan Frame Overlay
                VStack {
                    Spacer()
                    
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.green, lineWidth: 3)
                        .frame(width: 250, height: 250)
                    
                    Text(LocalizedStrings.scanQRCode)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                        .padding(.top, 20)
                    
                    Spacer()
                }
            }
            .navigationTitle(LocalizedStrings.scan)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStrings.close) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingResult) {
                if let result = scanResult {
                    ScanResultView(result: result)
                }
            }
        }
    }
}

struct ScanResult {
    let type: String // "pay" or "receive"
    let address: String
    let otp: String?
    let amount: String?
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var scannedCode: String
    @Binding var showingResult: Bool
    @Binding var scanResult: ScanResult?
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let scanner = ScannerViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ScannerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func didFindCode(_ code: String) {
            parent.scannedCode = code
            parent.scanResult = parseQRCode(code)
            parent.showingResult = true
        }
        
        private func parseQRCode(_ code: String) -> ScanResult? {
            guard let url = URL(string: code),
                  url.scheme == "tinypay",
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let queryItems = components.queryItems else {
                return nil
            }
            
            let type = url.host ?? ""
            var address = ""
            var otp: String?
            var amount: String?
            
            for item in queryItems {
                switch item.name {
                case "address":
                    address = item.value ?? ""
                case "otp":
                    otp = item.value
                case "amount":
                    amount = item.value
                default:
                    break
                }
            }
            
            return ScanResult(type: type, address: address, otp: otp, amount: amount)
        }
    }
}

protocol ScannerDelegate: AnyObject {
    func didFindCode(_ code: String)
}

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: ScannerDelegate?
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            delegate?.didFindCode(stringValue)
            captureSession.stopRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if captureSession?.isRunning == true {
            captureSession.stopRunning()
        }
    }
}

struct ScanResultView: View {
    let result: ScanResult
    @State private var inputAmount = ""
    @State private var isProcessing = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                Spacer()
                
                // Result Icon
                Image(systemName: result.type == "pay" ? "dollarsign.circle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(result.type == "pay" ? .blue : .green)
                
                // Result Type
                Text(result.type == "pay" ? LocalizedStrings.payCode : LocalizedStrings.receiveCode)
                    .font(.title)
                    .fontWeight(.bold)
                
                // Details
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text(LocalizedStrings.address + ":")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(result.address.prefix(10) + "..." + result.address.suffix(6))
                            .font(.system(.body, design: .monospaced))
                    }
                    
                    if let otp = result.otp {
                        HStack {
                            Text(LocalizedStrings.currentOTP + ":")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(otp)
                                .font(.system(.title3, design: .monospaced))
                                .fontWeight(.bold)
                        }
                    }
                    
                    if result.type == "pay" {
                        // Scanning pay code - need to input amount
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizedStrings.amount + ":")
                                .foregroundColor(.secondary)
                            TextField(LocalizedStrings.enterAmount, text: $inputAmount)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.title2)
                        }
                    } else if let amount = result.amount {
                        // Scanning receive code - fixed amount
                        HStack {
                            Text(LocalizedStrings.amount + ":")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(amount)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Action Button
                Button(action: {
                    processPayment()
                }) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "checkmark")
                            Text(result.type == "pay" ? LocalizedStrings.confirmCollection : LocalizedStrings.confirmPayment)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(result.type == "pay" && inputAmount.isEmpty)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle(LocalizedStrings.scanResult)
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
    
    private func processPayment() {
        isProcessing = true
        
        // TODO: Implement blockchain transaction
        // For pay code: collect payment with inputAmount
        // For receive code: pay the fixed amount
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isProcessing = false
            dismiss()
        }
    }
}

#Preview {
    ScanView()
}
