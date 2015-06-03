//
//  ViewController.swift
//  InstaRoulette
//
//  Created by Simen Johannessen on 03/06/15.
//  Copyright (c) 2015 lomas. All rights reserved.
//

import UIKit
import Photos

class ViewController: UIViewController {
    var assets = [PHAsset]()
    let docController  = UIDocumentInteractionController()

    @IBOutlet weak var bulletImage: UIImageView!
    @IBAction func didPressInstaRoulette(sender: AnyObject) {
        if assets.count == 0 {
            presentAlertView("No pictures", message: "")
        }
        
        let pic = arc4random_uniform(UInt32(assets.count))
        
        getImageFromAsset(assets[Int(pic)], successHandler: { (image) -> Void in
            self.postToInstragram(image)
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchAssets()
    }

    func fetchAssets() {
        if let results = PHAsset.fetchAssetsWithMediaType(.Image, options: nil) {
            self.evaluateResult(results)
        } else {
            presentAlertView("Error", message: "An error occured when fetching your images. Did you press yes to allow the app to use photos?")
        }
    }
    
    func evaluateResult(results: PHFetchResult){
        results.enumerateObjectsUsingBlock { (object, idx, _) in
            if let asset = object as? PHAsset {
                self.assets.append(asset)
            }
        }
    }
    
    func getImageFromAsset(asset: PHAsset, successHandler: (image: UIImage) -> Void) {
        let manager = PHImageManager.defaultManager()
        let initialRequestOptions = PHImageRequestOptions()
        initialRequestOptions.deliveryMode = PHImageRequestOptionsDeliveryMode.HighQualityFormat
        initialRequestOptions.resizeMode = PHImageRequestOptionsResizeMode.Exact

        manager.requestImageForAsset(asset,
            targetSize: CGSize(width: 1024, height: 1024),
            contentMode: PHImageContentMode.AspectFit,
            options: initialRequestOptions) { (result, _) in
                if let res: UIImage = result {
                    successHandler(image: res)
                } else {
                    self.presentAlertView("Error", message: "An error occured while fetching the random photo")
                }
        }
    }
    
    func postToInstragram(image: UIImage) {
        var instagramURL = NSURL(string: "instagram://app")!
        
        if UIApplication.sharedApplication().canOpenURL(instagramURL) {
            let documentDirectory = NSHomeDirectory().stringByAppendingPathComponent("Documents")
            let saveImagePath = documentDirectory.stringByAppendingPathComponent("Image.igo")
            let imageData = UIImagePNGRepresentation(image)
            imageData.writeToFile(saveImagePath, atomically: true)
            let imageURL = NSURL.fileURLWithPath(saveImagePath)!
            
            docController.URL = imageURL
            docController.UTI = "com.instagram.exclusivegram"
            docController.annotation = ["InstagramCaption": "#instaroulette"]
            docController.presentOpenInMenuFromRect(CGRectZero, inView: self.view, animated: true)
        } else {
            presentAlertView("Instagram app not found", message: "An Instagram app is required to be installed on your phone")
        }
    }
    
    func presentAlertView(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
}

