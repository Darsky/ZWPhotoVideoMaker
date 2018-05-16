//
//  MusicFileModel.h
//  VideoRecorder
//
//  Created by Darsky on 2018/5/15.
//  Copyright © 2018年 Darsky. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MusicFileModel : NSObject

@property (copy, nonatomic) NSString *fileName;

@property (copy, nonatomic) NSString *musicName;

@property (strong, nonatomic) UIImage *coverImage;

@property (copy, nonatomic) NSString *artist;

@property (nonatomic) NSInteger duration;

@property (copy, nonatomic) NSString *durationDes;

@property (nonatomic) BOOL isPlaying;


@end
