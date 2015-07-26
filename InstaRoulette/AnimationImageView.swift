import Foundation
import UIKit

class AnimationImageView {
    let velocity: CGFloat
    let totalHeight: CGFloat
    let firstAnimationCenterPoint: CGPoint!
    let startFrameOrigin: CGPoint!
    let bottomCenterPoint: CGPoint!
    let imageView: UIImageView
    
    var delegate: AnimationFromTopToBottomDelegate?
    
    init(imageView: UIImageView, velocity: CGFloat, totalHeight: CGFloat, firstAnimationCenterPoint: CGPoint, startFrameOrigin: CGPoint, bottomCenterPoint: CGPoint) {
        self.velocity = velocity
        self.totalHeight = totalHeight
        self.firstAnimationCenterPoint = firstAnimationCenterPoint
        self.startFrameOrigin = startFrameOrigin
        self.bottomCenterPoint = bottomCenterPoint
        self.imageView = imageView
        
        self.imageView.center.x = startFrameOrigin.x
        self.imageView.center.y = startFrameOrigin.y
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
            self.animateSecondPart()
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