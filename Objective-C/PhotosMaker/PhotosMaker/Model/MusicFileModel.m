//
//  MusicFileModel.m
//  VideoRecorder
//
//  Created by Darsky on 2018/5/15.
//  Copyright © 2018年 Darsky. All rights reserved.
//

#import "MusicFileModel.h"

@implementation MusicFileModel

- (NSString*)durationDes
{
    if (_durationDes == nil)
    {
        if (_duration > 0)
        {
            _durationDes = [NSString stringWithFormat:@"%02ld:%02ld",_duration/60,_duration%60];
        }
        else
        {
            _durationDes = @"00:00";
        }
    }
    return _durationDes;
}

@end
