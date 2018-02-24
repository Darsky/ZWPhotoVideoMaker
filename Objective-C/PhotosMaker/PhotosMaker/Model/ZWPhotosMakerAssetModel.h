//
//  ZWPhotosMakerAssetModel.h
//  ZWMusicPlayer
//
//  Created by Darsky on 2018/1/25.
//  Copyright © 2018年 Darsky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

@interface ZWPhotosMakerAssetModel : NSObject

@property (strong, nonatomic) UIImage *image;

@property (strong, nonatomic) CLLocation *location;

@property (strong, nonatomic) NSDate *createDate;

@property (strong, nonatomic) PHAsset *asset;

@property (copy, nonatomic) NSString *durationDesc;

@property (nonatomic) BOOL isSelected;

+ (ZWPhotosMakerAssetModel*)assetModelWithPHAssets:(PHAsset*)asset;

@end
