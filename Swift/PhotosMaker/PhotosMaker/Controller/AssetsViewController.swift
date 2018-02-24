//
//  AssetsViewController.swift
//  PhotosMaker
//
//  Created by Darsky on 2018/2/24.
//  Copyright © 2018年 Darsky. All rights reserved.
//

import UIKit

class AssetsViewController: UIViewController,UICollectionViewDataSource,UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout
{
    //MARK: - Controller
    var onlyPicture:Bool? = false
    var maxCount:NSInteger?
    var itemSize:CGSize?
    //MARK: - CollectionView
    @IBOutlet weak var collectionView: UICollectionView!
    var dataArray:[AssetModel]?
    
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
        
        
    }
    
    // MARK: - UICollectionViewDataSource Method
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        
    }
    
    // MARK: - Other Method
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


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


}
