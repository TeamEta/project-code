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
    
    @IBOutlet weak var deltaX: UILabel!
    @IBOutlet weak var distanceToClosest: UILabel!
    
    var picturePicker: UIImagePickerController!
    
    var timeToCapture: Bool = false
    
    var yawVal: Double = 0.0
    var pitchVal: Double = 0.0
    var rollVal: Double = 0.0
    
    var firstYawVal: Double = 0.0
    var firstPitchVal: Double = 0.0
    var firstRollVal: Double = 0.0
    
    var secondYawVal: Double = 0.0
    var secondPitchVal: Double = 0.0
    var secondRollVal: Double = 0.0
    
    var deltaYaw: Double = 0.0
    var deltaPitch: Double = 0.0
    var deltaRoll: Double = 0.0
    
    var nSamples = 50
    var mVariance = 0.175
    var gyroSamples = Array<Double> ()
    var stable = false;
    
    var avgYaw1 = 0.0;
    var avgYaw2 = 0.0;
    var avg = 0.0;
    
    var distance = 0.0;
    var arm = 0.309245;
    
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
        
        
        
        let angle = self.avgYaw2 - self.avgYaw1;
        switch chosenPicture {
        case 0:
            fatalError("No image selected, and yet a picture was taken.")
        case 1:
            firstImage.image = selectedImage
            
            self.firstYawVal = self.yawVal
            self.firstPitchVal = self.pitchVal
            self.firstRollVal = self.rollVal
            
            self.firstYaw.text = String(format:"Yaw = %.3f", self.firstYawVal)
            self.firstPitch.text = String(format:"Pitch = %.3f", self.firstPitchVal)
            self.firstRoll.text = String(format:"Roll = %.3f", self.firstRollVal)
            self.avgYaw1 = self.avg;
        case 2:
            secondImage.image = selectedImage
            
            self.secondYawVal = self.yawVal
            self.secondPitchVal = self.pitchVal
            self.secondRollVal = self.rollVal
            
            self.secondYaw.text = String(format:"Yaw = %.3f", self.secondYawVal)
            self.secondPitch.text = String(format:"Pitch = %.3f", self.secondPitchVal)
            self.secondRoll.text = String(format:"Roll = %.3f", self.secondRollVal)
            
            self.avgYaw2 = self.avg;
            
            distance = sqrt(abs(2*arm*arm-2*arm*arm*cos(angle)));
            self.deltaX.text = String(format:"DeltaX = %.3f, %0.3f", self.distance, angle)
            
            deltaYaw = acos(cos(firstYawVal)*cos(secondYawVal) + sin(firstYawVal)*sin(secondYawVal))
            deltaPitch = acos(cos(firstPitchVal)*cos(secondPitchVal) + sin(firstPitchVal)*sin(secondPitchVal))
            deltaRoll = acos(cos(firstRollVal)*cos(secondRollVal) + sin(firstRollVal)*sin(secondRollVal))
            
            secondImage.image = OpenCVWrapper.transform_Image(selectedImage, yaw: 0, pitch: 0, roll: 0)

            /*
            if ((firstYawVal > 0 && secondYawVal > 0) // both positive
                || (firstYawVal < 0 && secondYawVal < 0) // both negative
                || (firstYawVal > 0 && firstYawVal < M_PI_2 && secondYawVal > -M_PI_2) // between PI/2 and -PI/2
                || (secondYawVal > 0 && secondYawVal < M_PI_2 && firstYawVal > -M_PI_2))
            {
                deltaYaw = abs(firstYawVal - secondYawVal)
            }
            else if (firstYawVal > 0 && secondYawVal < 0)
            {
                secondYawVal += 2*M_PI
                deltaYaw = abs(firstYawVal - secondYawVal)
            }
            else
            {
                firstYawVal += 2*M_PI
                deltaYaw = abs(firstYawVal - secondYawVal)
            }
            
            if ((firstPitchVal > 0 && secondPitchVal > 0) // both positive
                || (firstPitchVal < 0 && secondPitchVal < 0) // both negative
                || (firstPitchVal > 0 && firstPitchVal < M_PI_2 && secondPitchVal > -M_PI_2) // between PI/2 and -PI/2
                || (secondPitchVal > 0 && secondPitchVal < M_PI_2 && firstPitchVal > -M_PI_2))
            {
                deltaPitch = abs(firstPitchVal - secondPitchVal)
            }
            else if (firstPitchVal > 0 && secondPitchVal < 0)
            {
                secondPitchVal += 2*M_PI
                deltaPitch = abs(firstPitchVal - secondPitchVal)
            }
            else
            {
                firstPitchVal += 2*M_PI
                deltaPitch = abs(firstPitchVal - secondPitchVal)
            }
            
            if ((firstRollVal > 0 && secondRollVal > 0) // both positive
                || (firstRollVal < 0 && secondRollVal < 0) // both negative
                || (firstRollVal > 0 && firstRollVal < M_PI_2 && secondRollVal > -M_PI_2) // between PI/2 and -PI/2
                || (secondRollVal > 0 && secondRollVal < M_PI_2 && firstRollVal > -M_PI_2))
            {
                deltaRoll = abs(firstRollVal - secondRollVal)
            }
            else if (firstRollVal > 0 && secondRollVal < 0)
            {
                secondRollVal += 2*M_PI
                deltaRoll = abs(firstRollVal - secondRollVal)
            }
            else
            {
                firstRollVal += 2*M_PI
                deltaRoll = abs(firstRollVal - secondRollVal)
            }*/
            self.distanceToClosest.text = String(format:"%.3f", self.deltaRoll)

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
        
        self.timeToCapture = true
        
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
            imagePicker.showsCameraControls = false;
            self.picturePicker = imagePicker;
            
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
                self.avg = avg;
                
                let variance = sMax-sMin;
                if (variance < self.mVariance)
                {
                    self.stable = true
                }
                else
                {
                    self.stable = false
                }
                
                if(!self.stable)
                {
                    
                    
                    //self.gyroRawX.text = String(format:"high: %f low: %f", sMax, sMin)
                }
                else
                {
                    if(self.picturePicker != nil)
                    {
                        if(self.picturePicker.isViewLoaded)// && self.timeToCapture)
                        {
                            self.picturePicker.takePicture()
                            self.timeToCapture = false
                        }
                    }
                    
                    //self.gyroRawX.text = String(format:"Yaw = %f : Stable", yaw)
                }
                //self.firstYaw.text = String(format:"Yaw = %.3f", (self.manager.deviceMotion?.attitude.yaw)!)
        }
        )

        
    }
}

