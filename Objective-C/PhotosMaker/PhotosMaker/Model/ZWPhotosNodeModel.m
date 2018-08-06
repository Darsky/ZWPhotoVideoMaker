//
//  ZWPhotosNodeModel.m
//  PhotosMaker
//
//  Created by Darsky on 2018/5/17.
//  Copyright © 2018年 Darsky. All rights reserved.
//

#import "ZWPhotosNodeModel.h"

@implementation ZWPhotosNodeModel

- (void)setObject:(id)object
{
    _object = object;
    if ([object isKindOfClass:[UIImage class]])
    {
        _thumImage = [self sacleImage:_object];
    }
}

- (UIImage*)sacleImage:(UIImage*)tmpImage
{
    UIImage *uploadImage = nil;
    
    NSData * imageData = UIImageJPEGRepresentation(tmpImage, 0.5);
    NSUInteger sizeOriginKB = [imageData length]/1000;
    if (sizeOriginKB > 300)
    {
        float a = 300.00;
        float b = (float)sizeOriginKB;
        float q = sqrtf(a / b);
        
        CGSize sizeImage = uploadImage.size;
        CGFloat widthSmall = sizeImage.width * q;
        CGFloat heighSmall = sizeImage.height * q;
        CGSize sizeImageSmall = CGSizeMake(widthSmall, heighSmall);
        
        UIGraphicsBeginImageContext(sizeImageSmall);
        CGRect smallImageRect = CGRectMake(0, 0, sizeImageSmall.width, sizeImageSmall.height);
        [uploadImage drawInRect:smallImageRect];
        UIImage *smallImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        imageData = UIImagePNGRepresentation(smallImage);
    }
    
    uploadImage = [UIImage imageWithData:imageData];
    return uploadImage;
    
}

@end
