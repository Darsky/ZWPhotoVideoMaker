//
//  ViewController.swift
//  PhotosMaker
//
//  Created by Darsky on 2018/2/24.
//  Copyright © 2018年 Darsky. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    @IBAction func didStartButtonTouch(_ sender: Any)
    {
        let viewController:AssetsViewController = AssetsViewController(nibName: "AssetsViewController", bundle: Bundle.main)
        self.present(UINavigationController.init(rootViewController: viewController), animated: true)
        {
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

