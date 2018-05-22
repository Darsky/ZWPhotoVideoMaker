//
//  ZWPhotosMakerHelper.h
//  ZWMusicPlayer
//
//  Created by Darsky on 2018/1/27.
//  Copyright © 2018年 Darsky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MusicFileModel.h"

typedef void (^PhotosMakeFinishBlock) (NSURL *fileUrl);

typedef void (^ErrorMsgBlock)    (NSString *errorMsg);

typedef void (^PhotosMakeProgressBlock)   (float progress);


@interface ZWPhotosMakerHelper : NSObject

@property (copy, nonatomic) PhotosMakeFinishBlock finishBlock;
@property (copy, nonatomic) PhotosMakeProgressBlock progressBlock;
@property (copy, nonatomic) ErrorMsgBlock errorMsgBlock;



- (void)startMakePhotoVideosWithAnimationGroup:(CAAnimationGroup*)group
                                     withNodes:(NSArray*)nodeArray
                                   withBgImage:(UIImage*)bgImage
                                      andMusic:(MusicFileModel*)musicModel
                                       forSize:(CGSize)videoSize
                               withFinishBlock:(PhotosMakeFinishBlock)photosMakeFinishBlock
                              andProgressBlock:(PhotosMakeProgressBlock)progressBlock
                              adnErrorMsgBlock:(ErrorMsgBlock)errorMsgBlock;

- (void)combinePicturesAndVideoByEmptyFileWithAnimationGroup:(CAAnimationGroup*)group
                                               withVideoNode:(NSArray*)nodeArray
                                                 withBgImage:(UIImage*)bgImage
                                                    andMusic:(MusicFileModel*)musicModel
                                                     forSize:(CGSize)videoSize
                                             withFinishBlock:(PhotosMakeFinishBlock)photosMakeFinishBlock
                                            andProgressBlock:(PhotosMakeProgressBlock)progressBlock
                                            adnErrorMsgBlock:(ErrorMsgBlock)errorMsgBlock;

- (void)initializeMusicFolderWithSuccessBlock:(void(^)(NSArray* array))successBlock
                                andErrorBlock:(void(^)(NSError *error))errorBlock;
@end
