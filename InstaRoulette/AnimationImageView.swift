import Foundation
import UIKit

class AnimationImageView {
    let velocity: CGFloat
    let totalHeight: CGFloat
    let firstAnimationCenterPoint: CGPoint!
    let bottomCenterPoint: CGPoint!
    let imageView: UIImageView
    let shouldAnimateSecondPart: Bool
    var delegate: AnimationFromTopToBottomDelegate?
    
    init(imageView: UIImageView, velocity: CGFloat, totalHeight: CGFloat, firstAnimationCenterPoint: CGPoint, bottomCenterPoint: CGPoint, shouldAnimateSecondPart: Bool) {
        self.velocity = velocity
        self.totalHeight = totalHeight
        self.firstAnimationCenterPoint = firstAnimationCenterPoint
        self.bottomCenterPoint = bottomCenterPoint
        self.imageView = imageView
        self.shouldAnimateSecondPart = shouldAnimateSecondPart
    }
    
    func getDurationFirstPart() -> Double {
        return Double(imageView.frame.height / CGFloat(velocity))
    }
    
    func getDurationSecondPart() -> Double {
        return Double((totalHeight - imageView.frame.height) / CGFloat(velocity))
    }
    
    func animateFirstPart() {
        doAnimation(getDurationFirstPart(), endPoint: firstAnimationCenterPoint) { (finished) -> Void in
            self.delegate?.animateNextImage()
            if self.shouldAnimateSecondPart {
                self.animateSecondPart()
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