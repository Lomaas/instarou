import Foundation
import UIKit

class AnimationUtil {
    let velocity: CGFloat
    let totalHeight: CGFloat
    let firstAnimationCenterPoint: CGPoint!
    let startFrameOrigin: CGPoint!
    let endCenterPoint: CGPoint!
    let bottomCenterPoint: CGPoint!
    let imageView: UIImageView
    
    var delegate: AnimationFromTopToBottomDelegate?
    
    init(imageView: UIImageView, velocity: CGFloat, totalHeight: CGFloat, firstAnimationCenterPoint: CGPoint, startFrameOrigin: CGPoint, endCenterPoint: CGPoint, bottomCenterPoint: CGPoint) {
        self.velocity = velocity
        self.totalHeight = totalHeight
        self.firstAnimationCenterPoint = firstAnimationCenterPoint
        self.startFrameOrigin = startFrameOrigin
        self.endCenterPoint = endCenterPoint
        self.bottomCenterPoint = bottomCenterPoint
        self.imageView = imageView
        
        self.imageView.center.x = startFrameOrigin.x
        self.imageView.center.y = startFrameOrigin.y
    }
    
    func getDurationFirstPart() -> CGFloat {
        return imageView.frame.height / CGFloat(velocity)
    }
    
    func getDurationSecondPart() -> CGFloat {
        return (totalHeight - imageView.frame.height) / CGFloat(velocity)
    }
    
    func animateFirstPart() {
        let duration = getDurationFirstPart()
        
        doAnimation(Double(duration), endPoint: firstAnimationCenterPoint) { (finished) -> Void in
            
            self.delegate?.animateNextImage()
            self.animateSecondPart(duration)
        }
    }
    
    func animateSecondPart(firstAnimDuration: CGFloat) {
        let duration = getDurationSecondPart()
        
        doAnimation(Double(duration), endPoint: bottomCenterPoint) { (finished) -> Void in
            self.delegate?.animationFinished()
        }
    }
    
    func animateSecondPartOfFinish(firstAnimDuration: CGFloat) {
        let duration = 1.0 - firstAnimDuration
        
        doAnimation(Double(duration), endPoint: bottomCenterPoint) { (finished) -> Void in
            self.delegate?.animationFinished()
        }
    }
    
    func doAnimation(duration: Double, endPoint: CGPoint, completionHandler: (finished: Bool) -> Void) {
        UIView.animateWithDuration(duration, delay: 0, options: UIViewAnimationOptions.CurveLinear, animations: { () -> Void in
            self.imageView.center = endPoint
        }) { (finished) -> Void in
            completionHandler(finished: finished)
        }
    }
}