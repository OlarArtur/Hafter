//
//  PresentMenuAnimator.swift
//  Hafter
//
//  Created by Artur Olar on 07.04.2022.
//

import UIKit

class MenuAnimatorHelper {
    static let snapshotTag: Int = 12345
    static let menuXOffset = 0.25
}

class PresentMenuAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from), let toVC = transitionContext.viewController(forKey: .to), let snapshot = fromVC.view.snapshotView(afterScreenUpdates: true) else {
            return
        }
        
        let duration = self.transitionDuration(using: transitionContext)
        let containerView = transitionContext.containerView
        
        containerView.insertSubview(toVC.view, belowSubview: fromVC.view)
        
        snapshot.tag = MenuAnimatorHelper.snapshotTag
        snapshot.isUserInteractionEnabled = false
        snapshot.layer.shadowOpacity = 0.7
        containerView.insertSubview(snapshot, aboveSubview: toVC.view)
        fromVC.view.isHidden = true
        
        let screenBounds = UIScreen.main.bounds
        let finalFrameTopLeftCorner = CGPoint(x: screenBounds.width * MenuAnimatorHelper.menuXOffset, y: 0)
        let snapshotFinalFrame = CGRect(origin: finalFrameTopLeftCorner, size: screenBounds.size)
        
        UIView.animate(withDuration: duration, animations: {
            snapshot.frame = snapshotFinalFrame
        }, completion: { _ in
            fromVC.view.isHidden = false
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}

class MenuDismissAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from), let toVC = transitionContext.viewController(forKey: .to) else {
            return
        }
        let duration = self.transitionDuration(using: transitionContext)
        let containerView = transitionContext.containerView
        
        let snapshot = containerView.viewWithTag(MenuAnimatorHelper.snapshotTag)
        
        UIView.animate(withDuration: duration,animations: {
            snapshot?.frame = CGRect(origin: CGPoint.zero, size: UIScreen.main.bounds.size)
        },completion: { _ in
            let didTransitionComplete = !transitionContext.transitionWasCancelled
            if didTransitionComplete {
                containerView.insertSubview(toVC.view, aboveSubview: fromVC.view)
                snapshot?.removeFromSuperview()
            }
            transitionContext.completeTransition(didTransitionComplete)
        })
    }
}
