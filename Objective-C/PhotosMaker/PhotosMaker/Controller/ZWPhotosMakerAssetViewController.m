//
//  ZWPhotosMakerAssetViewController.m
//  ZWMusicPlayer
//
//  Created by Darsky on 2018/1/25.
//  Copyright © 2018年 Darsky. All rights reserved.
//

#import "ZWPhotosMakerAssetViewController.h"
#import "ZWPhotosMakerAssetCell.h"
#import <Photos/Photos.h>
#import "ZWPhotosMakerAssetModel.h"
#import "ZWPhotosMakerHelper.h"
#import "ZWPhotosMakerEditerViewController.h"
#import "ZWPhotosMakerVideoModel.h"

@interface ZWPhotosMakerAssetViewController ()<UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,UIScrollViewDelegate>
{    
    NSMutableArray<ZWPhotosMakerAssetModel*> *_dataArray;
    
    CGSize _itemSize;
        
    __weak IBOutlet UIButton *_confirmButton;
    
    NSInteger _selectedItemCount;
    
    NSArray  *_musicArray;
    
    __weak IBOutlet UISegmentedControl *_musicSegment;
    
}

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;



@end

@implementation ZWPhotosMakerAssetViewController

static NSString *ZWPhotosMakerAssetCellIdentifier          = @"ZWPhotosMakerAssetCell";

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (self.maxCount == 0)
    {
        self.maxCount = 20;
    }
    _musicArray = @[@"Micmacs A La Gare.mp3",@"Valse di Fantastica.mp3",@"带你去旅行.mp3",];
    //设置是否半透明度
    self.navigationController.navigationBar.translucent = NO;
    //设置背景颜色
    //    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];

    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
    [self.navigationController.navigationBar setBackgroundImage:[self createImageWithColor:[UIColor blackColor]]
                                                  forBarMetrics:UIBarMetricsDefault];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [UIColor clearColor]; //加上背景颜色，方便观察Button的大小
    //设置图片
    [button setTitle:@"返回" forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:15];
    [button setTitleColor:[UIColor whiteColor]
                 forState:UIControlStateNormal];
    [button addTarget:self
               action:@selector(backButtonPressed)
     forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    self.navigationItem.leftBarButtonItem = barButtonItem;
    
    _confirmButton.layer.masksToBounds = YES;
    _confirmButton.layer.cornerRadius = 5;
    
    _itemSize = CGSizeMake((SCREEN_WIDTH-10)/4.0, (SCREEN_WIDTH-10)/4.0);
    // Do any additional setup after loading the view from its nib.
    
    [_collectionView registerNib:[UINib nibWithNibName:ZWPhotosMakerAssetCellIdentifier
                                                       bundle:[NSBundle mainBundle]]
             forCellWithReuseIdentifier:ZWPhotosMakerAssetCellIdentifier];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (_dataArray.count == 0)
    {
        [MBProgressHUD showHUDAddedTo:self.view
                             animated:YES];
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status)
         {
             if (status == PHAuthorizationStatusAuthorized)
             {
                 [self loadOriginPhotosFromUserLibary];
             }
             else
             {
                 [MBProgressHUD hideHUDForView:self.view animated:YES];
                 if (status == PHAuthorizationStatusNotDetermined)
                 {
                     NSLog(@"User has not yet made a choice with regards to this application");
                 }
                 else if (status == PHAuthorizationStatusRestricted)
                 {
                     [MBProgressHUD hideHUDForView:self.view animated:YES];
                     NSLog(@"This application is not authorized to access photo data.");
                 }
                 else if (status == PHAuthorizationStatusDenied)
                 {
                     NSLog(@"User has explicitly denied this application access to photos data.");
                 }
             }
         }];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
    
}

#pragma mark - UICollectionViewDataSource Method


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _dataArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ZWPhotosMakerAssetCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:ZWPhotosMakerAssetCellIdentifier forIndexPath:indexPath];
    
    if (_dataArray[indexPath.row].asset.mediaType == PHAssetMediaTypeVideo)
    {
        cell.videoDurationLabel.hidden = NO;
        cell.videoDurationLabel.text = _dataArray[indexPath.row].durationDesc?:@"00:00";
    }
    else
    {
        cell.videoDurationLabel.hidden = YES;
    }
    [cell.photoImageView setImage:_dataArray[indexPath.row].image];
    [cell.selectButton setSelected:_dataArray[indexPath.row].isSelected];
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout Method

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return _itemSize;
}


- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(2, 2, 2, 0);
}

#pragma mark - UICollectionViewDelegate Method

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(nonnull UICollectionViewCell *)cell forItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (_dataArray[indexPath.row].isSelected)
    {
        _dataArray[indexPath.row].isSelected = NO;
        _selectedItemCount--;
        [_collectionView reloadItemsAtIndexPaths:@[indexPath]];
    }
    else if (_selectedItemCount < self.maxCount)
    {
        ZWPhotosMakerAssetModel *assetModel = _dataArray[indexPath.row];
        assetModel.isSelected = YES;
        _selectedItemCount++;
        [_collectionView reloadItemsAtIndexPaths:@[indexPath]];
    }
}

#pragma mark - 数据处理

- (void)loadOriginPhotosFromUserLibary
{
    PHFetchOptions*options = [[PHFetchOptions alloc]init];
    
    options.sortDescriptors=@[[NSSortDescriptor sortDescriptorWithKey:@"creationDate"
                                                            ascending:NO]];

    PHFetchResult *fetchResult = self.onlyPicture?[PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage
                                                                            options:options]:[PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage
                                                                                                                   options:options];
    CGSize targetSize = CGSizeMake(_itemSize.width*[UIScreen mainScreen].scale, _itemSize.height*[UIScreen mainScreen].scale);
    PHImageRequestOptions *imageRequestOptions = [[PHImageRequestOptions alloc] init];
    imageRequestOptions.resizeMode = PHImageRequestOptionsResizeModeFast;
    imageRequestOptions.synchronous = NO;
    NSMutableArray *resultArray = [NSMutableArray array];
    for (int x = 0; x<fetchResult.count; x++)
    {
        PHAsset *targetAsset = fetchResult[x];
        ZWPhotosMakerAssetModel *model = [ZWPhotosMakerAssetModel assetModelWithPHAssets:targetAsset];
        [resultArray insertObject:model
                          atIndex:0];


        [[PHImageManager defaultManager] requestImageForAsset:model.asset
                                                   targetSize:targetSize
                                                  contentMode:PHImageContentModeDefault
                                                      options:imageRequestOptions
                                                resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info)
         {
             model.image = result;
         }];

    }
    _dataArray = resultArray;
    dispatch_sync(dispatch_get_main_queue(),
                  ^{
                      [MBProgressHUD hideHUDForView:self.view
                                           animated:YES];
                      [_collectionView reloadData];
                      [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:_dataArray.count - 1 inSection:0]
                                              atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
                  });
}
- (IBAction)didConfirmButtonTouch:(id)sender
{
    if (_selectedItemCount > 0)
    {
        NSMutableArray *seletcedAssetArray = [NSMutableArray array];
        for (int x = 0; x<_dataArray.count; x++)
        {
            if (_dataArray[x].isSelected)
            {
                [seletcedAssetArray addObject:_dataArray[x]];
            }
        }
        self.view.userInteractionEnabled = NO;
        [MBProgressHUD showHUDAddedTo:self.view
                             animated:YES];
        [self requestHeighImageByAsset:seletcedAssetArray
                       withFinsihBlock:^(NSMutableArray *resultArray)
         {
             dispatch_async(dispatch_get_main_queue(), ^{
                 [MBProgressHUD hideHUDForView:self.view
                                      animated:YES];
                 self.view.userInteractionEnabled = YES;
                 ZWPhotosMakerEditerViewController *viewController = nil;
                 viewController = [[ZWPhotosMakerEditerViewController alloc] initWithNibName:@"ZWPhotosMakerEditerViewController"
                                                                                      bundle:nil];
                 viewController.mediasArray = resultArray;
                 [self.navigationController pushViewController:viewController
                                                      animated:YES];
             });
         }
                     exceptionResponse:^
         {
             dispatch_async(dispatch_get_main_queue(), ^{
                 self.view.userInteractionEnabled = YES;
                 [MBProgressHUD hideHUDForView:self.view
                                      animated:YES];
             });
         }];
    }
}



- (void)requestHeighImageByAsset:(NSMutableArray*)array
             withFinsihBlock:(void(^)(NSMutableArray *resultArray))finishBlock
           exceptionResponse:(void(^)(void))exceptionResponse
{
    CGSize targetSize = CGSizeMake(600,
                            600);
    __block NSInteger count = 0;
    PHImageRequestOptions *imageRequestOptions = [[PHImageRequestOptions alloc] init];
    imageRequestOptions.resizeMode = PHImageRequestOptionsResizeModeExact;
    imageRequestOptions.synchronous = YES;
    imageRequestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    NSMutableArray *resultArrary = [NSMutableArray array];
    for (ZWPhotosMakerAssetModel *model in array)
    {
        if (model.asset.mediaType == PHAssetMediaTypeImage)
        {
            [[PHImageManager defaultManager] requestImageForAsset:model.asset
                                                       targetSize:targetSize
                                                      contentMode:PHImageContentModeAspectFit
                                                          options:imageRequestOptions
                                                    resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info)
             {
                 if (result != nil)
                 {
                     if (self.onlyPicture)
                     {
                         [resultArrary addObject:[self clipImage:result
                                                          toRect:targetSize]];
                     }
                     else
                     {
                         [resultArrary addObject:result];
                     }
                     count++;
                     if (count == array.count)
                     {
                         finishBlock(resultArrary);
                     }
                 }
                 else
                 {
                     exceptionResponse();
                 }
             }];
        }
        else if (model.asset.mediaType == PHAssetMediaTypeVideo)
        {
            PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
            options.version = PHImageRequestOptionsVersionCurrent;
            options.deliveryMode = PHVideoRequestOptionsDeliveryModeMediumQualityFormat;
            
            PHImageManager *manager = [PHImageManager defaultManager];
            [manager requestAVAssetForVideo:model.asset
                                    options:options
                              resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info)
             {
                 int fps = 20;
                 AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
                 imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
                 imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
                 imageGenerator.apertureMode = AVAssetImageGeneratorApertureModeProductionAperture;
                 imageGenerator.appliesPreferredTrackTransform = YES;
                 imageGenerator.maximumSize =  CGSizeMake(targetSize.width/2.0, targetSize.height/2.0);
                 CMTime cmtime = asset.duration; //视频时间信息结构体
                 Float64 durationSeconds = CMTimeGetSeconds(cmtime)>3?3:CMTimeGetSeconds(cmtime); //视频总秒数
                 NSMutableArray *times = [NSMutableArray array];
                 Float64 totalFrames = durationSeconds * fps; //获得视频总帧数
                 CMTime timeFrame;
                 for (int i = 1; i <= totalFrames; i++) {
                     timeFrame = CMTimeMake(i, fps); //第i帧 帧率
                     NSValue *timeValue = [NSValue valueWithCMTime:timeFrame];
                     [times addObject:timeValue];
                 }
                 NSMutableArray *videoThumbArray = [NSMutableArray array];
                 
                 [imageGenerator generateCGImagesAsynchronouslyForTimes:times
                                                      completionHandler:^(CMTime requestedTime,
                                                                          CGImageRef  _Nullable image,
                                                                          CMTime actualTime,
                                                                          AVAssetImageGeneratorResult result,
                                                                          NSError * _Nullable error)
                  {
                      if (result == AVAssetImageGeneratorSucceeded)
                      {
                          UIImage *tempImage = [UIImage imageWithCGImage:image];
                          [videoThumbArray addObject:tempImage];
                          NSLog(@"generateCGImages progress is %.2f",(float)videoThumbArray.count/(float)totalFrames);
                          if (requestedTime.value == times.count)
                          {
                              ZWPhotosMakerVideoModel *viewModel = [[ZWPhotosMakerVideoModel alloc] init];
                              viewModel.videoImageArray = videoThumbArray;
                              viewModel.duration = durationSeconds;
                              viewModel.videoAsset = asset;
                              [resultArrary addObject:viewModel];
                              count++;
                              if (count == array.count)
                              {
                                  finishBlock(resultArrary);
                              }
                          }
                      }
                      else
                      {
                          NSLog(@"获取视频截图出错");
                          exceptionResponse();
                      }
                 }];
            }];
        }
        else
        {
            exceptionResponse();
            break;
        }
    }
}



- (void)backButtonPressed{
    if ([[[self navigationController] viewControllers] count] > 1)
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (UIImage*)createImageWithColor:(UIColor*)color
{
    CGRect rect=CGRectMake(0.0f, 0.0f, 1, 1);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return theImage;
}
#pragma mark -
#pragma mark 等比切出一张图片

-(UIImage *)clipImage:(UIImage *)image toRect:(CGSize)size{
    
    //被切图片宽比例比高比例小 或者相等，以图片宽进行放大
    if (image.size.width*size.height <= image.size.height*size.width) {
        
        //以被剪裁图片的宽度为基准，得到剪切范围的大小
        CGFloat width  = image.size.width;
        CGFloat height = image.size.width * size.height / size.width;
        
        // 调用剪切方法
        // 这里是以中心位置剪切，也可以通过改变rect的x、y值调整剪切位置
        return [self imageFromImage:image inRect:CGRectMake(0, (image.size.height -height)/2, width, height)];
        
    }else{ //被切图片宽比例比高比例大，以图片高进行剪裁
        
        // 以被剪切图片的高度为基准，得到剪切范围的大小
        CGFloat width  = image.size.height * size.width / size.height;
        CGFloat height = image.size.height;
        
        // 调用剪切方法
        // 这里是以中心位置剪切，也可以通过改变rect的x、y值调整剪切位置
        return [self imageFromImage:image inRect:CGRectMake((image.size.width -width)/2, 0, width, height)];
    }
    return nil;
}

-(UIImage *)imageFromImage:(UIImage *)image
                    inRect:(CGRect)rect{
    
    //将UIImage转换成CGImageRef
    CGImageRef sourceImageRef = [image CGImage];
    
    //按照给定的矩形区域进行剪裁
    CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);
    
    //将CGImageRef转换成UIImage
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    CGImageRelease(newImageRef);
    //返回剪裁后的图片
    return newImage;
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    NSLog(@"OK");
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
