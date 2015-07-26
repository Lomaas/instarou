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
    let maxSpinTimes = Int(random(7...19))
    let maxImagesInMemory = 25
    let imageHeight = 275.0
    let imageWidth = 275.0
    let velocity = CGFloat(2000)
    var spinned = 0
    
    var finishAnimationCounter = 0
    lazy var finishAnimationEndPointsArray = [CGPoint]()
    var firstAnimationCenterPoint: CGPoint!
    
    var hasFetchedAssets = false
    var isAnimating = false
    
    var images = [CustomImageView]()
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        finishAnimationEndPointsArray = [
            CGPointMake(self.view.center.x, self.view.center.y + CGFloat(imageHeight)),
            CGPointMake(self.view.center.x, self.view.center.y),
            CGPointMake(self.view.center.x, self.view.center.y - CGFloat(imageHeight))
        ]
        firstAnimationCenterPoint = CGPointMake(view.center.x, CGFloat(imageHeight/2))
        fetchAssets()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("Did Receive memory warning")
    }
    
    func getImageView(image: UIImage) -> CustomImageView {
        let imageView = CustomImageView(frame: CGRectMake(0, 0, CGFloat(imageWidth), CGFloat(imageHeight)))
        imageView.image = image
//        imageView.layer.cornerRadius = 3.0
        imageView.layer.backgroundColor = UIColor.whiteColor().CGColor
//        imageView.layer.borderWidth = 2.0
//        imageView.layer.borderColor = UIColor.whiteColor().CGColor
        imageView.backgroundColor = UIColor.clearColor()
        imageView.contentMode = UIViewContentMode.ScaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }
    
    func configureAndStartAnimation() {
        if isAnimating { return }
        
        isAnimating = true
        spinned = 0
        finishAnimationCounter = 0

        animateNextImage()
    }

    func animateFinish() {
        if isAnimating == false {
            return
        }
        
        if finishAnimationCounter >= finishAnimationEndPointsArray.count {
            isAnimating = false
            return
        }
        
        var firstAnimationCenterPoint = CGPointMake(view.center.x, CGFloat(imageHeight/2))
        let imageView1 = getNextImageView()
        
        let bottomCenterPoint = finishAnimationEndPointsArray[finishAnimationCounter];
        if firstAnimationCenterPoint.y >= bottomCenterPoint.y {
            firstAnimationCenterPoint = bottomCenterPoint
        }

        let animationImageView1 = AnimationImageView(imageView: imageView1,
            velocity: velocity,
            totalHeight: self.getTotalHeight(),
            firstAnimationCenterPoint: firstAnimationCenterPoint,
            startFrameOrigin: getStartPos(imageView1),
            bottomCenterPoint: bottomCenterPoint
        )
        
        finishAnimationCounter++
        animationImageView1.delegate = self
        animationImageView1.animateFirstPart()
        
        // Store image when animation is done
        // self.storeImage(imageView.image!)
    }
    
    func getStartPos(imageView: UIImageView) -> CGPoint {
        return CGPointMake(self.view.center.x, -CGFloat(imageHeight/2))
    }
    
    func getTotalHeight() -> CGFloat {
        return self.view.frame.size.height + CGFloat(imageHeight)
    }
    
    func getNextImageView() -> CustomImageView {
        let imageView = images[currentImageIndex]
        currentImageIndex++
        currentImageIndex = currentImageIndex%(images.count - 1)
        return imageView
    }
    
    func createOverlay(imageView: CustomImageView) {
        let height = CGFloat(23)
        let label = UILabel(frame: CGRectMake(3, imageView.frame.size.height - height, imageView.frame.size.width, 20))
        label.textColor = UIColor.whiteColor()
        let date = imageView.asset?.creationDate?.toString("yyyy-MM-dd") ?? ""
        
        if let location = imageView.asset?.location {
            LocationService.getLocationAddress(location) { (address) -> Void in
                label.text = "\(address), \(date)"
            }
        } else {
            label.text = "\(date)"
        }
        
        let width = CGFloat(45)
        let image = UIImageView(frame: CGRectMake(imageView.frame.size.width - width, imageView.frame.size.height - 40, width - 5, width - 5))
        image.image = UIImage(named: "bullet")
        image.contentMode = UIViewContentMode.ScaleAspectFit
        imageView.addSubview(label)
        imageView.addSubview(image)
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
        
        let animationImageView = AnimationImageView(imageView: imageView, velocity: velocity, totalHeight: self.getTotalHeight(), firstAnimationCenterPoint: firstAnimationCenterPoint, startFrameOrigin: getStartPos(imageView), bottomCenterPoint: bottomCenterPoint)
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
