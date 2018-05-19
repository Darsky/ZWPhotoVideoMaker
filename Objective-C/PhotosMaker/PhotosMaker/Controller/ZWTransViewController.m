//
//  ZWTransViewController.m
//  PhotosMaker
//
//  Created by Darsky on 2018/5/19.
//  Copyright © 2018年 Darsky. All rights reserved.
//

#import "ZWTransViewController.h"

@interface ZWTransViewController ()
{
    
    __weak IBOutlet UIView *_demoView;
    
    float scale;
}

@end

@implementation ZWTransViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    scale = 22.5/96.0;
}

- (IBAction)didRotate:(id)sender
{
    _demoView.transform = CGAffineTransformRotate(_demoView.transform, M_PI_2);
}

- (IBAction)didTransButtonTouch:(id)sender
{
    _demoView.transform = CGAffineTransformTranslate(_demoView.transform, 0, -96*scale/2.0);
}
- (IBAction)didScaleButtonTouch:(id)sender {
    _demoView.transform = CGAffineTransformScale(_demoView.transform, scale, scale);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
