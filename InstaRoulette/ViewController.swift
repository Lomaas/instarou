import UIKit
import Photos
import AssetsLibrary

class ViewController: UIViewController {
    var assets = [PHAsset]()
    let docController  = UIDocumentInteractionController()
    
    var startFrameOrigin: CGPoint!
    var endCenterPoint: CGPoint!
    var bottomCenterPoint: CGPoint!
    
    let maxSpinTimesPhaseOne = 15
    let maxSpinTimesPhaseTwo = 16
    
    var animationDuration: Double!
    var spinned = 0
    
    var isAnimating = false
    
    var myImage1 = UIImageView(frame: CGRectMake(20, -250, 250, 250))
    var myImage2 = UIImageView(frame: CGRectMake(20, -250, 250, 250))
    var myImage3 = UIImageView(frame: CGRectMake(20, -250, 250, 250))
    
    var images = [UIImage]()
    var currentImageIndex = 0
    
    @IBOutlet weak var bulletImage: UIImageView!
    
    @IBAction func didPressInstaRoulette(sender: AnyObject) {
        if assets.count == 0 {
            presentAlertView("No pictures", message: "")
            return
        }
        
//        let pic3 = arc4random_uniform(UInt32(assets.count))
        
        for index in 0...assets.count - 1 {
            if index > 10 {
                break
            }
            self.getImageFromAsset(assets[index]) { (image) -> Void in
                self.images.append(image)
            }
        }
        configureAndStartAnimation()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        myImage1.image = UIImage(named: "blurredimage")
        myImage1 = configureImageView(myImage1)
        myImage2.image = UIImage(named: "blurredimage2")
        myImage2 = configureImageView(myImage2)
        myImage3.image = UIImage(named: "blurredimage3")
        myImage3 = configureImageView(myImage3)
        
        view.addSubview(myImage1)
        view.addSubview(myImage2)
        view.addSubview(myImage3)
        
        fetchAssets()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("Did Receive memory warning")
    }
    
    func configureImageView(image: UIImageView) -> UIImageView {
        image.layer.cornerRadius = 3.0
        image.layer.backgroundColor = UIColor.whiteColor().CGColor
        image.layer.borderWidth = 2.0
        image.layer.borderColor = UIColor.whiteColor().CGColor
        image.backgroundColor = UIColor.clearColor()
        image.contentMode = UIViewContentMode.ScaleAspectFill
        image.clipsToBounds = true
        return image
    }
    
    func configureAndStartAnimation() {
        if isAnimating { return }
        
        isAnimating = true
        spinned = 0
        animationDuration = 0.75
        times = 0
        
        endCenterPoint = CGPointMake(self.view.center.x, view.frame.size.height/2)
        bottomCenterPoint = CGPointMake(self.view.center.x, view.frame.size.height + myImage3.frame.height/2)
        
        var timer = NSTimer.scheduledTimerWithTimeInterval(0, target: self, selector: Selector("start"), userInfo: nil, repeats: false)
        timer = NSTimer.scheduledTimerWithTimeInterval(animationDuration/3, target: self, selector: Selector("start"), userInfo: nil, repeats: false)
        timer = NSTimer.scheduledTimerWithTimeInterval((animationDuration/3) * 2, target: self, selector: Selector("start"), userInfo: nil, repeats: false)
    }
    
    var times = 0
    
    func start() {
        print("Start")
        if times == 0 {
            animate(myImage1)
        } else if times == 1 {
            animate(myImage2)
        } else {
            animate(myImage3)
        }
        times++
    }
    
    func animate(view: UIView) {
        setStartPos(view)
        setImage(view as! UIImageView)
        
        if spinned >= maxSpinTimesPhaseTwo {
            animateFinish(myImage1)
            return
        }
        
//        if spinned > maxSpinTimesPhaseOne {
//            animationDuration += 0.01
//        }
        
        UIView.animateWithDuration(animationDuration, animations: { () -> Void in
            view.center = self.bottomCenterPoint
        }) { (finished) -> Void in
            self.spinned++
            self.animate(view)
        }
    }
    
    func animateFinish(view: UIView) {
        if isAnimating == false {
            return
        }
        
        isAnimating = false
        setStartPos(view)

        UIView.animateWithDuration(animationDuration, animations: { () -> Void in
            view.center = self.endCenterPoint
        }) { (finished) -> Void in
            print("test")
            let image = view as! UIImageView
            self.storeImage(image.image!)
        }
    }
    
    func setStartPos(view: UIView) {
        view.center.y = -view.frame.height/2
        view.center.x = self.view.center.x
    }
    
    func setImage(view: UIImageView) {
        if images.count == 0 {
            return
        }
        
        view.image = images[currentImageIndex]
        currentImageIndex++
        currentImageIndex = currentImageIndex%(images.count - 1)
        print("currentImageIndex: \(currentImageIndex)")
    }

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
        
//        if UIApplication.sharedApplication().canOpenURL(instagramURL) {
            UIApplication.sharedApplication().openURL(instagramURL)
//        } else {
//            presentAlertView("Instagram app not found", message: "An Instagram app is required to be installed on your phone")
//        }
    }
    
    func presentAlertView(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
}

