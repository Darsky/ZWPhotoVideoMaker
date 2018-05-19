//
//  ZWPhotosNodeModel.h
//  PhotosMaker
//
//  Created by Darsky on 2018/5/17.
//  Copyright © 2018年 Darsky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef enum
{
    ZWPhotosNodeTypePicture,
    ZWPhotosNodeTypeVideo,
}ZWPhotosNodeType;

typedef enum
{
    ZWPhotosNodeAnimationTypeNone,
    ZWPhotosNodeAnimationTypeFade,
}ZWPhotosNodeAnimationType;

@interface ZWPhotosNodeModel : NSObject

@property (strong, nonatomic) id object;

@property (nonatomic) ZWPhotosNodeType type;

@property (nonatomic) ZWPhotosNodeAnimationType animationType;

@property (nonatomic) double startTime;

@property (nonatomic) double endTime;

@property (nonatomic) double duration;

@property (nonatomic) float  mediaWidth;

@property (nonatomic) float  mediaHeight;

@property (nonatomic) BOOL   isPortraitVideo;

@property (strong, nonatomic) UIImage* thumImage;

@property (strong, nonatomic) AVPlayer *player;

@property (strong, nonatomic) AVPlayerLayer *playerLayer;

@property (nonatomic) BOOL isPlaying;

@end
