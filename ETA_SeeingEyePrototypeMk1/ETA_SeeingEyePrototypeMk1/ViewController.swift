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

var globalImage: UIImage? = nil

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
        
    var posx1: Double = 0
    var posy1: Double = 0
    
    var posx2: Double = 0
    var posy2: Double = 0
    
    var first: Bool = true;
    var disparityPresent = false;
    var secondImageDisparity = false
    
    var picturePicker: UIImagePickerController!
    
    var timeToCapture: Bool = false
    
    var yawVal: Double = 0.0
    var pitchVal: Double = 0.0
    var rollVal: Double = 0.0
    
    var sYaw: Double = 1.0;
    var sPitch: Double = 1.0;
    var sRoll: Double = 1.0;
    
    
    var firstYawVal: Double = 0.0
    var firstPitchVal: Double = 0.0
    var firstRollVal: Double = 0.0
    
    var secondYawVal: Double = 0.0
    var secondPitchVal: Double = 0.0
    var secondRollVal: Double = 0.0
    
    var deltaYawAvg: Double = 0.0
    var deltaYaw: Double = 0.0
    var deltaPitch: Double = 0.0
    var deltaRoll: Double = 0.0
    
    var nSamples = 50
    var nAccSample = 64
    var mVariance = 0.175
    var gyroSamples = Array<Double> ()
    
    var xSamples = Array<Double> ()
    var ySamples = Array<Double> ()
    var zSamples = Array<Double> ()
    
    var stable = false;
    
    var avgYaw1 = 0.0;
    var avgYaw2 = 0.0;
    var avg = 0.0;
    
    var ax = 0.0;
    var ay = 0.0;
    var az = 0.0;
    
    var x = 0.0;
    var y = 0.0;
    var z = 0.0;
    
    
    var avgx = 0.0;
    var avgy = 0.0;
    var avgz = 0.0;
    
    var velx = 0.0;
    var vely = 0.0;
    var velz = 0.0;
    
    //how far the human is suppose to move the camera
    let expect_distance = 0.0586;
    var distance = 0.0;
    
    
    //how much to trust the sensor readings
    let trust = 0.10
    //how much the human is expected to err by
    let error = 0.10
    var arm = 0.309245;
    
    var chosenPicture: Int = 2
    
    var disp_map = UnsafeMutableRawPointer.allocate(bytes: Int(OpenCVWrapper.mat_size()), alignedTo: 1);
    
    var integrate = false;
    var lastTime = 0.0;
    
    //MARK: UIImagePickerControllerDelegate
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        //Dismiss this picker if the user cancels
        dismiss(animated: true, completion: nil)
        
    }
    
    func resetDistance()
    {
        x = 0.0;
        y = 0.0;
        z = 0.0;
        
        velx = 0.0;
        vely = 0.0;
        velz = 0.0;
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        
        // The info dictionary may contain multiple representations of the image. You want to use the original.
        dismiss(animated: true, completion: nil)
        guard let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
        
        
        
        
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
            
            distance = (-x * trust) + (expect_distance * (1.0-trust))
            if(distance > expect_distance + expect_distance*error || distance < expect_distance - expect_distance*error )
            {
                distance = expect_distance;
            }
            
            
            integrate = false;
            
            if(first)
            {
                disp_map.deallocate(bytes: Int(OpenCVWrapper.mat_size()), alignedTo: 1)
                first = false;
            }
            else
            {
                OpenCVWrapper.destroy_mat(disp_map);
            }
            
            if(x>0)
            {
                distance = expect_distance
            }
            
            secondImage.image = selectedImage
            //globalImage = selectedImage
            secondImageDisparity = false
            
            self.secondYawVal = self.yawVal
            self.secondPitchVal = self.pitchVal
            self.secondRollVal = self.rollVal
            
            
            
            self.avgYaw2 = self.avg;
            let angle = acos(cos(self.avgYaw1)*cos(self.avgYaw2) + sin(self.avgYaw1)*sin(self.avgYaw2))
            
            
            //distance = sqrt(abs(2*arm*arm-2*arm*arm*cos(angle)));
            self.deltaX.text = String(format:"DeltaX = %.3f, %0.3f", self.distance, angle)
            
            deltaYaw = acos(cos(firstYawVal)*cos(secondYawVal) + sin(firstYawVal)*sin(secondYawVal))
            deltaPitch = acos(cos(firstPitchVal)*cos(secondPitchVal) + sin(firstPitchVal)*sin(secondPitchVal))
            deltaRoll = acos(cos(firstRollVal)*cos(secondRollVal) + sin(firstRollVal)*sin(secondRollVal))
            
            
            self.secondYaw.text = String(format:"dYaw = %.3f", deltaYaw)
            self.secondPitch.text = String(format:"dPitch = %.3f", deltaPitch)
            self.secondRoll.text = String(format:"dRoll = %.3f", distance)
            //deltaRoll = 0;
            //deltaYaw = 0;
            //deltaPitch = 0;
            
            deltaYawAvg = 0;
            
            if(self.firstYawVal < self.secondYawVal)
            {
                self.sYaw = 1.0;
            }
            else
            {
                self.sYaw = -1.0;
            }
            
            if(self.firstRollVal < self.secondRollVal)
            {
                self.sRoll = -1.0;
            }
            else
            {
                self.sRoll = 1.0;
            }
            
            if(self.firstPitchVal < self.secondPitchVal)
            {
                self.sPitch = -1.0;
            }
            else
            {
                self.sPitch = 1.0;
            }
            
            //firstImage.image = OpenCVWrapper.transform_image(firstImage.image, yaw: self.sYaw*deltaYaw/8, pitch: self.sPitch*deltaPitch/8, roll: self.sRoll*deltaRoll/8);
            //secondImage.image = OpenCVWrapper.transform_image(secondImage.image, yaw: -self.sYaw*deltaYaw/8, pitch: -self.sPitch*deltaPitch/8, roll: -self.sRoll*deltaRoll/8);
            
            firstImage.image = OpenCVWrapper.rotate_image(firstImage.image, yaw: self.sYaw*deltaYaw/8, pitch: self.sPitch*deltaPitch/2, roll: self.sRoll*deltaRoll/2);
            secondImage.image = OpenCVWrapper.rotate_image(secondImage.image, yaw: -self.sYaw*deltaYaw/8, pitch: -self.sPitch*deltaPitch/2, roll: -self.sRoll*deltaRoll/2);
            globalImage = secondImage.image
            //var disp_map : UnsafeMutableRawPointer;
             //dismiss(animated: true, completion: nil)
            
            //var disp_map : UnsafeMutableRawPointer;
            //if(self.sPitch < 0)
            //{
                disp_map = OpenCVWrapper.solveDisparity(firstImage.image, imageRight: secondImage.image);
            //}
            //else
            //{
                //disp_map = OpenCVWrapper.solveDisparity(secondImage.image, imageRight: firstImage.image);
            //}

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
            
            let disp = OpenCVWrapper.get_max_disparity(disp_map);
            let dist = OpenCVWrapper.pix_dist((Double)(OpenCVWrapper.get_max_x()*10), pix1y: (Double)(OpenCVWrapper.get_max_y()*10), pix2x: (Double)(OpenCVWrapper.get_max_x()*10)+disp*10, pix2y: (Double)(OpenCVWrapper.get_max_y()*10), cent1x: (Double)(secondImage.image!.size.width*10)/2.0, cent1y: (Double)(secondImage.image!.size.height*10)/2.0, cent2x: (Double)(secondImage.image!.size.width*10)/2.0, cent2y: (Double)(secondImage.image!.size.height*10)/2.0, theta: 0.0004163, length: self.distance, delta: 0)
            
            //let dy = OpenCVWrapper.calculate_rectification(firstImage.image, image2: secondImage.image)
            
            
            self.distanceToClosest.text = String(format:"%.3f : %.3f", disp, 440.0/disp)

            //DispImage.image = OpenCVWrapper.get_image(disp_map);
            
            //self.secondYaw.text = String(format:"X = %.3f", self.x)
            //self.secondPitch.text = String(format:"Y = %.3f", self.y)
            //self.secondRoll.text = String(format:"Z = %.3f", self.z)
            
            disparityPresent = true
            
            //DispImage.image = OpenCVWrapper.get_image(disp_map);
            
            //OpenCVWrapper.destroy_mat(disp_map);

        default:
            fatalError("Expected chosenPicture to be updated with the picture chosen.")
        }
        
        // Dismiss the picker
       
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
    //@IBOutlet weak var DispImage: UIImageView!
    
    @IBAction func switchToDisparityMap(_ sender: UIButton) {
        let localImage: UIImage? = firstImage.image
        
        if (disparityPresent && !secondImageDisparity)
        {
            secondImageDisparity = true
            secondImage.image = OpenCVWrapper.get_image(disp_map)
            firstImage.image = OpenCVWrapper.get_image(disp_map)
            firstImage.image = localImage
        }
        else if (disparityPresent && secondImageDisparity)
        {
            secondImageDisparity = false
            secondImage.image = globalImage
        }
    }
    
    @IBAction func takePictureButtonPressed(_ sender: UIButton) {
        switch chosenPicture {
        case 0:
            chosenPicture = 1
        case 1:
            chosenPicture = 2
        case 2:
            chosenPicture = 1
            integrate = true;
            resetDistance();
        default:
            fatalError("Expected chosenPicture to be updated with the picture chosen.")
        }
        
        self.timeToCapture = true
        
        capturePhoto()
        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.captureDidLoad), userInfo: nil, repeats: false);
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

    func captureDidLoad()
    {
        self.picturePicker.takePicture()
    }
    
    //MARK: Navigation
    
    // This method lets you configure a view controller before it's presented.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        manager.stopDeviceMotionUpdates()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tGR1 = UITapGestureRecognizer(target: self, action: #selector(image1Tapped(TGR:)))
        firstImage.isUserInteractionEnabled = true
        firstImage.addGestureRecognizer(tGR1)
        
        let tGR2 = UITapGestureRecognizer(target: self, action: #selector(image2Tapped(TGR:)))
        secondImage.isUserInteractionEnabled = true
        secondImage.addGestureRecognizer(tGR2)
        
        //let tGR3 = UITapGestureRecognizer(target: self, action: #selector(image3Tapped(TGR:)))
        //DispImage.isUserInteractionEnabled = true
        //DispImage.addGestureRecognizer(tGR3)

        firstImage.image = OpenCVWrapper.transform_image(firstImage.image, yaw: 0, pitch: 0, roll: 0)
        
        manager.deviceMotionUpdateInterval = 0.01
        manager.startDeviceMotionUpdates(to: OperationQueue.main, withHandler:
            {deviceManager, error in
                //self.yawVal = (self.manager.deviceMotion?.attitude.yaw)!
                //self.pitchVal = (self.manager.deviceMotion?.attitude.pitch)!
                //self.rollVal = (self.manager.deviceMotion?.attitude.roll)!
                
                //ok time to be crazy and use quaternions
                let quat : CMQuaternion = (self.manager.deviceMotion?.attitude.quaternion)!;
                
                self.yawVal = atan2(2*(quat.x*quat.y + quat.z*quat.w), 1 - 2*(quat.y*quat.y + quat.z*quat.z));
                self.pitchVal = atan2(2*(quat.x*quat.w + quat.y*quat.z), 1 - 2*(quat.z*quat.z + quat.w * quat.w));
                self.rollVal = asin(2*(quat.x*quat.z - quat.w*quat.y));
                
                var iax = self.avgx
                var iay = self.avgy
                var iaz = self.avgz
                var ivy = self.vely
                var ivx = self.velx
                var ivz = self.velz
                let ipx = self.x
                let ipy = self.y
                let ipz = self.z
                
                //calculate global acceleration values
                let matr = (self.manager.deviceMotion?.attitude.rotationMatrix)!
                var lax = (self.manager.deviceMotion?.userAcceleration.x)!
                var lay = (self.manager.deviceMotion?.userAcceleration.y)!
                var laz = (self.manager.deviceMotion?.userAcceleration.z)!
                
                
                
                if(lax < 0.01 && lax > -0.01)
                {
                    lax = 0
                }
                if(lay < 0.01 && lay > -0.01)
                {
                    lay = 0
                }
                if(laz < 0.01 && laz > -0.01)
                {
                    laz = 0
                }
                
                
                let yaw = self.yawVal;
                
                
                self.gyroSamples.append(yaw)
                if(self.gyroSamples.count > self.nSamples)
                {
                    self.gyroSamples.remove(at: 0)
                }
                
                self.xSamples.append(lax)
                if(self.xSamples.count > self.nAccSample)
                {
                    self.xSamples.remove(at: 0)
                }
                self.ySamples.append(lay)
                if(self.ySamples.count > self.nAccSample)
                {
                    self.ySamples.remove(at: 0)
                }
                self.zSamples.append(laz)
                if(self.zSamples.count > self.nAccSample)
                {
                    self.zSamples.remove(at: 0)
                }
                
                
                var sMax = abs(self.gyroSamples[0])
                var sMin = abs(self.gyroSamples[0])
                var avg = 0.0
                self.avgx = self.xSamples[0];
                self.avgy = self.ySamples[0];
                self.avgz = self.zSamples[0];
                
                var o = 0.0
                
                var cx = 0;
                var cy = 0;
                var cz = 0;
                
                for i in 1..<self.ySamples.count
                {
                    if(self.xSamples[i] == 0)
                    {
                        cx += 1;
                    }
                    if(self.ySamples[i] == 0)
                    {
                        cy += 1;
                    }
                    if(self.zSamples[i] == 0)
                    {
                        cz += 1;
                    }
                    
                    self.avgx += self.xSamples[i]
                    self.avgy += self.ySamples[i]
                    self.avgz += self.zSamples[i]
                }
                
                self.avgx = 9.81*self.avgx/Double(self.nAccSample);
                self.avgy = 9.81*self.avgy/Double(self.nAccSample);
                self.avgz = 9.81*self.avgz/Double(self.nAccSample);
                
                if(cx >= 25)
                {
                    self.velx = 0
                    ivx = 0;
                }
                if(cy >= 25)
                {
                    self.vely = 0
                    ivy = 0;
                }
                if(cz >= 25)
                {
                    self.velz = 0
                    ivz = 0;
                }
                
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
                        if(self.picturePicker.isViewLoaded && self.timeToCapture)
                        {
                            
                            self.timeToCapture = false
                            
                            
                        }
                    }
                    
                    //self.gyroRawX.text = String(format:"Yaw = %f : Stable", yaw)
                }

                
                if(self.integrate)
                {
                    
                    var gax = iax*matr.m11 + iay*matr.m21 + iaz*matr.m31;
                    var gay = iax*matr.m12 + iay*matr.m22 + iaz*matr.m32;
                    var gaz = iax*matr.m13 + iay*matr.m23 + iaz*matr.m33;
                    gax = gax * 9.81
                    gay = gay * 9.81
                    gaz = gaz * 9.81
                    
                    //iax = iax
                    //iay = iay
                    //iaz = iaz
                    
                    
                    let dt = (self.manager.deviceMotion?.timestamp)! - self.lastTime;
                    /*self.velx = ivx + iax + (self.avgx - iax/2)
                    self.vely = ivy + iay + (self.avgy - iay/2)
                    self.velx = ivz + iaz + (self.avgz - iaz/2)
                    
                    self.x = ipx + ivx + (self.velx - ivx/2)
                    self.y = ipy + ivy + (self.vely - ivy/2)
                    self.z = ipz + ivz + (self.velz - ivz/2)*/
                    
                    self.velx = ivx + (self.avgx + iax)/2*dt;
                    self.x = ipx + (self.velx + ivx)/2*dt;
                    
                    self.vely = ivy + (self.avgy + iay)/2*dt;
                    self.y = ipy + (self.vely + ivy)/2*dt;
                    self.velz = ivz + (self.avgz + iaz)/2*dt;
                    self.z = ipz + (self.velz + ivz)/2*dt;
                    
                }
                
                let deltaYaw = acos(cos(self.firstYawVal)*cos(self.yawVal) + sin(self.firstYawVal)*sin(self.yawVal))
                let deltaPitch = acos(cos(self.firstPitchVal)*cos(self.pitchVal) + sin(self.firstPitchVal)*sin(self.pitchVal))
                let deltaRoll = acos(cos(self.firstRollVal)*cos(self.rollVal) + sin(self.firstRollVal)*sin(self.rollVal))
                
                self.firstYaw.text = String(format:"Yaw = %.3f", self.x)
                self.firstPitch.text = String(format:"Pitch = %.3f", self.y)
                self.firstRoll.text = String(format:"Roll = %.3f", self.z)
                self.lastTime = (self.manager.deviceMotion?.timestamp)!
                //self.firstYaw.text = String(format:"Yaw = %.3f", (self.manager.deviceMotion?.attitude.yaw)!)
        }
        )

        
    }
    
    func image1Tapped(TGR: UITapGestureRecognizer)
    {
        
        imageTapped(TGR: TGR, id:  1)
        globalImage = self.firstImage.image!
        //imageTapped(TGR: TGR, isFirst:  true)
    }
    
    func image2Tapped(TGR: UITapGestureRecognizer)
    {
        
        imageTapped(TGR: TGR, id : 2)
        globalImage = self.secondImage.image!
        //imageTapped(TGR: TGR, isFirst : false)
        
        
    }
    
    func image3Tapped(TGR: UITapGestureRecognizer)
    {
        
        imageTapped(TGR: TGR, id : 3)
    }
    
    
    //called every time the image is tapped
    func imageTapped(TGR: UITapGestureRecognizer, id img : Int)
    {
        //get the point touched on the image
        let tappedImage = TGR.view as! UIImageView
        let touchPoint = TGR.location(in: tappedImage);
        
        let width = Double((tappedImage.image?.size.width)!);
        let height = Double((tappedImage.image?.size.height)!);
        
        //get the scale factor from screen space to image space
        let scalex = Double(tappedImage.frame.size.width) / width;
        let scaley = Double(tappedImage.frame.size.height) / height;
        
        
  
        //get the original x,y coordinates from the tapped x,y coordinates
        let posx = Double(touchPoint.x) / scalex
        let posy = Double(touchPoint.y) / scaley
        var dist = 0.0
        
        if(!secondImageDisparity)
        {
            if(img == 1)
            {
                posx1=posx
                posy1=posy
            }
            else
            {
                posx2=posx
                posy2=posy
            }
            
            dist = OpenCVWrapper.pix_dist(posx1, pix1y: posy1, pix2x: posx2, pix2y: posy2, cent1x: width/2.0, cent1y: height/2.0, cent2x: width/2.0, cent2y: height/2.0, theta: 0.0004163*5, length: 0.09, delta: 0)
            
            //self.deltaX.text = String(format:"%.3f, %0.3f", deltaYawAvg, 0)
            self.distanceToClosest.text = String(format:"%.3f : %.3f", distance, dist)
            
        }
        
        else
        {
            //let disp_map = OpenCVWrapper.solveDisparity(firstImage.image, imageRight: secondImage.image);
            let disp = OpenCVWrapper.get_disparity(disp_map, px: posx, py: posy)
            dist = OpenCVWrapper.pix_dist(posx, pix1y: posy, pix2x: posx+disp, pix2y: posy, cent1x: width/2.0, cent1y: height/2.0, cent2x: width/2.0, cent2y: height/2.0, theta: 0.0004163, length: self.distance, delta: 0)
            //self.distanceToClosest.text = String(format:"%.3f : %.3f", disp, (440.0/disp)*0.31)
            //self.deltaX.text = String(format:"%.3f, %0.3f", width, height)
            self.distanceToClosest.text = String(format:"Distance: %.3f", (665.529*distance/disp))
            self.deltaX.text = String(format:"Pixel Delta: %0.3f", disp)
        }
        
        
        
        
    }
}

