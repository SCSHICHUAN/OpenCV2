//
//  openCV.cpp
//  FirstOpenCV
//
//  Created by Stan on 2023/8/12.
//

#include "openCV.hpp"
#include <iostream>
#include <stdio.h>


using namespace std;
using namespace cv;
const double PI = 3.141592653589793;


Mat unfold_fish_eye_image(CVPixelBufferRef buffer){
    
    cv::Mat mat;

    CVPixelBufferLockBaseAddress(buffer, 0);

    void *address = CVPixelBufferGetBaseAddress(buffer);
    int width = (int) CVPixelBufferGetWidth(buffer);
    int height = (int) CVPixelBufferGetHeight(buffer);

    mat   = cv::Mat(height, width, CV_8UC4, address, 0);
    

    CVPixelBufferUnlockBaseAddress(buffer, 0);


    return unfold_fish_eye_image(mat);
}



//Find the corresponding fisheye outpout point corresponding to an input cartesian point
Point2f findFisheye(int Xe, int Ye, double R, double Cfx, double Cfy, double He, double We){
    Point2f fisheyePoint;
    double theta, r, Xf, Yf; //Polar coordinates

    r = Ye/He*R;
    theta = Xe/We*2.0*PI;
    Xf = Cfx+r*sin(theta);
    Yf = Cfy+r*cos(theta);
    fisheyePoint.x = Xf;
    fisheyePoint.y = Yf;

    return fisheyePoint;
}

Mat unfold_fish_eye_image(Mat fisheyeImage){

    Mat equirectangularImage;
//    fisheyeImage = imread(PATH_IMAGE, IMREAD_COLOR);
//    cv::cvtColor(fisheyeImage, fisheyeImage, IMREAD_COLOR);

    float Hf, Wf, He, We;
    double R, Cfx, Cfy;

    Hf = fisheyeImage.size().height;
    Wf = fisheyeImage.size().width;
    R = Hf/2.0; //The fisheye image is a square of 1400x1400 pixels containing a circle so the radius is half of the width or height size
    Cfx = Wf/2.0; //The fisheye image is a square so the center in x is located at half the distance of the width
    Cfy = Hf/2.0; //The fisheye image is a square so the center in y is located at half the distance of the height

    He = (int)R * 1.5;
    We = (int)2*PI*R;

    equirectangularImage.create(He, We, fisheyeImage.type());

    for (int Xe = 0; Xe <equirectangularImage.size().width; Xe++){
        for (int Ye = 0; Ye <equirectangularImage.size().height; Ye++){
            equirectangularImage.at<Vec4b>(cv::Point(Xe, Ye)) =  fisheyeImage.at<Vec4b>(findFisheye(Xe, Ye, R, Cfx, Cfy, He, We));
        }
    }

    return equirectangularImage;
}

