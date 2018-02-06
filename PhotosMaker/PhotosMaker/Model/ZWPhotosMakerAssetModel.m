//
//  ZWPhotosMakerAssetModel.m
//  ZWMusicPlayer
//
//  Created by Darsky on 2018/1/25.
//  Copyright © 2018年 Darsky. All rights reserved.
//

#import "ZWPhotosMakerAssetModel.h"

@implementation ZWPhotosMakerAssetModel


+ (ZWPhotosMakerAssetModel*)assetModelWithPHAssets:(PHAsset*)asset
{
    ZWPhotosMakerAssetModel *model = [[ZWPhotosMakerAssetModel alloc] init];
    model.createDate = [asset.creationDate copy];
    model.location   = [asset.location copy];
    model.asset = asset;
    return model;
}

- (void)setAsset:(PHAsset *)asset
{
    _asset = asset;
    if (_asset != nil && _asset.mediaType == PHAssetMediaTypeVideo)
    {
        self.durationDesc = [NSString stringWithFormat:@"%02ld:%02ld",(NSInteger)_asset.duration/60,(NSInteger)_asset.duration%60];
    }
}

@end
