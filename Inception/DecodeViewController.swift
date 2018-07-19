//
//  ViewController.swift
//  Inception
//
//  Created by Mohammed Lazim on 7/6/17.
//  Copyright © 2017 iostreamh. All rights reserved.
//

import UIKit
import AVFoundation

class DecodeViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    @IBOutlet weak var predictionLabel: UILabel!
    @IBOutlet weak var resizedImage: UIImageView!
    var cameraSession: AVCaptureSession? = AVCaptureSession()

    var timeDiff = 0
    var isLightOn = false
    var isLightOff = false
    var isDaignoseStarted = false;
    var shortLed = 0
    var longLed = 0;
    var isSyncTime = false
    var isFirstTime = true
    
    var onTime: Date? = nil
    var offDate: Date? = nil

    
    lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let preview =  AVCaptureVideoPreviewLayer(session: self.cameraSession!)
        preview.videoGravity = .resizeAspectFill
        return preview
    }()
    
    var model = Inception();
    
    //var model = ledmodal1();

    
    private let sessionQueue = DispatchQueue(label: "session queue", attributes: [], target: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        predictionLabel.text = "Initiliazing..."
        
        let captureDevice = AVCaptureDevice.default(for: .video)! // todo: Can return nil. MDM restrictions
        
        do {
            let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            
            cameraSession?.beginConfiguration()
            
            if (cameraSession?.canAddInput(deviceInput) == true) {
                cameraSession?.addInput(deviceInput)
            }
            
            let dataOutput = AVCaptureVideoDataOutput()
            
            dataOutput.videoSettings = [((kCVPixelBufferPixelFormatTypeKey as NSString) as String) : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange as UInt32)]
            
            dataOutput.alwaysDiscardsLateVideoFrames = true
            
            if (cameraSession?.canAddOutput(dataOutput) == true) {
                cameraSession?.addOutput(dataOutput)
            }
            
            cameraSession?.commitConfiguration()
            
            let queue = DispatchQueue(label: "com.iostreamh.inception.video-output")
            dataOutput.setSampleBufferDelegate(self, queue: queue)
        }
        catch let error as NSError {
            NSLog("\(error), \(error.localizedDescription)")
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        var frame = view.frame
        frame.size.height = frame.size.height - 35.0
        previewLayer.frame = frame
        view.layer.addSublayer(previewLayer)
        cameraSession?.startRunning()
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        view.layer.removeFromSuperlayer()
        cameraSession?.stopRunning()
        cameraSession = nil
        
    }
    
    func resetAfterDecode() {
        self.cameraSession?.startRunning()
        self.isDaignoseStarted = false
        self.isSyncTime = false
        self.timeDiff = 0
        self.isLightOn = false
        self.isLightOff = false
        self.shortLed = 0;
        self.longLed = 0;
        self.offDate = nil
        self.onTime = nil
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection){
        connection.videoOrientation = .portrait
        if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            let ciImage = CIImage(cvImageBuffer: imageBuffer)
            let img = UIImage(ciImage: ciImage).resizeTo(CGSize(width: 227, height: 227))
            
            if let uiImage = img {
                let pixelBuffer = uiImage.buffer()!
                let output = try? model.prediction(data: pixelBuffer)
                
                DispatchQueue.main.async {
                    self.resizedImage.image = uiImage
                    
                    if (output?.classLabel == "lighton" && !self.isLightOn){
                        
                        // First calculate the sync time
                        
                        if let lOnTime = self.onTime {
//                            print("On time is not nil")

                            self.onTime = Date();
                            let timeIntervalbwOn = lOnTime.timeIntervalSinceNow*1000
                            let tDiffForON = abs(Int(timeIntervalbwOn))
//                            print("tDiffForON :", tDiffForON)
                            if tDiffForON > 1800 && !self.isDaignoseStarted{
//                                print("tDiffForON and  isDaignoseStarted true:")

                                self.isSyncTime = true
                                self.isDaignoseStarted = true;
                                self.shortLed = 0;
                                self.longLed = 0;

                            }
                            
                          // If sync time has not yet calculated
                        }else{
//                            print("On time was nil")
                            self.onTime = Date();
                        }
                        
                        self.isLightOff = false
                        self.isLightOn  = true
                        
                    }else if(output?.classLabel == "lightoff" && !self.isLightOff){
//                        print("Simply lightoff")

                        if let loffDate = self.onTime {
                            
//                            print("onTime has been assigned")

                            self.offDate = Date()
                            let timeInterval = loffDate.timeIntervalSinceNow * 1000
                            self.timeDiff = abs(Int(timeInterval))
                            
                            if(self.isDaignoseStarted){
//                                print("timeInterval :", self.timeDiff )
                                
                                if(self.timeDiff < 350 && self.timeDiff > 180){
                                    self.shortLed = self.shortLed + 1;
                                }
                                else if(self.timeDiff > 850 && self.timeDiff < 1200){
                                    self.longLed = self.longLed + 1;
                                }
                            }
                        }
                        
                        self.isLightOff = true
                        self.isLightOn  = false
                        
                    }else if(output?.classLabel == "lightoff" && self.isLightOff){
//                        print("isLightOff continue")
                        
                        if let loffDate = self.offDate {
                            let timeInterval = loffDate.timeIntervalSinceNow * 1000
                            self.timeDiff = abs(Int(timeInterval))
                            
                            if(self.timeDiff >= 1800 && self.isDaignoseStarted && self.isSyncTime && self.longLed > 0 && self.shortLed > 0){
//                                print("show alert")
                                let alertController = UIAlertController(title: "Fault Code is : ", message: String(self.shortLed) + String(self.longLed), preferredStyle: UIAlertControllerStyle.alert)
                                
                                alertController.addAction(UIAlertAction(title: "Try Again!", style: UIAlertActionStyle.default,handler: {(action:UIAlertAction) in
                                    self.resetAfterDecode()
                                }))
//                                print("stopRunning3")
                                self.cameraSession?.stopRunning()
                                self.present(alertController, animated: true, completion: nil)
                            }

                        }
                        
                    }
                    
                    self.predictionLabel.text = output?.classLabel ?? "I don't know! 😞"
                    
                }
            }
        }
    }
}




extension Date {
    var millisecondsSince1970:Int {
        return Int((self.timeIntervalSince1970 * 1000.0).rounded())
    }
    
    init(milliseconds:Int) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds / 1000))
    }
}


extension UIImage {
    func buffer() -> CVPixelBuffer? {
        return UIImage.buffer(from: self)
    }
    
    // Taken from:
    // https://stackoverflow.com/questions/44462087/how-to-convert-a-uiimage-to-a-cvpixelbuffer
    // https://www.hackingwithswift.com/whats-new-in-ios-11
    static func buffer(from image: UIImage) -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: image.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
    
    func resizeTo(_ size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContext(size)
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}


//https://www.invasivecode.com/weblog/AVFoundation-Swift-capture-video/
//https://gist.github.com/MihaelIsaev/273e4e8ddaaf062d2155
