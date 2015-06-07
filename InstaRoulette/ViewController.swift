import UIKit
import Photos
import AssetsLibrary

class ViewController: UIViewController {
    var assets = [PHAsset]()
    let docController  = UIDocumentInteractionController()

    @IBOutlet weak var bulletImage: UIImageView!
    @IBAction func didPressInstaRoulette(sender: AnyObject) {
        if assets.count == 0 {
            presentAlertView("No pictures", message: "")
            return
        }
        
        let pic = arc4random_uniform(UInt32(assets.count))
        getImageFromAsset(assets[Int(pic)])
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
    
    func getImageFromAsset(asset: PHAsset) {
        let manager = PHImageManager.defaultManager()
        let initialRequestOptions = PHImageRequestOptions()
        initialRequestOptions.deliveryMode = PHImageRequestOptionsDeliveryMode.HighQualityFormat
        initialRequestOptions.resizeMode = PHImageRequestOptionsResizeMode.Exact
        
        manager.requestImageForAsset(asset,
            targetSize: CGSize(width: 1024, height: 1024),
            contentMode: PHImageContentMode.AspectFit,
            options: initialRequestOptions) { (result, _) in
                if let res: UIImage = result {
                    self.storeImage(res)
                } else {
                    self.presentAlertView("Error", message: "An error occured while fetching the random photo")
                }
        }
    }
    
    func storeImage(image: UIImage) {
        let lib = ALAssetsLibrary()
        let orientation = ALAssetOrientation(rawValue: image.imageOrientation.rawValue)!
        
        lib.writeImageToSavedPhotosAlbum(image.CGImage, orientation: orientation, completionBlock: { (url, error) -> Void in
            self.postToInstagramUrlBased(url.absoluteString!)
        })
    }
    
    func postToInstagramUrlBased(assetFilePath: String) {
        let caption = "%23instaroulette"
        let instagramURL = NSURL(string: "instagram://library?AssetPath=\(assetFilePath)&InstagramCaption=\(caption)")!
        
        if UIApplication.sharedApplication().canOpenURL(instagramURL) {
            UIApplication.sharedApplication().openURL(instagramURL)
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

