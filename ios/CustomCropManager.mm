// #import <opencv2/opencv.hpp>
#import "CustomCropManager.h"
#import <React/RCTLog.h>
#import <React/RCTConvert.h>

#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <GLKit/GLKit.h>

@implementation CustomCropManager

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(crop:(NSDictionary *)points imageURI:(NSString *)imageURI callback:(RCTResponseSenderBlock)callback)
{
    UIImage *image = [UIImage imageWithContentsOfFile:imageURI];
    image = [self fixOrientation:image];

    CIImage *ciImage = [[CIImage alloc] initWithImage:image];

    NSMutableDictionary *rectangleCoordinates = [NSMutableDictionary new];
    // CGPoint tl = CGPointMake([RCTConvert CGFloat:points[@"topLeft"][@"x"]], [self getCartesianPoint:[RCTConvert CGFloat:points[@"topLeft"][@"y"]] withHeight:image.size.height]);
    CGPoint tl = [self getCartesianPoint2:points[@"topLeft"] withHeight: image.size.height];
    CGPoint tr = [self getCartesianPoint2:points[@"topRight"] withHeight: image.size.height];
    CGPoint bl = [self getCartesianPoint2:points[@"bottomLeft"] withHeight: image.size.height];
    CGPoint br = [self getCartesianPoint2:points[@"bottomRight"] withHeight: image.size.height];
    // CGPoint tr = CGPointMake([RCTConvert CGFloat:points[@"topRight"][@"x"]], [self getCartesianPoint:[RCTConvert CGFloat:points[@"topRight"][@"y"]] withHeight:image.size.height]);
    // CGPoint bl = CGPointMake([RCTConvert CGFloat:points[@"bottomLeft"][@"x"]], [self getCartesianPoint:[RCTConvert CGFloat:points[@"bottomLeft"][@"y"]] withHeight:image.size.height]);
    // CGPoint br = CGPointMake([RCTConvert CGFloat:points[@"bottomRight"][@"x"]], [self getCartesianPoint:[RCTConvert CGFloat:points[@"bottomRight"][@"y"]] withHeight:image.size.height]);

    rectangleCoordinates[@"inputTopLeft"] = [CIVector vectorWithCGPoint:tl];
    rectangleCoordinates[@"inputTopRight"] = [CIVector vectorWithCGPoint:tr];
    rectangleCoordinates[@"inputBottomLeft"] = [CIVector vectorWithCGPoint:bl];
    rectangleCoordinates[@"inputBottomRight"] = [CIVector vectorWithCGPoint:br];


    


    CIImage *enhancedImage = [ciImage imageByApplyingFilter:@"CIPerspectiveCorrection" withInputParameters:rectangleCoordinates];

    UIGraphicsBeginImageContext(CGSizeMake(enhancedImage.extent.size.width, enhancedImage.extent.size.height));
    [[UIImage imageWithCIImage:enhancedImage scale:1.0 orientation:UIImageOrientationUp] drawInRect:CGRectMake(0,0, enhancedImage.extent.size.width, enhancedImage.extent.size.height)];
    UIImage *image2 = UIGraphicsGetImageFromCurrentImageContext();

    NSData *croppedImageData = UIImageJPEGRepresentation(image2, 1.0);
    NSString *croppedFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"cropped_img_%i.jpeg",(int)[NSDate date].timeIntervalSince1970]];

    [croppedImageData writeToFile:croppedFilePath atomically:YES];

    callback(@[[NSNull null], @{@"image": croppedFilePath}]);

    // NSString *updatedCroppedFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"updated_cropped_img_%i.jpeg",(int)[NSDate date].timeIntervalSince1970]];
    // [imageToEncode writeToFile:updatedCroppedFilePath atomically:YES];
    // callback(@[[NSNull null], @{@"image": updatedCroppedFilePath}]);
    // UIImage* convertedImage = [self UIImageFromCVMat:mat];
    // NSData *imageToEncode = UIImageJPEGRepresentation(convertedImage, 0.8);
    // callback(@[[NSNull null], @{@"image": [imageToEncode base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength]}]);
}
- (CGFloat)getCartesianPoint:(CGFloat)point withHeight:(CGFloat)height {
    return height - point;
}
- (CGPoint)getCartesianPoint2:(NSDictionary *)point withHeight:(CGFloat)height {
    return CGPointMake([RCTConvert CGFloat:point[@"x"]], height - [RCTConvert CGFloat:point[@"y"]]);
}
- (UIImage *)fixOrientation:(UIImage *)srcImg {
    if (srcImg.imageOrientation == UIImageOrientationUp) {
        return srcImg;
    }

    CGAffineTransform transform = CGAffineTransformIdentity;
    switch (srcImg.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, srcImg.size.width, srcImg.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;

        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, srcImg.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;

        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, srcImg.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }

    switch (srcImg.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, srcImg.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;

        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, srcImg.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }

    CGContextRef ctx = CGBitmapContextCreate(NULL, srcImg.size.width, srcImg.size.height, CGImageGetBitsPerComponent(srcImg.CGImage), 0, CGImageGetColorSpace(srcImg.CGImage), CGImageGetBitmapInfo(srcImg.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (srcImg.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            CGContextDrawImage(ctx, CGRectMake(0,0,srcImg.size.height,srcImg.size.width), srcImg.CGImage);
            break;

        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,srcImg.size.width,srcImg.size.height), srcImg.CGImage);
            break;
    }

    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}


// - (cv::Mat)cvMatFromUIImage:(UIImage *)image
// {
//     CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
//     CGFloat cols = image.size.width;
//     CGFloat rows = image.size.height;
    
//     cv::Mat cvMat(rows, cols, CV_8UC4);
    
//     CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,
//                                                     cols,
//                                                     rows,
//                                                     8,
//                                                     cvMat.step[0],
//                                                     colorSpace,
//                                                     kCGImageAlphaNoneSkipLast |
//                                                     kCGBitmapByteOrderDefault);
    
//     CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
//     CGContextRelease(contextRef);
    
//     return cvMat;
// }


// -(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
// {
//     NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
//     CGColorSpaceRef colorSpace;
    
//     if (cvMat.elemSize() == 1) {
//         colorSpace = CGColorSpaceCreateDeviceGray();
//     } else {
//         colorSpace = CGColorSpaceCreateDeviceRGB();
//     }
    
//     CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
//     CGImageRef imageRef = CGImageCreate(cvMat.cols,
//                                         cvMat.rows,
//                                         8,
//                                         8 * cvMat.elemSize(),
//                                         cvMat.step[0],
//                                         colorSpace,
//                                         kCGImageAlphaNone|kCGBitmapByteOrderDefault,
//                                         provider,
//                                         NULL,
//                                         false,
//                                         kCGRenderingIntentDefault
//                                         );
    
    
//     UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
//     CGImageRelease(imageRef);
//     CGDataProviderRelease(provider);
//     CGColorSpaceRelease(colorSpace);
    
//     return finalImage;
// }


@end
