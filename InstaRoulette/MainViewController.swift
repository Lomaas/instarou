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

protocol AnimationFromTopToBottomDelegate {
    func animateNextImage()
    func animationFinished()
}


class MainViewController: UIViewController {
    var assets = [PHAsset]()
    let maxSpinTimes = Int(random(20...25))
    let maxImagesInMemory = 25
    let imageHeight = 275.0
    let imageWidth = 275.0
    let startVelocity = CGFloat(2000)
    var velocity: CGFloat
    var spinned = 0
    var secondPhaseSpinning: Int!
    var finishAnimationCounter = 0
    let finishAnimationCounterForFinalImage = 1
    lazy var finishAnimationEndPointsArray = [CGPoint]()
    var firstAnimationCenterPoint: CGPoint!
    var finalImage: CustomImageView!
    var hasFetchedAssets = false
    var isAnimating = false
    
    var images = [CustomImageView]()
    var currentImageIndex = 0
    
    @IBOutlet weak var spinButton: UIButton!
    
    required init?(coder aDecoder: NSCoder) {
        velocity = startVelocity
        super.init(coder: aDecoder)
    }
    
    @IBAction func didPressInstaRoulette(sender: AnyObject) {
        if hasFetchedAssets == false || assets.count == 0 {
            fetchAssets({ () -> Void in
                self.start()
            })
            return
        }
        
        if isAnimating {
            return
        }
        
        start()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        secondPhaseSpinning = maxSpinTimes - 2
        finishAnimationEndPointsArray = [
            CGPointMake(self.view.center.x, self.view.center.y + CGFloat(imageHeight)),
            CGPointMake(self.view.center.x, self.view.center.y),
            CGPointMake(self.view.center.x, self.view.center.y - CGFloat(imageHeight))
        ]
        firstAnimationCenterPoint = CGPointMake(view.center.x, CGFloat(imageHeight/2))
        fetchAssets(nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("Did Receive memory warning")
    }
    
    func start() {
        if assets.count == 0 {
            presentAlertView("No pictures", message: "")
            return
        }
        cleanUp()
        
        var counter = 0    // Todo refactor to use async lib
        assets.shuffle()
        
        let count = assets.count > maxImagesInMemory ? maxImagesInMemory : assets.count - 1
        
        for index in 0...count {
            self.getImageFromAsset(assets[index]) { (image) -> Void in
                counter++
                let imageView = self.getImageView(image)
                imageView.asset = self.assets[index]
                self.view.insertSubview(imageView, belowSubview: self.spinButton)
                self.images.append(imageView)
                
                if counter > count {
                    self.configureAndStartAnimation()
                }
            }
        }
    }
    
    func getImageView(image: UIImage) -> CustomImageView {
        let nib = NSBundle.mainBundle().loadNibNamed("CustomImageView", owner: self, options: nil)
        let imageView = nib[0] as! CustomImageView
        imageView.frame = CGRectMake(0, 0, CGFloat(imageWidth), CGFloat(imageHeight))
        imageView.instaRouletteLabel.text = ""
        
        setStartPosForImageView(imageView)
        imageView.image = image
        imageView.layer.backgroundColor = UIColor.whiteColor().CGColor
        imageView.backgroundColor = UIColor.clearColor()
        imageView.contentMode = UIViewContentMode.ScaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }
    
    func configureAndStartAnimation() {
        if isAnimating { return }
        
        isAnimating = true
        spinned = 0
        velocity = startVelocity
        finishAnimationCounter = 0

        animateNextImage()
    }

    func animateFinish() {
        if isAnimating == false {
            return
        }
        
        if finishAnimationCounter >= finishAnimationEndPointsArray.count {
            isAnimating = false
            createOverlay(finalImage)
            storeImage(finalImage.pb_takeSnapshot())
            
            return
        }
        let imageView1 = getNextImageView()
        setStartPosForImageView(imageView1)
        let bottomCenterPoint = finishAnimationEndPointsArray[finishAnimationCounter];
        
        if finishAnimationCounter == finishAnimationCounterForFinalImage {
            finalImage = imageView1
        }
        
        let animationImageView1: AnimationImageView
        if finishAnimationCounter == finishAnimationEndPointsArray.count - 1 {
            animationImageView1 = AnimationImageView(imageView: imageView1,
                velocity: velocity,
                firstAnimationCenterPoint: bottomCenterPoint,
                bottomCenterPoint: bottomCenterPoint,
                shouldAnimateSecondPart: false
            )
        } else {
            animationImageView1 = AnimationImageView(imageView: imageView1,
                velocity: velocity,
                firstAnimationCenterPoint: firstAnimationCenterPoint,
                bottomCenterPoint: bottomCenterPoint,
                shouldAnimateSecondPart: true
            )
        }
        
        finishAnimationCounter++
        animationImageView1.delegate = self
        animationImageView1.animateFirstPart()
    }
    
    func setStartPosForImageView(imageView: UIImageView) {
        imageView.center = CGPointMake(view.frame.width/2, -CGFloat(imageHeight/2))
    }
    
    func getNextImageView() -> CustomImageView {
        let imageView = images[currentImageIndex]
        currentImageIndex++
        currentImageIndex = currentImageIndex%(images.count - 1)
        return imageView
    }
    
    func createOverlay(imageView: CustomImageView) {
        let text = "#instaRoulette"
//        text += imageView.asset?.creationDate?.toString("yyyy-MM-dd") ?? ""
        
        imageView.instaRouletteLabel.text = text
//
//        if let location = imageView.asset?.location {
//            LocationService.getLocationAddress(location) { (address) -> Void in
//                label.text = "\(address), \(date)"
//            }
//        } else {
//            label.text = "\(date)"
//        }
    }
    
    func cleanUp() {
        for image in images {
            image.removeFromSuperview()
        }
        images.removeAll()
    }
    
    // MARK: Fetch images from storage
    
    func fetchAssets(successHandler: (() -> Void)?) {
        let results = PHAsset.fetchAssetsWithMediaType(.Image, options: nil)
        var counter = 0

        results.enumerateObjectsUsingBlock { (object, idx, _) in
            counter++
            if let asset = object as? PHAsset {
                self.assets.append(asset)
            }
            
            if results.count >= counter {
                successHandler?()
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
            if let imageUrl = url {
                self.postToInstagramUrlBased(imageUrl.absoluteString)
            } else {
                self.postToInstagramUrlBased("lalala")
            }
        }
    }
    
    func postToInstagramUrlBased(assetFilePath: String) {
        let caption = "%23instaRoulette%20%40instarouletteapp"
        
        guard let instagramURL = NSURL(string: "instagram://library?AssetPath=\(assetFilePath)&InstagramCaption=\(caption)") else {
            presentAlertView("Error", message: "Could not post image")
            return
        }
        
        if UIApplication.sharedApplication().canOpenURL(instagramURL) {
            UIApplication.sharedApplication().openURL(instagramURL)
        }
    }
    
    func presentAlertView(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
}

extension MainViewController: AnimationFromTopToBottomDelegate {
    func animateNextImage() {
        if spinned >= maxSpinTimes {
            animateFinish()
            return
        }
        
        let bottomCenterPoint = CGPointMake(view.center.x, view.frame.size.height + CGFloat(imageHeight/2))
        let imageView = getNextImageView()
        setStartPosForImageView(imageView)
        
        let animationImageView = AnimationImageView(imageView: imageView,
            velocity: velocity,
            firstAnimationCenterPoint:
            firstAnimationCenterPoint,
            bottomCenterPoint: bottomCenterPoint,
            shouldAnimateSecondPart: true
        )
        animationImageView.delegate = self
        animationImageView.animateFirstPart()
    }
    
    func animationFinished() {
        self.spinned++
    }
}

extension NSDate {
    func toString(format: String) -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.stringFromDate(self)
    }
}

extension UIView {
    func pb_takeSnapshot() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, UIScreen.mainScreen().scale)
        
        drawViewHierarchyInRect(self.bounds, afterScreenUpdates: true)
        
        // old style: layer.renderInContext(UIGraphicsGetCurrentContext())
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
