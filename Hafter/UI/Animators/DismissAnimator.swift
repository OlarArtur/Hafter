//
//  AlertDismissAnimator.swift
//  Hafter
//
//  Created by Artur Olar on 06.04.2022.
//

import UIKit

@objc class DismissAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from), let toVC = transitionContext.viewController(forKey: .to) else {
            return
        }
        transitionContext.containerView.insertSubview(toVC.view, belowSubview: fromVC.view)
        let final = transitionContext.finalFrame(for: toVC)
        
        let toOff = final.offsetBy(dx: -final.width, dy: 0)
        
        fromVC.view.frame = final
        
        let duration = self.transitionDuration(using: transitionContext)
        UIView.animate(withDuration: duration, animations: {
            fromVC.view.frame = toOff
        }, completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
