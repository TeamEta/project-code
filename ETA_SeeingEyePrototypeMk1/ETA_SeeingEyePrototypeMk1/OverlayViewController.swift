//
//  OverlayViewController.swift
//  ETA_SeeingEyePrototypeMk1
//
//  Created by Engineering on 4/12/17.
//  Copyright © 2017 Engineering. All rights reserved.
//

import UIKit

class OverlayViewController: UIViewController {

    @IBOutlet weak var overlayImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.overlayImage.image = globalImage
        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
