//
//  ViewController.swift
//  Finding
//
//  Created by Dhanushikka Ravichandiran on 6/13/18.
//  Copyright © 2018 Dhanushikka Ravichandiran. All rights reserved.
//

import UIKit
import MobileCoreServices
import GoogleMobileVision
import Vision
import Firebase
import FirebaseMLVision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var findWord: UITextField!
    var imagePicker : UIImagePickerController!
    var textRecognizer: VisionTextRecognizer!
    
    @IBOutlet weak var imageView: UIImageView!
     var frameSublayer = CALayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    
        let vision = Vision.vision()
        textRecognizer = vision.onDeviceTextRecognizer()
        imageView.layer.addSublayer(frameSublayer)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func openCamera(_ sender: Any) {
        
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        if(UIImagePickerController.isSourceTypeAvailable(.camera)){
            imagePicker.sourceType = .camera
        }
        else{
            imagePicker.sourceType = .photoLibrary
        }
        //imagePicker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .camera)!
       
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
        print("User cancelled the camera or the photo library ")
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView.contentMode = .scaleAspectFit
            imageView.image = pickedImage
        }
        print("calling textDectection()")
        self.dismiss(animated: true, completion: nil)
        
        textDetection()
    }
    
    
    func processResult(from text: VisionText?, error: Error?) {
        removeFrames()
        print("processing")
        guard let features = text, let image = imageView.image else {
            return
        }
        let word = findWord.text!
        for block in features.blocks {
            for line in block.lines {
                for element in line.elements {
                    if(element.text.isEqual(word)){
                        self.addFrameView(
                            featureFrame: element.frame,
                            imageSize: image.size,
                            viewFrame: self.imageView.frame
                        )
                    }
                }
            }
        }
    }
    
    private func addFrameView(featureFrame: CGRect, imageSize: CGSize, viewFrame: CGRect) {
        print("Frame: \(featureFrame).")
        
        let viewSize = viewFrame.size
        
        // Find resolution for the view and image
        let rView = viewSize.width / viewSize.height
        let rImage = imageSize.width / imageSize.height
        
        // Define scale based on comparing resolutions
        var scale: CGFloat
        if rView > rImage {
            scale = viewSize.height / imageSize.height
        } else {
            scale = viewSize.width / imageSize.width
        }
        
        // Calculate scaled feature frame size
        let featureWidthScaled = featureFrame.size.width * scale
        let featureHeightScaled = featureFrame.size.height * scale
        
        // Calculate scaled feature frame top-left point
        let imageWidthScaled = imageSize.width * scale
        let imageHeightScaled = imageSize.height * scale
        
        let imagePointXScaled = (viewSize.width - imageWidthScaled) / 2
        let imagePointYScaled = (viewSize.height - imageHeightScaled) / 2
        
        let featurePointXScaled = imagePointXScaled + featureFrame.origin.x * scale
        let featurePointYScaled = imagePointYScaled + featureFrame.origin.y * scale
        
        // Define a rect for scaled feature frame
        let featureRectScaled = CGRect(x: featurePointXScaled,
                                       y: featurePointYScaled,
                                       width: featureWidthScaled,
                                       height: featureHeightScaled)
        
        drawFrame(featureRectScaled)
    }
    
    /// Creates and draws a frame for the calculated rect as a sublayer.
    ///
    /// - Parameter rect: The rect to draw.
    private func drawFrame(_ rect: CGRect) {
        print("drawing")
        let bpath: UIBezierPath = UIBezierPath(rect: rect)
        let rectLayer: CAShapeLayer = CAShapeLayer()
        rectLayer.path = bpath.cgPath
        rectLayer.strokeColor = UIColor.black.cgColor
        rectLayer.fillColor = UIColor.yellow.cgColor
        rectLayer.opacity = 0.4
        rectLayer.lineWidth = 4.0
        frameSublayer.addSublayer(rectLayer)
    }
    
    private func removeFrames() {
        guard let sublayers = frameSublayer.sublayers else { return }
        for sublayer in sublayers {
            guard let frameLayer = sublayer as CALayer? else {
                print("Failed to remove frame layer.")
                continue
            }
            frameLayer.removeFromSuperlayer()
        }
    }
 
    // the main part
    func textDetection() {
        print("detecting ")
        
        let visionImage = VisionImage(image: imageView.image!)
        textRecognizer.process(visionImage, completion: { (features, error) in
            self.processResult(from: features, error: error)
        })
     
    }
    
}
