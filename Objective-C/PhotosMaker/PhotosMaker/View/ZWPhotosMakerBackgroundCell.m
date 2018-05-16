//
//  ZWPhotosMakerBackgroundCell.m
//  PhotosMaker
//
//  Created by Darsky on 2018/5/15.
//  Copyright © 2018年 Darsky. All rights reserved.
//

#import "ZWPhotosMakerBackgroundCell.h"

@implementation ZWPhotosMakerBackgroundCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    _selectedView.layer.borderWidth = 4.0;
    _selectedView.layer.borderColor = [UIColor blueColor].CGColor;
}

@end
