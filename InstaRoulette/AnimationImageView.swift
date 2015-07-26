import Foundation
import UIKit

class AnimationImageView {
    let velocity: CGFloat
    let firstAnimationCenterPoint: CGPoint!
    let bottomCenterPoint: CGPoint!
    let imageView: UIImageView
    let shouldAnimateSecondPart: Bool
    var delegate: AnimationFromTopToBottomDelegate?
    
    init(imageView: UIImageView, velocity: CGFloat, firstAnimationCenterPoint: CGPoint, bottomCenterPoint: CGPoint, shouldAnimateSecondPart: Bool) {
        self.velocity = velocity
        self.firstAnimationCenterPoint = firstAnimationCenterPoint
        self.bottomCenterPoint = bottomCenterPoint
        self.imageView = imageView
        self.shouldAnimateSecondPart = shouldAnimateSecondPart
    }
    
    func getDurationFirstPart() -> Double {
        return Double((firstAnimationCenterPoint.y + imageView.frame.height/2) / CGFloat(velocity))
    }
    
    func getDurationSecondPart() -> Double {
        return Double((bottomCenterPoint.y - imageView.frame.height/2) / CGFloat(velocity))
    }
    
    func animateFirstPart() {
        doAnimation(getDurationFirstPart(), endPoint: firstAnimationCenterPoint) { (finished) -> Void in
            self.delegate?.animateNextImage()
            
            if self.shouldAnimateSecondPart {
                self.animateSecondPart()
            } else {
                self.delegate?.animationFinished()
            }
        }
    }
    
    func animateSecondPart() {
        doAnimation(getDurationSecondPart(), endPoint: bottomCenterPoint) { (finished) -> Void in
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