//
//  OpenCVWrapper.h
//  FoodTracker
//
//  Created by Micah on 2/1/17.
//  Copyright © 2017 Engineering. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface OpenCVWrapper : NSObject

//returns OpenCV version as a string
+(NSString *) openCVVersionString;

//returns a disparity map as an image
+(void *) solveDisparity: (UIImage *) imageL imageRight:(UIImage *) imageR;

//creates a visible image from the disparity map
+(UIImage *) get_image: (void *) mat;

//returns a distance of a pixel based on Dr. Hamiltons MATLAB code
+(double) pix_dist: (double) p1x  pix1y:(double) p1y pix2x:(double) p2x pix2y:(double) p2y cent1x:(double) c1x cent1y:(double) c1y cent2x:(double) c2x cent2y:(double) c2y theta:(double) theta length:(double) L delta:(double) delta;

//returns disparity from a disparity map range is +-2048.9374 with steps of 0.0625
+(double) get_disparity: (void *) disp px:(double) posx py:(double) posy;

//gets the maximum(closest) value from a disparity map, hasn't been tested yet
+(double) get_max_disparity: (void *) disp;

//frees up the memory from creating a cv::Mat
+(void) destroy_mat: (void *) thing;

+(UIImage *) transform_image: (UIImage*) image yaw:(double) yaw pitch:(double) pitch roll:(double) roll;

+(int) get_max_x;

+(int) get_max_y;

+(double) calculate_rectification: (UIImage *) image1 image2:(UIImage *) image2;

+(UIImage*) rotate_image: (UIImage *) image1;

+(int) mat_size;

@end
