//
//  OpenCVWrapper.m
//  FoodTracker
//
//  Created by Micah on 2/1/17.
//  Copyright © 2017 Engineering. All rights reserved.
//
#import "opencv2/opencv.hpp"
#import "OpenCVWrapper.h"
#import "opencv2/imgcodecs/ios.h"
#import "opencv2/imgproc.hpp"
#import "opencv2/ximgproc/disparity_filter.hpp"
#include "math.h"
using namespace std;
using namespace cv;
using namespace cv::ximgproc;





//helper funcitons
cv::Rect computeROI(Size2i src_sz, Ptr<StereoMatcher> matcher_instance)
{
    int min_disparity = matcher_instance->getMinDisparity();
    int num_disparities = matcher_instance->getNumDisparities();
    int block_size = matcher_instance->getBlockSize();
    
    int bs2 = block_size/2;
    int minD = min_disparity, maxD = min_disparity + num_disparities - 1;
    
    int xmin = maxD + bs2;
    int xmax = src_sz.width + minD - bs2;
    int ymin = bs2;
    int ymax = src_sz.height - bs2;
    
    cv::Rect r(xmin, ymin, xmax - xmin, ymax - ymin);
    return r;
}

void rotateImage(const Mat &input, Mat &output, double alpha, double beta, double gamma, double dx, double dy, double dz, double f)

{
    
    //alpha = (alpha)*CV_PI/180.;
    //alpha = CV_PI/2.-alpha;
    //beta = (beta)*CV_PI/180.;
    //beta = beta-CV_PI/2;
    //gamma = (gamma)*CV_PI/180.;
    gamma = gamma+CV_PI/2;
    
    // get width and height for ease of use in matrices
    
    double w = (double)input.cols;
    
    double h = (double)input.rows;
    
    // Projection 2D -> 3D matrix
    
    Mat A1 = (Mat_<double>(4,3) <<
              
              1, 0, -w/2,
              
              0, 1, -h/2,
              
              0, 0,    1,
              
              0, 0,    1);
    
    // Rotation matrices around the X, Y, and Z axis
    
    Mat RX = (Mat_<double>(4, 4) <<
              
              1,          0,           0, 0,
              
              0, cos(alpha), -sin(alpha), 0,
              
              0, sin(alpha),  cos(alpha), 0,
              
              0,          0,           0, 1);
    
    Mat RY = (Mat_<double>(4, 4) <<
              
              cos(beta), 0, -sin(beta), 0,
              
              0, 1,          0, 0,
              
              sin(beta), 0,  cos(beta), 0,
              
              0, 0,          0, 1);
    
    Mat RZ = (Mat_<double>(4, 4) <<
              
              cos(gamma), -sin(gamma), 0, 0,
              
              sin(gamma),  cos(gamma), 0, 0,
              
              0,          0,           1, 0,
              
              0,          0,           0, 1);
    
    // Composed rotation matrix with (RX, RY, RZ)
    
    Mat R = RX * RY * RZ;
    
    // Translation matrix
    
    Mat T = (Mat_<double>(4, 4) <<
             
             1, 0, 0, dx,
             
             0, 1, 0, dy,
             
             0, 0, 1, dz,
             
             0, 0, 0, 1);
    
    // 3D -> 2D matrix
    
    /*Mat A2 = (Mat_<double>(3,4) <<
              
              f, 0, w/2, 0,
              
              0, f, h/2, 0,
              
              0, 0,   1, 0);*/
    
    Mat A2 = (Mat_<double>(3,4) <<
              
              f, 0, w/2, 0,
              
              0, f, h/2, 0,
              
              0, 0,   1, 0);
    
    // Final transformation matrix
    
    Mat trans = A2*(T * (R * A1));
    
    // Apply matrix transformation
    
    warpPerspective(input, output, trans, Size2i(input.cols, input.rows));
    
}


@implementation OpenCVWrapper

int max_x;
int max_y;

//simply returns the Open CV version as a string
+(NSString *) openCVVersionString
{
    return [NSString stringWithFormat:@"OpenCV Version %s", CV_VERSION];
}

//calculates a disparity map given 2 rectified images
+(void *) solveDisparity: (UIImage *) imageL imageRight:(UIImage *) imageR
{
    cv::Mat left, right, left_gray, right_gray, left_disp, right_disp;
    cv::Mat* disp;
    disp = new cv::Mat;
    if(imageL != nullptr && imageR != nullptr)
    {
        UIImageToMat( imageL, left);
        UIImageToMat(imageR, right);
    }
    
    
    cv::cvtColor(left, left_gray, CV_BGR2GRAY);
    cv::cvtColor(right, right_gray, CV_BGR2GRAY);
    
    //how many pixels in a square to match
    int window_size = 101;
    //int scl_fact = window_size*window_size;
    
    //fast method with search up to 256 pixels
    cv::Ptr<cv::StereoBM> sbm = cv::StereoBM::create(256, window_size);

    //all of the below values have to do with pre filtering out noise
    //sbm->setPreFilterCap(61);
    //sbm->setPreFilterSize(15);
    sbm->setMinDisparity(-39);
    
    //sbm->setTextureThreshold(1000);
    sbm->setUniquenessRatio(5);
    sbm->setSpeckleWindowSize(200);
    sbm->setSpeckleRange(1);
    
    //sbm->setDisp12MaxDiff(0);
    
    //compute the actual disparities
    sbm->compute(left_gray, right_gray, *disp);
    
    //slow but more information method
    //cv::Ptr<cv::StereoSGBM> sgbm = cv::StereoSGBM::create(0, 256, window_size);
    
    //sgbm->setPreFilterCap(61);
    //sgbm->setPreFilterSize(5);
    //sgbm->setMinDisparity(-39);
    
    //sgbm->setTextureThreshold(1000);
    //sgbm->setUniquenessRatio(0);
    //sgbm->setSpeckleWindowSize(15);
    //sgbm->setDisp12MaxDiff(1000000);
    //sgbm->setP1(24*window_size*window_size);
    //sgbm->setP2(96*window_size*window_size);
    //sgbm->setMode(StereoSGBM::MODE_SGBM_3WAY);
    //sgbm->setSpeckleRange(12);
    
    //sgbm->compute(left_gray, right_gray, *disp);
    
    /*
    Ptr<DisparityWLSFilter> wls_filter;
    
    //post filtered method
    wls_filter = cv::ximgproc::createDisparityWLSFilterGeneric(false);
    //Ptr<StereoMatcher> right_sbm = createRightMatcher(sbm);
    //sbm->setTextureThreshold(0);
    //sbm->setUniquenessRatio(0);
    
    cv::Rect ROI = computeROI(left_gray.size(), sbm);
    //wls_filter->setDepthDiscontinuityRadius((int)ceil(0.33*window_size));
    wls_filter->setDepthDiscontinuityRadius((int)ceil(0.5*window_size));
    
    sbm->compute(left_gray, right_gray, left_disp);
    //sgbm->compute(left_gray, right_gray, left_disp);
    //right_sbm->compute(right_gray, left_gray, right_disp);
    
    
    //cv::normalize(right_disp, *disp, 0, 255, CV_MINMAX, CV_8U);
    
    //filtering
    wls_filter->setLambda(8000.0);
    wls_filter->setSigmaColor(1.5);
    wls_filter->filter(left_disp, left_gray, *disp, Mat(), ROI);//*/
   
    
    //return the disparity map
    return disp;
}

//creates a visible image from the disparity map
+(UIImage *) get_image: (void *) mat
{
    cv::Mat disp8;
    cv::normalize(*((cv::Mat*)mat), disp8, 0, 255, CV_MINMAX, CV_8U);
    return MatToUIImage(disp8);
}

//calculates pixel distance via the MATLAB formula that Dr. Hamilton came up with
+(double) pix_dist: (double) p1x  pix1y:(double) p1y pix2x:(double) p2x pix2y:(double) p2y cent1x:(double) c1x cent1y:(double) c1y cent2x:(double) c2x cent2y:(double) c2y theta:(double) theta length:(double) L delta:(double) delta
{
    double AGLx = (p1x-c1x)*theta-delta/2;
    double AGRx = (p2x-c2x)*theta+delta/2;
    double AGLy = (p1y-c1y)*theta;
    double AGRy = (p2y-c2y)*theta;
    
    
    double alphaL = AGLy;
    double gammaL = AGLx;
    double alphaR = AGRy;
    double gammaR = AGRx;
    double thetaL = M_PI -  acos(cos(alphaL)*sin(gammaL));
    double thetaR = acos(cos(alphaR)*sin(gammaR));
    double d = (L/2)*sqrt(1-4*cos(thetaL + thetaR)*sin(thetaR)*sin(thetaL)/pow(sin(thetaL+thetaR), 2));
    
    return d;
}

//returns disparity from a disparity map range is +-2048.9374 with steps of 0.0625
+(double) get_disparity: (void *) disp px:(double) posx py:(double) posy
{
    return ((double)((cv::Mat *)disp)->at<short>(posy, posx))/((double)16);
}

//gets the maximum(closest) value from a disparity map, hasn't been tested yet
+(double) get_max_disparity: (void *) disp
{
    cv::Mat* disp_array = (cv::Mat*)disp;
    double maxim = 0.0;
    double value;
    
    for(int y=0; y<disp_array->rows; y++)
    {
        for(int x=0; x<disp_array->cols; x++)
        {
            value = disp_array->at<short>(y, x)/16.0;
            if(value>maxim && value < 200)
            {
                
                max_x = x;
                max_y = y;
                maxim = value;
            }
        }
    }
    
    
    return maxim;
}

+(int) get_max_x
{
    return max_x;
}

+(int) get_max_y
{
    return max_y;
}


//frees up the memory from creating a cv::Mat
+(void) destroy_mat: (void *) thing
{
    delete (cv::Mat*) thing;
}




/*+(UIImage *) transform_Image: (UIImage*) image yaw:(double) yaw pitch:(double) pitch roll:(double) roll
{
    cv::Mat source;
    cv::Mat result;
    
    UIImageToMat(image, source);
    
    rotateImage(source, result, 0, 0, 0, 0, 0, 100, 0);
    
    /*
    /*cv::Matx33d mPitch(1,0,0,0, cos(pitch), -sin(pitch), 0, sin(pitch), cos(pitch));
    cv::Matx33d mYaw(cos(yaw), 0, sin(yaw), 0,1,0, -sin(yaw), 0, cos(yaw));
    cv::Matx33d mRoll(cos(roll), -sin(roll), 0, sin(roll), cos(roll), 0, 0, 0, 1);
    //cv::Matx33d mRoll(1, 0, 0, 0, 1, 0, 0, 0, 1);
    
    cv::Matx33d rotation =  mYaw * (mPitch * mRoll);
 
    Matx33d rotation;
    
    cv::Rodrigues(Matx31d (0,0,0), rotation);
    
    cv::Mat A1 = (Mat_<double>(3,3) <<
                  1, 0, -w/2,
                  0, 1, -h/2,
                  0, 0, 1);*/

+(UIImage *) transform_image: (UIImage*) image yaw:(double) yaw pitch:(double) pitch roll:(double) roll
{
    cv::Mat source, result;
    UIImageToMat(image, source);
    /*
    Point2f inputQuad[4];
    Point2f outputQuad[4];
    
    Mat transform;
    
    cv::Matx44d mPitch(1,        0,          0,           0,
                       0,        cos(pitch), -sin(pitch), 0,
                       0,        sin(pitch), cos(pitch),  0,
                       0,        0,          0,           1);
    
    cv::Matx44d mYaw( cos(yaw),  0,          sin(yaw),    0,
                      0,         1,          0,           0,
                      -sin(yaw), 0,          cos(yaw),    0,
                      0,         0,          0,           1
                     );
    cv::Matx44d mRoll(cos(roll), -sin(roll), 0,           0,
                      sin(roll), cos(roll),  0,           0,
                      0,         0,          1,           0,
                      0,         0,          0,           1);
    
    cv::Matx44d center(1,         0,          0,           -(source.cols-1),
                      0,         1,          0,           -(source.rows-1),
                      0,         0,          1,           0,
                      0,         0,          0,           1);
    
    cv::Matx44d rotation =  (mYaw * (mPitch * mRoll));
    
    
    cv::Mat result;
    
    outputQuad[0] = Point2f(0,0);
    outputQuad[1] = Point2f(source.cols-1,0);
    outputQuad[2] = Point2f(source.cols-1,source.rows);
    outputQuad[3] = Point2f(0,0);
    
    
    cv::Matx14d point1(-(source.cols-1)/2, (source.rows-1)/2, 0, 1);
    cv::Matx14d point2(-(source.cols-1)/2, (source.rows-1)/2, 0, 1);
    cv::Matx14d point3(-(source.cols-1)/2, (source.rows-1)/2, 0, 1);
    cv::Matx14d point4(-(source.cols-1)/2, (source.rows-1)/2, 0, 1);
    
    point1 = point1 * rotation;
    point2 = point2 * rotation;
    point3 = point3 * rotation;
    point4 = point4 * rotation;
    
    inputQuad[0] = Point2f(point1.val[0], point1.val[1]);
    inputQuad[1] = Point2f(point2.val[0], point2.val[1]);
    inputQuad[2] = Point2f(point3.val[0], point3.val[1]);
    inputQuad[3] = Point2f(point4.val[0], point4.val[1]);
    
    Mat trans = cv::getPerspectiveTransform(outputQuad, inputQuad);*/
    Mat trans;
    rotateImage(source, result, pitch, yaw, roll, 0, 0, 2000, 2000);
    
    
    //cv::warpPerspective(source, result, trans, Size2i(2000,2000));

    
    return MatToUIImage(result);
}

+(double) calculate_rectification: (UIImage *) image1 image2:(UIImage *) image2
{
    Mat img1, img2, gray1, gray2;
    UIImageToMat(image1, img1);
    UIImageToMat(image2, img2);
    
    int img_y = img1.rows-1;
    int img_x = img1.cols-1;
    
    cv::cvtColor(img1, gray1, CV_BGR2GRAY);
    cv::cvtColor(img2, gray2, CV_BGR2GRAY);
    
    int srch = 201;
    double avg = 0.0;
    int best_fitness = INT_MAX;
    int value = 0;
    for(int i=img_y/2; i<img_y-srch; i++)
    {
        
        
        for(int y=i-srch; y<i+srch; y++)
        {
            if(y<0)
            {
                y=0;
            }
            if(y>img_y)
            {
                break;
            }

            int fitness = 0;
           
            for(int x=0; x<img_x; x++)
            {
                fitness+=abs((int)img1.at<unsigned char>(i, x)-(int)img2.at<unsigned char>(y, x));
                
            }
            
            if (fitness<best_fitness && fitness!=0)
            {
                best_fitness = fitness;
                value = y-i;
            }
            
        }
        if(value!=0 && value <= srch && value >= -srch)
        {
            if(avg == 0)
            {
                avg = (double)value;
            }
            else
            {
                avg=(double)(avg+value)/2.0;
            }
        }
    }
    return value;
}

@end


