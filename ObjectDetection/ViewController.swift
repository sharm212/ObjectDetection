//
//  ViewController.swift
//  ObjectDetection
//
//  Created by Jatin Sharma on 2023-12-01.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        guard let captureDevice =
                AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession.addInput(input)
        
        captureSession.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
    }


}

