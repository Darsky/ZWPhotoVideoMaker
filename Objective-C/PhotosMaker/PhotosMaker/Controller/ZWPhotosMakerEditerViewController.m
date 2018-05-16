//
//  ZWPhotosMakerEditerViewController.m
//  ZWMusicPlayer
//
//  Created by Darsky on 2018/2/2.
//  Copyright © 2018年 Darsky. All rights reserved.
//

#import "ZWPhotosMakerEditerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "ZWVideoThumbnailCell.h"
#import "ZWPhotosMakerVideoModel.h"
#import "ZWPhotosMakerHelper.h"
#import <Photos/Photos.h>
#import "ZWPhotosMakerBackgroundCell.h"
#import "ZWPhotosMakerMusicCell.h"
#define frameSize   3.0


@interface ZWPhotosMakerEditerViewController ()<CAAnimationDelegate,UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,AVAudioPlayerDelegate>
{
    __weak IBOutlet UIView *_displayView;
    
    IBOutlet UIImageView   *_displayBgImageView;
    
    UIImageView            *_displayImageView;
    
    NSTimeInterval          _totalDuration;
    
    __weak IBOutlet UIButton *_playButton;
    
    __weak IBOutlet UICollectionView *_collectionView;
    
    CGSize   _thumbnailSize;
    
    __weak IBOutlet UISegmentedControl *_segmentControl;
    
    NSInteger        _selectedBgIndex;
    
    NSArray         *_bgArray;
    
    CGSize           _bgItemSize;
    
    NSInteger        _selectedMusicIndex;
    
    NSArray         *_musicArray;
    
    CGSize           _musicItemSize;

    
    __weak IBOutlet UICollectionView *_additionalCollectionView;
    
    
    BOOL _isPlaying;
}
@property (strong, nonatomic) CAAnimationGroup *group;

@property (strong, nonatomic) CADisplayLink *playTimer;

@property (strong, nonatomic) AVAudioPlayer *audioPlayer;


@end

@implementation ZWPhotosMakerEditerViewController

static NSString *ZWVideoThumbnailCellIdentifier          = @"ZWVideoThumbnailCell";

static NSString *ZWVideoThumbnailHeaderIdentifier        = @"ZWVideoThumbnailHeader";

static NSString *ZWVideoThumbnailFooterIdentifier        = @"ZWVideoThumbnailFooter";

static NSString *ZWPhotosMakerBackgroundCellIdentifier   = @"ZWPhotosMakerBackgroundCell";

static NSString *ZWPhotosMakerMusicCellIdentifier        = @"ZWPhotosMakerMusicCell";



- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [UIColor clearColor]; //加上背景颜色，方便观察Button的大小
    //设置图片
    [button setTitle:@"确定" forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:15];
    [button setTitleColor:[UIColor whiteColor]
                 forState:UIControlStateNormal];
    [button addTarget:self
               action:@selector(didConfirmButtonTouch)
     forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    self.navigationItem.rightBarButtonItem = barButtonItem;
    
    _bgArray = @[[UIImage imageNamed:@"bg_videoMaker01"],[UIImage imageNamed:@"bg_videoMaker02"],[UIImage imageNamed:@"bg_videoMaker03"]];
    [_displayBgImageView setImage:_bgArray[_selectedBgIndex]];
    _thumbnailSize = CGSizeZero;
    [_collectionView registerNib:[UINib nibWithNibName:ZWVideoThumbnailCellIdentifier
                                                         bundle:[NSBundle mainBundle]]
               forCellWithReuseIdentifier:ZWVideoThumbnailCellIdentifier];
    [_collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
               withReuseIdentifier:ZWVideoThumbnailHeaderIdentifier];
    [_collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter
               withReuseIdentifier:ZWVideoThumbnailFooterIdentifier];
    
    [_additionalCollectionView registerNib:[UINib nibWithNibName:ZWPhotosMakerBackgroundCellIdentifier
                                                          bundle:[NSBundle mainBundle]]
                forCellWithReuseIdentifier:ZWPhotosMakerBackgroundCellIdentifier];
    [_additionalCollectionView registerNib:[UINib nibWithNibName:ZWPhotosMakerMusicCellIdentifier
                                                          bundle:[NSBundle mainBundle]]
                forCellWithReuseIdentifier:ZWPhotosMakerMusicCellIdentifier];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.mediasArray.count > 0 && self.group == nil)
    {
        _thumbnailSize = CGSizeMake(([UIScreen mainScreen].bounds.size.width - 30)/5.0, 40);
        _bgItemSize = CGSizeMake(100, 100);
        _musicItemSize = CGSizeMake(100, 100);

        _displayImageView = [[UIImageView alloc] initWithFrame:_displayView.bounds];
        [_displayView addSubview:_displayImageView];
        self.view.userInteractionEnabled = NO;
        [MBProgressHUD showHUDAddedTo:self.view
                             animated:YES];
        ZWPhotosMakerHelper *helper = [[ZWPhotosMakerHelper alloc] init];
        [helper initializeMusicFolderWithSuccessBlock:^(NSArray *array)
        {
            [MBProgressHUD hideHUDForView:self.view
                                 animated:YES];
            self.view.userInteractionEnabled = YES;
            _musicArray = array;
            MusicFileModel *model = _musicArray[_selectedMusicIndex];
            NSString *path =[ [NSBundle mainBundle]  pathForResource:model.fileName
                                                              ofType:@"mp3"];
            self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path]
                                                                      error:nil];
            [self.audioPlayer prepareToPlay];

            self.group = [self createAnimationGroupWithSize:_displayImageView.bounds.size];
            _totalDuration = self.group.duration;
            [_displayImageView.layer addAnimation:self.group
                                           forKey:@"group"];
            _displayImageView.layer.speed = 0;
            [_collectionView reloadData];
        }
                                        andErrorBlock:^(NSError *error)
        {
            [MBProgressHUD hideHUDForView:self.view
                                 animated:YES];
            self.view.userInteractionEnabled = YES;
        }];

    }

}

- (CAAnimationGroup*)createAnimationGroupWithSize:(CGSize)targetSize
{
    NSTimeInterval totalDuration = AVCoreAnimationBeginTimeAtZero;
    CAAnimationGroup *group = [CAAnimationGroup animation];
    NSMutableArray *animations = [NSMutableArray array];

    for (int index = 0; index<self.mediasArray.count; index++)
    {
        if ([self.mediasArray[index] isKindOfClass:[UIImage class]])
        {
            CAKeyframeAnimation * contentsAnimation;
            contentsAnimation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
            contentsAnimation.duration = 0.5f;
            contentsAnimation.removedOnCompletion = NO;
            contentsAnimation.fillMode = kCAFillModeForwards;
            UIImage *tempImage = self.mediasArray[index];
            contentsAnimation.values = @[(__bridge UIImage*)tempImage.CGImage];
            contentsAnimation.beginTime = totalDuration;
            [animations addObject:contentsAnimation];
            if (index != 0)
            {
                CAKeyframeAnimation * showAnimation;
                showAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
                showAnimation.duration = 0.5;
                //animation.delegate = self;
                showAnimation.removedOnCompletion = NO;
                showAnimation.fillMode = kCAFillModeForwards;
                showAnimation.values = @[[NSNumber numberWithFloat:0.0],
                                         [NSNumber numberWithFloat:1.0]];
                showAnimation.beginTime = totalDuration;
                [animations addObject:showAnimation];
            }
            totalDuration+=contentsAnimation.duration;
            
            CGFloat imageWidth  = 0;
            CGFloat imageHeight = 0;
            if (tempImage.size.width > tempImage.size.height)
            {
                imageWidth  = targetSize.width;
                imageHeight = imageWidth/tempImage.size.width*tempImage.size.height;
            }
            else
            {
                imageHeight = targetSize.height;
                imageWidth  = imageHeight/tempImage.size.height*tempImage.size.width;
            }
            CGFloat xPoint = targetSize.width/2.0 - imageWidth/2.0;
            CGFloat yPoint = targetSize.height/2.0 - imageHeight/2.0;
            
            CAKeyframeAnimation * boundsAnimation;
            boundsAnimation = [CAKeyframeAnimation animationWithKeyPath:@"bounds"];
            boundsAnimation.duration = 0.5f;
            //animation.delegate = self;
            boundsAnimation.removedOnCompletion = NO;
            boundsAnimation.fillMode = kCAFillModeForwards;
            boundsAnimation.values = @[[NSValue valueWithCGRect:CGRectMake(xPoint,yPoint,imageWidth,imageHeight)]];
            boundsAnimation.beginTime = totalDuration-0.5;
            [animations addObject:boundsAnimation];
            
            CAKeyframeAnimation *scaleZeroAnimation;
            scaleZeroAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
            scaleZeroAnimation.duration = 0.5f;
            scaleZeroAnimation.removedOnCompletion = NO;
            scaleZeroAnimation.autoreverses = YES;
            scaleZeroAnimation.fillMode = kCAFillModeForwards;
            scaleZeroAnimation.values = @[[NSNumber numberWithFloat:1]];
            scaleZeroAnimation.beginTime = totalDuration-0.5;
            [animations addObject:scaleZeroAnimation];
            
            CAKeyframeAnimation *scaleAnimation;
            scaleAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
            scaleAnimation.duration = 1.0f;
            scaleAnimation.removedOnCompletion = NO;
            scaleAnimation.fillMode = kCAFillModeForwards;
            scaleAnimation.values = @[[NSNumber numberWithFloat:1],
                                      [NSNumber numberWithFloat:2.0]];
            scaleAnimation.beginTime = totalDuration;
            [animations addObject:scaleAnimation];
            totalDuration+= scaleAnimation.duration;
            
            CAKeyframeAnimation * dissAnimation;
            dissAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
            dissAnimation.duration = 0.5;
            //animation.delegate = self;
            dissAnimation.removedOnCompletion = NO;
            dissAnimation.fillMode = kCAFillModeForwards;
            dissAnimation.values = (index == (int)self.mediasArray.count - 1)?@[[NSNumber numberWithFloat:1.0],
                                                                                [NSNumber numberWithFloat:0.8],
                                                                                [NSNumber numberWithFloat:0.4],
                                                                                [NSNumber numberWithFloat:0.0]]:@[[NSNumber numberWithFloat:1.0],
                                                                                                                  [NSNumber numberWithFloat:0.5],
                                                                                                                  [NSNumber numberWithFloat:0.3],
                                                                                                                  [NSNumber numberWithFloat:0.2]];
            dissAnimation.beginTime = totalDuration;
            [animations addObject:dissAnimation];
            totalDuration+=dissAnimation.duration;
        }
        else if ([self.mediasArray[index] isKindOfClass:[ZWPhotosMakerVideoModel class]])
        {
            ZWPhotosMakerVideoModel *viewModel = self.mediasArray[index];
            if (index != 0)
            {
                CAKeyframeAnimation * showAnimation;
                showAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
                showAnimation.duration = 0.5;
                //animation.delegate = self;
                showAnimation.removedOnCompletion = NO;
                showAnimation.fillMode = kCAFillModeForwards;
                showAnimation.values = @[[NSNumber numberWithFloat:0.0],
                                         [NSNumber numberWithFloat:1.0]];
                showAnimation.beginTime = totalDuration;
                [animations addObject:showAnimation];
            }
            UIImage *firstImage = nil;
            CAKeyframeAnimation * contentsAnimation;
            contentsAnimation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
            contentsAnimation.duration = viewModel.duration;
            contentsAnimation.removedOnCompletion = NO;
            contentsAnimation.fillMode = kCAFillModeForwards;
            NSMutableArray *videoContentsArray = [NSMutableArray array];
            for (int v = 0; v<viewModel.videoImageArray.count; v++)
            {
                UIImage *tempImage = viewModel.videoImageArray[v];
                if (v == 0)
                {
                    firstImage = tempImage;
                }
                [videoContentsArray addObject:(__bridge UIImage*)tempImage.CGImage];
            }
            contentsAnimation.values = videoContentsArray;
            contentsAnimation.beginTime = totalDuration;
            [animations addObject:contentsAnimation];
            
            CGFloat imageWidth  = 0;
            CGFloat imageHeight = 0;
            if (firstImage.size.width > firstImage.size.height)
            {
                imageWidth  = targetSize.width;
                imageHeight = imageWidth/firstImage.size.width*firstImage.size.height;
            }
            else
            {
                imageHeight = targetSize.height;
                imageWidth  = imageHeight/firstImage.size.height*firstImage.size.width;
            }
            CGFloat xPoint = targetSize.width/2.0 - imageWidth/2.0;
            CGFloat yPoint = targetSize.height/2.0 - imageHeight/2.0;
            
            CAKeyframeAnimation * boundsAnimation;
            boundsAnimation = [CAKeyframeAnimation animationWithKeyPath:@"bounds"];
            boundsAnimation.duration = 0.5f;
            //animation.delegate = self;
            boundsAnimation.removedOnCompletion = NO;
            boundsAnimation.fillMode = kCAFillModeForwards;
            boundsAnimation.values = @[[NSValue valueWithCGRect:CGRectMake(xPoint,yPoint,imageWidth,imageHeight)]];
            boundsAnimation.beginTime = totalDuration;
            [animations addObject:boundsAnimation];
            
            CAKeyframeAnimation *scaleZeroAnimation;
            scaleZeroAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
            scaleZeroAnimation.duration = 0.5f;
            //animation.delegate = self;
            scaleZeroAnimation.removedOnCompletion = NO;
            scaleZeroAnimation.autoreverses = YES;
            scaleZeroAnimation.fillMode = kCAFillModeForwards;
            scaleZeroAnimation.values = @[[NSNumber numberWithFloat:1]];
            scaleZeroAnimation.beginTime = totalDuration;
            [animations addObject:scaleZeroAnimation];

            totalDuration+=contentsAnimation.duration;
            
            CAKeyframeAnimation * dissAnimation;
            dissAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
            dissAnimation.duration = 0.5;
            //animation.delegate = self;
            dissAnimation.removedOnCompletion = NO;
            dissAnimation.fillMode = kCAFillModeForwards;
            dissAnimation.values = (index == (int)self.mediasArray.count - 1)?@[[NSNumber numberWithFloat:1.0],
                                     [NSNumber numberWithFloat:0.8],
                                     [NSNumber numberWithFloat:0.4],
                                                                                [NSNumber numberWithFloat:0.0]]:@[[NSNumber numberWithFloat:1.0],
                                                                                                                  [NSNumber numberWithFloat:0.5],
                                                                                                                  [NSNumber numberWithFloat:0.3],
                                                                                                                  [NSNumber numberWithFloat:0.0]];
            dissAnimation.beginTime = totalDuration;
            [animations addObject:dissAnimation];
            totalDuration+=dissAnimation.duration;
        }
    }
    
    
    group.animations = animations;
    group.duration = totalDuration;
    group.fillMode = kCAFillModeForwards;
    group.delegate = self;
    group.removedOnCompletion = NO;
    
    return group;
}


- (IBAction)didStartButtonTouch:(id)sender
{
    NSTimeInterval totalDuration = 0;
    CAAnimationGroup *group = [CAAnimationGroup animation];
    
    NSMutableArray *animations = [NSMutableArray array];
    CAKeyframeAnimation * shinningAnimation;
    shinningAnimation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
    shinningAnimation.duration = 0.5f;
    //animation.delegate = self;
    shinningAnimation.removedOnCompletion = NO;
    shinningAnimation.fillMode = kCAFillModeForwards;
    NSMutableArray *values =[NSMutableArray array];
    UIImage *tempImage = [UIImage imageNamed:@"img_cover_music"];
    [values addObject:(__bridge UIImage*)tempImage.CGImage];
    shinningAnimation.values = values;
    shinningAnimation.beginTime = totalDuration;
    [animations addObject:shinningAnimation];
    totalDuration+=shinningAnimation.duration;
    
    CAKeyframeAnimation * roationAnimation;
    roationAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation"];
    roationAnimation.duration = 2.0f;
    //animation.delegate = self;
    roationAnimation.removedOnCompletion = NO;
    roationAnimation.fillMode = kCAFillModeForwards;
    roationAnimation.values = @[[NSNumber numberWithFloat:0],
                         [NSNumber numberWithFloat:(1.0 * M_PI)],
                         [NSNumber numberWithFloat:(1.5 * M_PI)],
                         [NSNumber numberWithFloat:(2.0 * M_PI)]];
    roationAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    roationAnimation.beginTime = totalDuration+0.5;
    [animations addObject:roationAnimation];
    totalDuration+= (roationAnimation.autoreverses)?roationAnimation.duration*2:roationAnimation.duration;
    
    CAKeyframeAnimation *transAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
    transAnimation.duration = 2.0f;
    transAnimation.removedOnCompletion = NO;
    transAnimation.fillMode = kCAFillModeForwards;
    transAnimation.values = @[@(0),@(-100),@(-150),@(-100),@(0)];
    transAnimation.beginTime =  totalDuration+0.5;
    [animations addObject:transAnimation];
    totalDuration+= (transAnimation.autoreverses)?transAnimation.duration*2:transAnimation.duration;

    _totalDuration = totalDuration;
    group.animations = animations;
    group.duration = totalDuration;
    group.fillMode = kCAFillModeForwards;
    group.delegate = self;
    group.removedOnCompletion = NO;
    self.group = group;
    [_displayImageView.layer addAnimation:self.group
                                   forKey:@"group"];
    _displayImageView.layer.speed = 0;
}



- (void)animationDidStart:(CAAnimation *)anim
{
}

- (void)animationDidStop:(CAAnimation *)anim
                finished:(BOOL)flag
{
}

- (IBAction)didPlayButtonTouch:(UIButton *)sender
{
    if (sender.selected)
    {
        [self.audioPlayer pause];
        _isPlaying = NO;
        [self.playTimer setPaused:YES];
        _playButton.selected = NO;
    }
    else
    {

        if (self.playTimer == nil)
        {
            self.playTimer = [CADisplayLink displayLinkWithTarget:self
                                                         selector:@selector(updateSilder)];
            [self.playTimer addToRunLoop:[NSRunLoop currentRunLoop]
                                 forMode:NSRunLoopCommonModes];
            
        }
        [self.playTimer setPaused:NO];
        _playButton.selected = YES;
        _isPlaying = YES;
        [self.audioPlayer play];

    }
}

- (void)updateSilder
{
    CFTimeInterval targetTimeOffset = _displayImageView.layer.timeOffset+1.0/60.0;

    _displayImageView.layer.timeOffset = targetTimeOffset;
    float progress = _displayImageView.layer.timeOffset/_totalDuration;
//    NSLog(@"%.2f",progress);
    [self setVideoCollectionAtProgress:progress];

    if (progress >= 1.0 && _playButton.selected)
    {
        [self didPlayButtonTouch:_playButton];
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView == _collectionView)
    {
        // 如果当前想要的是头部视图
        // UICollectionElementKindSectionHeader是一个const修饰的字符串常量,所以可以直接使用==比较
        if (kind == UICollectionElementKindSectionHeader) {
            UICollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:ZWVideoThumbnailHeaderIdentifier
                                                                                             forIndexPath:indexPath];
            headerView.backgroundColor = [UIColor lightGrayColor];
            return headerView;
        }
        else if (kind == UICollectionElementKindSectionFooter) {
            UICollectionReusableView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:ZWVideoThumbnailFooterIdentifier
                                                                                             forIndexPath:indexPath];
            footerView.backgroundColor = [UIColor lightGrayColor];
            return footerView;
        }
        else
        {
            return nil;
        }
    }
    else
    {
        return nil;
    }

}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    if (collectionView == _collectionView)
    {
        return CGSizeMake((SCREEN_WIDTH-30)/2.0, 40);
    }
    else if (collectionView == _additionalCollectionView)
    {
        if (_segmentControl.selectedSegmentIndex == 0)
        {
            return CGSizeZero;
        }
        else
        {
            return CGSizeZero;
        }
    }
    else
    {
        return CGSizeZero;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section
{
    if (collectionView == _collectionView)
    {
        return CGSizeMake((SCREEN_WIDTH-30)/2.0, 40);
    }
    else
    {
        return CGSizeZero;
    }
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView == _collectionView)
    {
        if ([self.mediasArray[indexPath.row] isKindOfClass:[UIImage class]])
        {
            return _thumbnailSize;
        }
        else if ([self.mediasArray[indexPath.row] isKindOfClass:[ZWPhotosMakerVideoModel class]])
        {
            ZWPhotosMakerVideoModel *videoModel = self.mediasArray[indexPath.row];
            return CGSizeMake(_thumbnailSize.width*(videoModel.duration/2.0), _thumbnailSize.height);
        }
        else
        {
            return _thumbnailSize;
        }
    }
    else if (collectionView == _additionalCollectionView)
    {
        if (_segmentControl.selectedSegmentIndex == 0)
        {
            return _bgItemSize;
        }
        else
        {
            return CGSizeZero;
        }
    }
    else
    {
        return CGSizeZero;
    }

}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    if (collectionView == _collectionView)
    {
        return UIEdgeInsetsMake(0, 0, 0, 0);
    }
    else if (collectionView == _additionalCollectionView)
    {
        return UIEdgeInsetsMake(0, 0, 0, 0);
    }
    else
    {
        return UIEdgeInsetsMake(0, 0, 0, 0);
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    
    if (collectionView == _collectionView)
    {
        return self.mediasArray.count;
    }
    else if (collectionView == _additionalCollectionView)
    {
        if (_segmentControl.selectedSegmentIndex == 0)
        {
            return _bgArray.count;
        }
        else
        {
            return _musicArray.count;
        }
    }
    else
    {
        return 0;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView == _collectionView)
    {
        ZWVideoThumbnailCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:ZWVideoThumbnailCellIdentifier
                                                                               forIndexPath:indexPath];
        if ([self.mediasArray[indexPath.row] isKindOfClass:[ZWPhotosMakerVideoModel class]])
        {
            ZWPhotosMakerVideoModel *model = self.mediasArray[indexPath.row];
            [cell.thumbnailImageView setImage:[model.videoImageArray firstObject]];
        }
        else
        {
            [cell.thumbnailImageView setImage:self.mediasArray[indexPath.row]];
        }
        return cell;
    }
    else if (collectionView == _additionalCollectionView)
    {
        if (_segmentControl.selectedSegmentIndex == 0)
        {
            ZWPhotosMakerBackgroundCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:ZWPhotosMakerBackgroundCellIdentifier forIndexPath:indexPath];
            cell.bgNameLabel.text = [NSString stringWithFormat:@"背景%d",(int)indexPath.row];
            [cell.bgImageView setImage:_bgArray[indexPath.row]];
            if (indexPath.row == _selectedBgIndex)
            {
                cell.selectedView.hidden = NO;
            }
            else
            {
                cell.selectedView.hidden = YES;
            }
            return cell;
        }
        else if (_segmentControl.selectedSegmentIndex == 1)
        {
            ZWPhotosMakerMusicCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:ZWPhotosMakerMusicCellIdentifier forIndexPath:indexPath];
            
            MusicFileModel *model = _musicArray[indexPath.row];
            cell.musicNameLabel.text = model.musicName?:@"未知曲目";
            [cell.coverImageView setImage:model.coverImage];
            if (indexPath.row == _selectedMusicIndex)
            {
                cell.selectedView.hidden = NO;
            }
            else
            {
                cell.selectedView.hidden = YES;
            }
            return cell;
        }
        else
        {
            return nil;
        }
    }
    else
    {
        return nil;
    }
}

#pragma mark - UICollectionViewDelegate Method

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView == _additionalCollectionView)
    {
        if (_segmentControl.selectedSegmentIndex == 0)
        {
            _selectedBgIndex = indexPath.row;
            [_displayBgImageView setImage:_bgArray[_selectedBgIndex]];
            [_additionalCollectionView reloadData];
        }
        else if (_segmentControl.selectedSegmentIndex == 1)
        {
            if (_selectedMusicIndex != indexPath.row)
            {
                [self.audioPlayer stop];
                self.audioPlayer = nil;
                _selectedMusicIndex = indexPath.row;
                MusicFileModel *model = _musicArray[_selectedMusicIndex];
                NSString *path =[ [NSBundle mainBundle]  pathForResource:model.fileName
                                                                  ofType:@"mp3"];
                self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path]
                                                                          error:nil];
                self.audioPlayer.delegate = self;
                [self.audioPlayer prepareToPlay];
            }
        }
        else
        {
            
        }
    }
}

#pragma mark - UIScrollViewDelegate Method

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    NSLog(@"scrollViewWillBeginDecelerating");
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    NSLog(@"scrollViewWillBeginDragging");
    if (_isPlaying)
    {
        [self didPlayButtonTouch:_playButton];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (!_isPlaying)
    {
        float padding = (SCREEN_WIDTH-30)/2.0;
        float progress = scrollView.contentOffset.x/(_collectionView.contentSize.width-padding*2);
        NSLog(@"scroll Progress is %.2f",progress);
        _displayImageView.layer.timeOffset = _totalDuration*progress;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{

}

- (void)setVideoCollectionAtProgress:(float)progress
{
    float padding = (SCREEN_WIDTH-30)/2.0;
    [_collectionView setContentOffset:CGPointMake((_collectionView.contentSize.width-padding*2)*progress, 0)];
}

#pragma mark - Other Method

- (IBAction)didSegmentControlChanged:(UISegmentedControl *)sender
{
    [_additionalCollectionView reloadData];
}


- (void)didConfirmButtonTouch
{
    if (_isPlaying)
    {
        [self didPlayButtonTouch:_playButton];
    }
    self.view.userInteractionEnabled = NO;
    [MBProgressHUD showHUDAddedTo:self.view
                         animated:YES];
    ZWPhotosMakerHelper *helper = [[ZWPhotosMakerHelper alloc] init];
    CGSize videoSize = CGSizeMake(1800, 900);
    [helper startMakePhotoVideosWithAnimationGroup:[self createAnimationGroupWithSize:videoSize]
                                           forSize:videoSize
                                   withFinishBlock:^(NSURL *fileUrl)
     {
         [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^
          {
              [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:fileUrl];
          }
                                           completionHandler:^(BOOL success, NSError * _Nullable error)
          {
              dispatch_async(dispatch_get_main_queue(), ^{
                  [MBProgressHUD hideHUDForView:self.view
                                       animated:YES];
                  self.view.userInteractionEnabled = YES;
                  if (success)
                  {
                      NSLog(@"保存成功");
                  }
                  else
                  {
                      NSLog(@"存储相册失败");
                  }
              });
          }];
    }
                                  adnErrorMsgBlock:^(NSString *errorMsg)
     {
         dispatch_async(dispatch_get_main_queue(), ^{
             self.view.userInteractionEnabled = YES;
             [MBProgressHUD hideHUDForView:self.view
                                  animated:YES];
             NSLog(@"%@",errorMsg);
         });
    }];
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
