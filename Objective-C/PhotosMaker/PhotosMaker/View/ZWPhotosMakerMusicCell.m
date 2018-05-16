//
//  ZWPhotosMakerMusicCell.m
//  PhotosMaker
//
//  Created by Darsky on 2018/5/16.
//  Copyright © 2018年 Darsky. All rights reserved.
//

#import "ZWPhotosMakerMusicCell.h"

@implementation ZWPhotosMakerMusicCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    _selectedView.layer.borderWidth = 4.0;
    _selectedView.layer.borderColor = [UIColor blueColor].CGColor;
}

@end
