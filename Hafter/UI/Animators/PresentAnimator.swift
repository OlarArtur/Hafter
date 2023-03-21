//
//  AlertPresentAnimator.swift
//  Hafter
//
//  Created by Artur Olar on 06.04.2022.
//

import UIKit

@objc class PresentAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from), let toVC = transitionContext.viewController(forKey: .to), let snapshot = fromVC.view.snapshotView(afterScreenUpdates: true) else {
            return
        }
        snapshot.tag = MenuAnimatorHelper.snapshotTag
        transitionContext.containerView.insertSubview(toVC.view, aboveSubview: fromVC.view)
        let final = CGRect(x: fromVC.view.frame.origin.x, y: fromVC.view.frame.origin.y, width: fromVC.view.frame.width, height: fromVC.view.frame.height)
        
        let toOn = final.offsetBy(dx: 0, dy: -fromVC.view.safeAreaLayoutGuide.layoutFrame.height)
        toVC.view.frame = toOn
//        transitionContext.containerView.inse
//         tSubview(snapshot, belowSubview: toVC.view)
        
        let duration = self.transitionDuration(using: transitionContext)
        UIView.animate(withDuration: duration, animations: {
            toVC.view.frame = final
        }, completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
