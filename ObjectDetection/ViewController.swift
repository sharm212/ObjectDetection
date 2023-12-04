//
//  ViewController.swift
//  ObjectDetection
//
//  Created by Jatin Sharma on 2023-12-01.
//

import UIKit
import AVKit
import Vision
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var visionModel: VNCoreMLModel?
    let synthesizer = AVSpeechSynthesizer()
    let semaphore = DispatchSemaphore(value: 1)
    
    let identifierLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        //
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else { return }
        let request = VNCoreMLRequest(model: model)
        //
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession.addInput(input)
        /* starting capture session */
        setupVision()
        DispatchQueue.global(qos: .background).async {
            captureSession.startRunning()
        }
        //captureSession.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        
        setupIdentifierConfidenceLabel()
    }
    
    fileprivate func setupIdentifierConfidenceLabel() {
        view.addSubview(identifierLabel)
        identifierLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -32).isActive = true
        identifierLabel.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        identifierLabel.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        identifierLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    func setupVision() {
        guard let visionModel = try? VNCoreMLModel(for: Resnet50().model)
            else { fatalError("Can't load VisionML model") }
        self.visionModel = visionModel
    }
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        self.semaphore.wait()
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        guard let model = self.visionModel else { return }
        let request = VNCoreMLRequest(model: model) { (finishedReq, err) in

            guard let results = finishedReq.results as? [VNClassificationObservation] else { return }
            
            guard let firstObservation = results.first else { return }
            
            print(firstObservation.identifier, firstObservation.confidence)
            
            sleep(1)
            DispatchQueue.main.async {
                var val: String = self.identifierLabel.text ?? ""
                var val1 = val.components(separatedBy: CharacterSet.decimalDigits).joined()
               
                var val2 = val1.components(separatedBy: ",")
                var utterance = AVSpeechUtterance(string: val2[0])
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                utterance.rate = 0.4
                self.synthesizer.speak(utterance)
                
                self.semaphore.signal()
            }
            
            DispatchQueue.main.async {
                self.identifierLabel.text = "\(firstObservation.identifier) \(firstObservation.confidence * 100)"
            }
            
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }

}

