//
//  CustomImageView.swift
//  InstaRoulette
//
//  Created by Simen Johannessen on 24/06/15.
//  Copyright © 2015 lomas. All rights reserved.
//

import UIKit
import Photos
import AssetsLibrary

class CustomImageView: UIImageView {
    @IBOutlet weak var instaRouletteLabel: UILabel!
    
    var asset: PHAsset?
}
