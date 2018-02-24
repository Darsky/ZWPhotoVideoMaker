//
//  ZWPhotosMakerVideoModel.h
//  ZWMusicPlayer
//
//  Created by Darsky on 2018/2/3.
//  Copyright © 2018年 Darsky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface ZWPhotosMakerVideoModel : NSObject

@property (strong, nonatomic) NSMutableArray *videoImageArray;
@property (strong, nonatomic) AVAsset *videoAsset;
@property (nonatomic) NSInteger duration;

@end
