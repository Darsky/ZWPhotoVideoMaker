//
//  AssetsViewController.swift
//  PhotosMaker
//
//  Created by Darsky on 2018/2/24.
//  Copyright © 2018年 Darsky. All rights reserved.
//

import UIKit
import MBProgressHUD
import Photos


class AssetsViewController: UIViewController,UICollectionViewDataSource,UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout
{
    //MARK: - Controller
    var onlyPicture:Bool = false
    var maxCount:NSInteger?
    var itemSize:CGSize = CGSize.zero
    //MARK: - CollectionView
    @IBOutlet weak var collectionView: UICollectionView!
    var dataArray:[AssetModel]?
    let AssetCellIdentifier = "AssetCollectionViewCell"
    
    //MARK: - Other
    @IBOutlet weak var confirmButton: UIButton!
    
    var selectedCount:NSInteger = 0
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        if maxCount == 0
        {
            maxCount = 20
        }
        // Do any additional setup after loading the view.
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.barStyle = UIBarStyle.black
        self.navigationController?.navigationBar.setBackgroundImage(self.createImageWithColor(color: UIColor.black), for: UIBarPosition.top, barMetrics: UIBarMetrics.default)
        
        let button:UIButton = UIButton(type: UIButtonType.custom)
        button.backgroundColor = UIColor.clear
        button.setTitle("返回", for: UIControlState.normal)
        button.setTitleColor(UIColor.white, for: UIControlState.normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        button.addTarget(self, action: #selector(backButtonTouch), for: UIControlEvents.touchUpInside)
        let backBarItem:UIBarButtonItem = UIBarButtonItem(customView: button)
        self.navigationItem.leftBarButtonItem = backBarItem
        
        confirmButton.layer.masksToBounds = true
        confirmButton.layer.cornerRadius  = 5
        
        collectionView.register(UINib.init(nibName: AssetCellIdentifier, bundle: Bundle.main),
                                forCellWithReuseIdentifier:AssetCellIdentifier)
        
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        if dataArray?.count == 0
        {
            itemSize = CGSize.init(width: (UIScreen.main.bounds.size.width-10)/4.0, height: (UIScreen.main.bounds.size.height-10)/4.0)
            MBProgressHUD.showAdded(to: self.view, animated: true)
            PHPhotoLibrary.requestAuthorization({ (status) in
                if status == PHAuthorizationStatus.authorized
                {
                    self.loadPhotosFromDeviceLibary()
                }
                else
                {
                    
                }
                
            })
        }
    }
    
    // MARK: - UICollectionViewDataSource Method
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return dataArray!.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell:AssetCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: AssetCellIdentifier, for: indexPath) as! AssetCollectionViewCell
        if dataArray![indexPath.row].asset!.mediaType == PHAssetMediaType.video
        {
            cell.durationLabel.isHidden = false
            cell.durationLabel.text = dataArray![indexPath.row].durationDesc as String;
        }
        else
        {
            cell.durationLabel.isHidden = true
        }
        cell.imageView.image = dataArray![indexPath.row].image
        cell.selectButton.isSelected = dataArray![indexPath.row].isSeleted
        return cell
    }
    
    // MARK: - Other Method
    
    func loadPhotosFromDeviceLibary() -> ()
    {
        
        let fetchResult:PHFetchResult<PHAsset> = self.onlyPicture == true ? PHAsset.fetchAssets(with: PHAssetMediaType.image, options: nil):PHAsset.fetchAssets(with: nil)
        let targetSize:CGSize = CGSize.init(width: itemSize.width*UIScreen.main.scale, height: itemSize.height*UIScreen.main.scale)
        
        let imageRequestOptions:PHImageRequestOptions = PHImageRequestOptions.init()
        imageRequestOptions.resizeMode = PHImageRequestOptionsResizeMode.fast
        imageRequestOptions.isSynchronous = true
        var resultArray:[AssetModel] = []
        for x in 0 ..< fetchResult.count
        {
            let tempAsset:PHAsset = fetchResult[x]
            PHImageManager.default().requestImage(for: tempAsset, targetSize: targetSize, contentMode: PHImageContentMode.default, options: imageRequestOptions, resultHandler:
                {
                    (result, info) in
                    let model:AssetModel = AssetModel.assetModelWithPHAssets(asset: tempAsset)
                    model.image = result
                    resultArray.append(model)
                    if resultArray.count == fetchResult.count
                    {
                        self.dataArray = resultArray
                        DispatchQueue.main.sync {
                            MBProgressHUD.hide(for: self.view, animated: true)
                            self.collectionView.reloadData()
                            self.collectionView.scrollToItem(at: IndexPath.init(row: self.dataArray!.count - 1, section: 0), at: UICollectionViewScrollPosition.bottom, animated: false)
                            
                        }
                    }
            })
        }
        
    }
    
    func createImageWithColor(color:UIColor) -> UIImage
    {
        let rect:CGRect = CGRect.init(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        let context:CGContext! = UIGraphicsGetCurrentContext()
        context.setFillColor(color.cgColor)
        context.fill(rect)
        let resultImage:UIImage! = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resultImage
    }
    
    @objc func backButtonTouch() -> ()
    {
        if self.navigationController!.viewControllers.count > 1
        {
            self.navigationController?.popViewController(animated: true)
        }
        else
        {
            self.dismiss(animated: true, completion:
                {
                    
            })
        }
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


}
