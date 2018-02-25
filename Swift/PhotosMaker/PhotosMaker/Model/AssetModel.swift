//
//  AssetModel.swift
//  PhotosMaker
//
//  Created by Darsky on 2018/2/24.
//  Copyright © 2018年 Darsky. All rights reserved.
//

import UIKit
import Photos

class AssetModel: NSObject
{
    var image:UIImage?
    
    var _asset:PHAsset?
    
    var isSeleted:Bool = false
    
    var asset:PHAsset?{
        set
        {
            _asset = asset
            if _asset != nil && _asset?.mediaType == PHAssetMediaType.video
            {
                durationDesc = NSString(format: "%02ld:%02ld", _asset!.duration/60,_asset!.duration.truncatingRemainder(dividingBy: 60))
            }
        }
        get
        {
            return _asset
        }
    }
    var durationDesc:NSString = "00:00"

    class func assetModelWithPHAssets (asset:PHAsset) -> AssetModel
    {
        let model:AssetModel = AssetModel()
        model.asset = asset
        
        return model
    }
}
