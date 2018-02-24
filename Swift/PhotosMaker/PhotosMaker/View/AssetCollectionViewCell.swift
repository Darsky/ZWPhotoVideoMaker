//
//  AssetCollectionViewCell.swift
//  PhotosMaker
//
//  Created by Darsky on 2018/2/24.
//  Copyright © 2018年 Darsky. All rights reserved.
//

import UIKit

class AssetCollectionViewCell: UICollectionViewCell
{
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var selectButton: UIButton!
    @IBOutlet weak var durationLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
