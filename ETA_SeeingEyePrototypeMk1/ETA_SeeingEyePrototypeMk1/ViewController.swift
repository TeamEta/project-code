//
//  ViewController.swift
//  ETA_SeeingEyePrototypeMk1
//
//  Created by Engineering on 4/7/17.
//  Copyright © 2017 Engineering. All rights reserved.
//

import UIKit
import CoreMotion
import os.log
import Photos

class ViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let manager = CMMotionManager()

    //MARK: Properties
    
    @IBOutlet weak var firstImage: UIImageView!
    @IBOutlet weak var secondImage: UIImageView!
    
    @IBOutlet weak var firstYaw: UILabel!
    @IBOutlet weak var firstPitch: UILabel!
    @IBOutlet weak var firstRoll: UILabel!
    @IBOutlet weak var secondYaw: UILabel!
    @IBOutlet weak var secondPitch: UILabel!
    @IBOutlet weak var secondRoll: UILabel!
    
    var yawVal: Double = 0.0
    var pitchVal: Double = 0.0
    var rollVal: Double = 0.0
    
    
    var nSamples = 50
    var mVariance = 0.175/2
    var gyroSamples = Array<Double> ()
    var stable = false;
    
    var chosenPicture: Int = 0
    
    //MARK: UIImagePickerControllerDelegate
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        //Dismiss this picker if the user cancels
        dismiss(animated: true, completion: nil)
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        
        // The info dictionary may contain multiple representations of the image. You want to use the original.
        guard let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
        
        switch chosenPicture {
        case 0:
            fatalError("No image selected, and yet a picture was taken.")
        case 1:
            firstImage.image = selectedImage
            self.firstYaw.text = String(format:"Yaw = %.3f", self.yawVal)
            self.firstPitch.text = String(format:"Pitch = %.3f", self.pitchVal)
            self.firstRoll.text = String(format:"Roll = %.3f", self.rollVal)
        case 2:
            secondImage.image = selectedImage
            self.secondYaw.text = String(format:"Yaw = %.3f", self.yawVal)
            self.secondPitch.text = String(format:"Pitch = %.3f", self.pitchVal)
            self.secondRoll.text = String(format:"Roll = %.3f", self.rollVal)
        default:
            fatalError("Expected chosenPicture to be updated with the picture chosen.")
        }
        
        // Dismiss the picker
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: Actions
    
    /*@IBAction func captureFirstPhoto(_ sender: UITapGestureRecognizer) {
        chosenPicture = 1
        self.firstYaw.text = String(format:"Yaw = %f", self.yawVal)
        self.firstPitch.text = String(format:"Pitch = %f", self.pitchVal)
        self.firstRoll.text = String(format:"Roll = %f", self.rollVal)
        capturePhoto()
    }
    
    @IBAction func captureSecondPhoto(_ sender: UITapGestureRecognizer) {
        chosenPicture = 2
        self.secondYaw.text = String(format:"Yaw = %f", self.yawVal)
        self.secondPitch.text = String(format:"Pitch = %f", self.pitchVal)
        self.secondRoll.text = String(format:"Roll = %f", self.rollVal)
        capturePhoto()
    }*/
    
    @IBAction func takePictureButtonPressed(_ sender: UIButton) {
        switch chosenPicture {
        case 0:
            chosenPicture = 1
        case 1:
            chosenPicture = 2
        case 2:
            chosenPicture = 1
        default:
            fatalError("Expected chosenPicture to be updated with the picture chosen.")
        }
        
        capturePhoto()
    }
    
    func capturePhoto() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            
            // UIImagePickerController is a view controller that allows a user to pick media from their photo library, take a picture or movie, and more. This line declares one.
            let imagePicker = UIImagePickerController()
            
            // sets delegate of imagePicker
            imagePicker.delegate = self
            
            //
            imagePicker.sourceType = UIImagePickerControllerSourceType.camera
            //imagePicker.mediaTypes = [kUTTypeImage as String]
            imagePicker.allowsEditing = false
            
            imagePicker.cameraCaptureMode = .photo
            imagePicker.modalPresentationStyle = .fullScreen
            
            self.present(imagePicker, animated: true, completion: nil)
            //imagePicker.takePicture()
        }
    }

    
    
    //MARK: Navigation
    
    // This method lets you configure a view controller before it's presented.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        manager.stopDeviceMotionUpdates()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        manager.deviceMotionUpdateInterval = 0.1
        manager.startDeviceMotionUpdates(to: OperationQueue.main, withHandler:
            {deviceManager, error in
                self.yawVal = (self.manager.deviceMotion?.attitude.yaw)!
                self.pitchVal = (self.manager.deviceMotion?.attitude.pitch)!
                self.rollVal = (self.manager.deviceMotion?.attitude.roll)!
                
                let yaw = self.yawVal;
                
                
                self.gyroSamples.append(yaw)
                if(self.gyroSamples.count > self.nSamples)
                {
                    self.gyroSamples.remove(at: 0)
                }
                var sMax = abs(self.gyroSamples[0])
                var sMin = abs(self.gyroSamples[0])
                var avg = 0.0
                
                var o = 0.0
                for i in self.gyroSamples
                {
                    o = i
                    if (o<0)
                    {
                        o = -o;
                    }
                    if(o>sMax)
                    {
                        sMax = o
                    }
                    if(o<sMin)
                    {
                        sMin = o
                    }
                    avg = (avg+i)/2
                }
                
                
                let variance = sMax-sMin;
                if (variance < self.mVariance)
                {
                    self.stable = true
                }
                else
                {
                    self.stable = false
                }
                
                /*if(!self.stable)
                {
                    
                    
                    self.gyroRawX.text = String(format:"high: %f low: %f", sMax, sMin)
                }
                else
                {
                    if(self.picturePicker != nil)
                    {
                        if(self.picturePicker.isViewLoaded)
                        {
                            self.picturePicker.takePicture()
                        }
                    }
                    
                    self.gyroRawX.text = String(format:"Yaw = %f : Stable", yaw)
                }*/
                //self.firstYaw.text = String(format:"Yaw = %.3f", (self.manager.deviceMotion?.attitude.yaw)!)
        }
        )

        
    }
}

