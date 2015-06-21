import UIKit
import Photos
import AssetsLibrary

extension Array {
    mutating func shuffle() {
        for i in 0..<(count - 1) {
            let j = Int(arc4random_uniform(UInt32(count - i))) + i
            swap(&self[i], &self[j])
        }
    }
}

func random(range: Range<UInt32>) -> UInt32 {
    return range.startIndex + arc4random_uniform(range.endIndex - range.startIndex + 1)
}

class ViewController: UIViewController {
    var assets = [PHAsset]()
    
    var firstAnimationCenterPoint: CGPoint!
    var startFrameOrigin: CGPoint!
    var endCenterPoint: CGPoint!
    var bottomCenterPoint: CGPoint!
    
    let maxSpinTimes = Int(random(7...19))
    let maxImagesInMemory = 25
    
    var animationDuration: CGFloat = 0.7
    var spinned = 0
    
    var hasFetchedAssets = false
    var isAnimating = false
    let imageHeight = 250.0
    let imageWidth = 250.0
    
    var images = [UIImageView]()
    var currentImageIndex = 0
    
    @IBOutlet weak var spinButton: UIButton!
    @IBAction func didPressInstaRoulette(sender: AnyObject) {
        // TODO: Fix this bug when first run
        if hasFetchedAssets == false {
            fetchAssets()
            return
        }
        
        if isAnimating {
            return
        }
        
        if assets.count == 0 {
            presentAlertView("No pictures", message: "")
            return
        }
        cleanUp()
        
        var done = 0    // Todo refactor to use async lib
        assets.shuffle()
        let count = assets.count > maxImagesInMemory ? maxImagesInMemory : assets.count - 1
        
        for index in 0...count {
            self.getImageFromAsset(assets[index]) { (image) -> Void in
                done++
                let imageView = self.getImageView(image)
                self.view.insertSubview(imageView, belowSubview: self.spinButton)
                self.images.append(imageView)
                
                if done > self.maxImagesInMemory {
                    self.configureAndStartAnimation()
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchAssets()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("Did Receive memory warning")
    }
    
    func getImageView(image: UIImage) -> UIImageView {
        let imageView = UIImageView(frame: CGRectMake(0.0, CGFloat(-imageHeight), CGFloat(imageWidth), CGFloat(imageHeight)))
        imageView.image = image
        imageView.layer.cornerRadius = 3.0
        imageView.layer.backgroundColor = UIColor.whiteColor().CGColor
        imageView.layer.borderWidth = 3.0
        imageView.layer.borderColor = UIColor.whiteColor().CGColor
        imageView.backgroundColor = UIColor.clearColor()
        imageView.contentMode = UIViewContentMode.ScaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }
    
    func configureAndStartAnimation() {
        if isAnimating { return }
        
        isAnimating = true
        spinned = 0
        
        firstAnimationCenterPoint = CGPointMake(view.center.x, CGFloat(imageHeight/2))
        endCenterPoint = CGPointMake(view.center.x, view.frame.size.height/2)
        bottomCenterPoint = CGPointMake(view.center.x, view.frame.size.height + CGFloat(imageHeight/2))
        animateNextImage()
    }
    
    func animateNextImage() {
        if spinned >= maxSpinTimes {
            animateFinish()
            return
        }
        let imageView = getNextImageView()
        setStartPos(imageView)
        animateFirstPart(imageView)
    }
    
    func animateFirstPart(imageView: UIImageView) {
        let duration = animationDuration / (getTotalHeight() / imageView.frame.height)
        
        UIView.animateWithDuration(Double(duration), delay: 0, options: UIViewAnimationOptions.CurveLinear, animations: { () -> Void in
            //            imageView.transform = CGAffineTransformMakeTranslation(0, self.firstAnimationCenterPoint.y - imageView.center.y)
            imageView.center = self.firstAnimationCenterPoint
            }) { (finished) -> Void in
                self.animateNextImage()
                self.animateSecondPart(imageView, firstAnimDuration: duration)
        }
    }
    
    func animateSecondPart(imageView: UIImageView, firstAnimDuration: CGFloat) {
        let duration = animationDuration - firstAnimDuration
        
        UIView.animateWithDuration(Double(duration), delay: 0, options: UIViewAnimationOptions.CurveLinear, animations: { () -> Void in
            //            imageView.transform = CGAffineTransformMakeTranslation(0, self.bottomCenterPoint.y - imageView.center.y)
            imageView.center = self.bottomCenterPoint
            }) { (finished) -> Void in
                self.spinned++
        }
    }
    
    func animateSecondPartOfFinish(imageView: UIImageView, firstAnimDuration: CGFloat) {
        let duration = animationDuration - firstAnimDuration
        
        UIView.animateWithDuration(Double(duration), delay: 0, options: UIViewAnimationOptions.CurveLinear, animations: { () -> Void in
            //            imageView.transform = CGAffineTransformMakeTranslation(0, self.bottomCenterPoint.y - imageView.center.y)
            imageView.center = self.bottomCenterPoint
            }) { (finished) -> Void in
                self.spinned++
        }
    }
    
    func animateFinish() {
        if isAnimating == false {
            return
        }
        
        isAnimating = false
        
        let imageView1 = getNextImageView()
        let endPos1 = CGPointMake(self.view.center.x, self.view.center.y - CGFloat(imageHeight))
        setStartPos(imageView1)
        
        let imageView2 = getNextImageView()
        let endPos2 = CGPointMake(self.view.center.x, self.view.center.y)
        setStartPos(imageView2)
        
        let imageView3 = getNextImageView()
        let endPos3 = CGPointMake(self.view.center.x, self.view.center.y + CGFloat(imageHeight))
        setStartPos(imageView3)
        
        typealias Tuple = (imageView: UIImageView, endPos: CGPoint, duration: CGFloat)
        let finishImages: [Tuple] = [
            (imageView3, endPos3, self.animationDuration / ((self.getTotalHeight() - CGFloat(imageHeight)) / endPos3.y)),
            (imageView2, endPos2, self.animationDuration / ((self.getTotalHeight() - CGFloat(imageHeight)) / endPos2.y)),
            (imageView1, endPos1, self.animationDuration / ((self.getTotalHeight() - CGFloat(imageHeight)) / endPos1.y))
            
        ]
        
        var index = 0
        
        func secondAnim(imageMeta: Tuple) {
            UIView.animateWithDuration(Double(imageMeta.duration), delay: 0, options: UIViewAnimationOptions.CurveLinear, animations: { () -> Void in
                //            imageView.transform = CGAffineTransformMakeTranslation(0, self.bottomCenterPoint.y - imageView.center.y)
                imageMeta.imageView.center = imageMeta.endPos
                }) { (finished) -> Void in
                    
            }
        }
        
        func firstAnim(imageMeta: Tuple) {
            let endPosY = imageMeta.endPos.y < self.firstAnimationCenterPoint.y ? imageMeta.endPos.y : self.firstAnimationCenterPoint.y
            
            let duration = self.animationDuration / (self.getTotalHeight() / CGFloat(self.imageHeight))
            
            
            
            UIView.animateWithDuration(Double(duration), delay: 0, options: UIViewAnimationOptions.CurveLinear, animations: { () -> Void in
                imageMeta.imageView.center.y = endPosY
                }) { (finished) -> Void in
                    if imageMeta.endPos.y > self.firstAnimationCenterPoint.y {
                        secondAnim(imageMeta)
                    }
                    index++
                    if index < finishImages.count {
                        firstAnim(finishImages[index])
                    }
            }
        }
        
        firstAnim(finishImages[index])
        //        UIView.animateWithDuration(Double(animationDuration), animations: { () -> Void in
        //            imageView.center = self.endpos1
        //        }) { (finished) -> Void in
        //            self.storeImage(imageView.image!)
        //        }
    }
    
    func setStartPos(imageView: UIImageView) {
        imageView.center.y = -CGFloat(imageHeight/2)
        imageView.center.x = self.view.center.x
    }
    
    func getTotalHeight() -> CGFloat {
        return self.view.frame.size.height + CGFloat(imageHeight)
    }
    
    func getNextImageView() -> UIImageView {
        let imageView = images[currentImageIndex]
        currentImageIndex++
        currentImageIndex = currentImageIndex%(images.count - 1)
        return imageView
    }
    
    func cleanUp() {
        for image in images {
            image.removeFromSuperview()
        }
        images.removeAll()
    }
    
    // MARK: Fetch images from storage
    
    func fetchAssets() {
        let results = PHAsset.fetchAssetsWithMediaType(.Image, options: nil)
        self.evaluateResult(results)
    }
    
    func evaluateResult(results: PHFetchResult){
        results.enumerateObjectsUsingBlock { (object, idx, _) in
            if let asset = object as? PHAsset {
                self.assets.append(asset)
            }
        }
        hasFetchedAssets = true
    }
    
    func getImageFromAsset(asset: PHAsset, successHandler: ((image: UIImage) -> Void)?) {
        let manager = PHImageManager.defaultManager()
        let initialRequestOptions = PHImageRequestOptions()
        initialRequestOptions.deliveryMode = PHImageRequestOptionsDeliveryMode.HighQualityFormat
        initialRequestOptions.resizeMode = PHImageRequestOptionsResizeMode.Exact
        
        manager.requestImageForAsset(asset,
            targetSize: CGSize(width: 1024, height: 1024),
            contentMode: PHImageContentMode.AspectFit,
            options: initialRequestOptions) { (result, _) in
                if let res: UIImage = result {
                    successHandler?(image: res)
                    //                    self.storeImage(res)
                } else {
                    self.presentAlertView("Error", message: "An error occured while fetching the random photo")
                }
        }
    }
    
    // MARK: Store & post to instagram
    
    func storeImage(image: UIImage) {
        let lib = ALAssetsLibrary()
        let orientation = ALAssetOrientation(rawValue: image.imageOrientation.rawValue)!
        lib.writeImageToSavedPhotosAlbum(image.CGImage!, orientation: orientation) { (url, error) -> Void in
            print("Hello")
            self.postToInstagramUrlBased(url.absoluteString)
        }
    }
    
    func postToInstagramUrlBased(assetFilePath: String) {
        let caption = "%23instaroulette"
        let instagramURL = NSURL(string: "instagram://library?AssetPath=\(assetFilePath)&InstagramCaption=\(caption)")!
        
        if UIApplication.sharedApplication().canOpenURL(instagramURL) {
            UIApplication.sharedApplication().openURL(instagramURL)
        }
        //            presentAlertView("Instagram app not found", message: "An Instagram app is required to be installed on your phone")
        //        }
    }
    
    func presentAlertView(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
}

