//
//  CameraView.swift
//  ALCameraViewController
//
//  Created by Alex Littlejohn on 2015/06/17.
//  Copyright (c) 2015 zero. All rights reserved.
//

import UIKit
import AVFoundation

public typealias CameraShotCompletion = (UIImage?, AVDepthData?) -> Void

public class CameraView: UIView, AVCapturePhotoCaptureDelegate {
    
    var session: AVCaptureSession!
    var input: AVCaptureDeviceInput!
    var photoOutput: AVCapturePhotoOutput!
    var settings: AVCapturePhotoSettings!
    var preview: AVCaptureVideoPreviewLayer!
    
    private var cameraShotCompletion: CameraShotCompletion?
    
    let cameraQueue = DispatchQueue(label: "com.zero.ALCameraViewController.Queue")

    public var currentPosition = CameraGlobals.shared.defaultCameraPosition
    
    public func startSession() {
        session = AVCaptureSession()
        session.sessionPreset = .photo

        configureSession(position: currentPosition)

        cameraQueue.sync {
            session.startRunning()
            DispatchQueue.main.async() { [weak self] in
                self?.createPreview()
                self?.rotatePreview()
            }
        }
    }
    
    public func stopSession() {
        cameraQueue.sync {
            session?.stopRunning()
            preview?.removeFromSuperlayer()
            
            session = nil
            input = nil
            settings = nil
            photoOutput = nil
            preview = nil
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        preview?.frame = bounds
    }

    public func configureZoom() {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinch(gesture:)))
        addGestureRecognizer(pinchGesture)
    }

    @objc internal func pinch(gesture: UIPinchGestureRecognizer) {
        let device = input.device

        // Return zoom value between the minimum and maximum zoom values
        func minMaxZoom(_ factor: CGFloat) -> CGFloat {
            return min(max(factor, 1.0), device.activeFormat.videoMaxZoomFactor)
        }

        func update(scale factor: CGFloat) {
            do {
                try device.lockForConfiguration()
                defer { device.unlockForConfiguration() }
                device.videoZoomFactor = factor
            } catch {
                print("\(error.localizedDescription)")
            }
        }

        let velocity = gesture.velocity
        let velocityFactor: CGFloat = 8.0
        let desiredZoomFactor = device.videoZoomFactor + atan2(velocity, velocityFactor)

        let newScaleFactor = minMaxZoom(desiredZoomFactor)
        switch gesture.state {
        case .began, .changed:
            update(scale: newScaleFactor)
        case _:
            break
        }
    }
    
    private func createPreview() {
        
        preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = AVLayerVideoGravity.resizeAspect
        preview.frame = bounds

        layer.addSublayer(preview)
    }
    
    private func configureSession(position: AVCaptureDevice.Position) {
        var preferredDeviceTypes: [AVCaptureDevice.DeviceType] = [.builtInDualCamera, .builtInWideAngleCamera]
        if #available(iOS 11.1, *) {
            preferredDeviceTypes.insert(.builtInTrueDepthCamera, at: 0)
        }
        let disoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: preferredDeviceTypes, mediaType: .video, position: position)
        let device = disoverySession.devices.first!
        
        session.beginConfiguration()
        
        for input in session.inputs {
            session.removeInput(input)
        }
        input = try! AVCaptureDeviceInput(device: device)
        session.addInput(input)
        
        for output in session.outputs {
            session.removeOutput(output)
        }
        photoOutput = AVCapturePhotoOutput()
        session.addOutput(photoOutput)
        // The image output must be added to the session _before_ accessing isDepthDataDeliverySupported/isDepthDataDeliveryEnabled https://stackoverflow.com/questions/49302065/iphone-7-ios-11-2-depth-data-delivery-is-not-supported-in-the-current-configu/49308754#49308754
        // The documentation on https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/capturing_photos_with_depth is plain wrong (output is added _after_ configuring in the sample code 🙄)
        photoOutput.isDepthDataDeliveryEnabled = photoOutput.isDepthDataDeliverySupported
        
        settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        settings.isDepthDataDeliveryEnabled = photoOutput.isDepthDataDeliverySupported
        settings.flashMode = .auto
        
        session.commitConfiguration()
    }
    
    public func capturePhoto(completion: @escaping CameraShotCompletion) {
        isUserInteractionEnabled = false

        cameraQueue.sync {
            cameraShotCompletion = completion
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        DispatchQueue.main.async() {
            self.isUserInteractionEnabled = true
            
            if error != nil {
                // TODO: how should the error flow here?
                self.cameraShotCompletion!(nil, nil)
                return
            }
            
            let result = photo.getImage(videoOrientation: self.preview.connection!.videoOrientation)
            self.cameraShotCompletion!(result.image, result.depthData)
            self.cameraShotCompletion = nil
        }
    }
    
    public func focusCamera(toPoint: CGPoint) -> Bool {
        
        let device = input.device
        guard let preview = preview, device.isFocusModeSupported(.continuousAutoFocus) else {
            return false
        }
        
        do { try device.lockForConfiguration() } catch {
            return false
        }
        
        let focusPoint = preview.captureDevicePointConverted(fromLayerPoint: toPoint)

        device.focusPointOfInterest = focusPoint
        device.focusMode = .continuousAutoFocus

        device.exposurePointOfInterest = focusPoint
        device.exposureMode = .continuousAutoExposure

        device.unlockForConfiguration()
        
        return true
    }
    
    public func cycleFlash() {
        guard input.device.hasFlash else {
            return
        }
        
        if settings.flashMode == .on {
            settings.flashMode = .off
        } else if settings.flashMode == .off {
            settings.flashMode = .auto
        } else {
            settings.flashMode = .on
        }
    }

    public func swapCameraInput() {
        currentPosition = input.device.position == .back ? .front : .back
        configureSession(position: currentPosition)
    }
  
    public func rotatePreview() {
      
        guard preview != nil else {
            return
        }
        switch UIApplication.shared.statusBarOrientation {
            case .portrait:
              preview?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
              break
            case .portraitUpsideDown:
              preview?.connection?.videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown
              break
            case .landscapeRight:
              preview?.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeRight
              break
            case .landscapeLeft:
              preview?.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
              break
            default: break
        }
    }
    
}
