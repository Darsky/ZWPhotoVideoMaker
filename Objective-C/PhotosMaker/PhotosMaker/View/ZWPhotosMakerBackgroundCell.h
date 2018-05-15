//
//  ZWPhotosMakerBackgroundCell.h
//  PhotosMaker
//
//  Created by Darsky on 2018/5/15.
//  Copyright © 2018年 Darsky. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZWPhotosMakerBackgroundCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *bgImageView;
@property (weak, nonatomic) IBOutlet UILabel *bgNameLabel;
@property (weak, nonatomic) IBOutlet UIView *selectedView;

@end
