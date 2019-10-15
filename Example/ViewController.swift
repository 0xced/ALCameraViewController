//
//  ViewController.swift
//  ALCameraViewController
//
//  Created by Alex Littlejohn on 2015/06/17.
//  Copyright (c) 2015 zero. All rights reserved.
//

import AVFoundation
import UIKit

class ViewController: UIViewController {

    var libraryEnabled: Bool = true
    var croppingEnabled: Bool = false
    var allowResizing: Bool = true
    var allowMoving: Bool = false
    var minimumSize: CGSize = CGSize(width: 60, height: 60)

    var croppingParameters: CroppingParameters {
        return CroppingParameters(isEnabled: croppingEnabled, allowResizing: allowResizing, allowMoving: allowMoving, minimumSize: minimumSize)
    }
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var croppingParametersView: UIView!
    @IBOutlet weak var minimumSizeLabel: UILabel!

    var image: UIImage?
    var depthImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.imageView.contentMode = .scaleAspectFit
    }
    
    @IBAction func openCamera(_ sender: Any) {
        let cameraViewController = CameraViewController(croppingParameters: croppingParameters, allowsLibraryAccess: libraryEnabled) { [weak self] image, depthData, asset in
            self?.updateImages(image: image, depthData: depthData)
            self?.dismiss(animated: true, completion: nil)
        }
        
        present(cameraViewController, animated: true, completion: nil)
    }
    
    @IBAction func openLibrary(_ sender: Any) {
        let libraryViewController = CameraViewController.imagePickerViewController(croppingParameters: croppingParameters) { [weak self] image, depthData, asset in
            self?.updateImages(image: image, depthData: depthData)
            self?.dismiss(animated: true, completion: nil)
        }
        
        present(libraryViewController, animated: true, completion: nil)
    }
    
    @IBAction func libraryChanged(_ sender: Any) {
        libraryEnabled = !libraryEnabled
    }
    
    @IBAction func croppingChanged(_ sender: UISwitch) {
        croppingEnabled = sender.isOn
        croppingParametersView.isHidden = !sender.isOn
    }

    @IBAction func resizingChanged(_ sender: UISwitch) {
        allowResizing = sender.isOn
    }

    @IBAction func movingChanged(_ sender: UISwitch) {
        allowMoving = sender.isOn
    }

    @IBAction func minimumSizeChanged(_ sender: UISlider) {
        let newValue = sender.value
        minimumSize = CGSize(width: CGFloat(newValue), height: CGFloat(newValue))
        minimumSizeLabel.text = "Minimum size: \(newValue.rounded())"
    }

    private func updateImages(image: UIImage?, depthData: AVDepthData?) {
        self.imageView.image = image
        self.image = image
        self.depthImage = nil
        if let image = image, let depthData = depthData {
            DispatchQueue.global().async {
                self.depthImage = depthData.getImage(imageOrientation: image.imageOrientation).image
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let depthImage = depthImage {
            self.imageView.image = depthImage
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        restoreImage()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        restoreImage()
    }

    func restoreImage() {
        if let image = image {
            self.imageView.image = image
        }
    }

}

