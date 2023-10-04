//
//  AlertPresentAnimator.swift
//  Hafter
//
//  Created by Artur Olar on 06.04.2022.
//

import UIKit

protocol TransitionManagerDelegate: AnyObject {
    func dismiss()
}

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

@objc final class FoggingViewPresentAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    weak var delegate: TransitionManagerDelegate?
    
    var snapshot: UIView? {
        didSet {
            if delegate != nil {
                let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismiss))
                snapshot?.addGestureRecognizer(tapGestureRecognizer)
            }
        }
    }
    
    @objc private func dismiss() {
        delegate?.dismiss()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from), let toVC = transitionContext.viewController(forKey: .to), let snapshot = fromVC.view.snapshotView(afterScreenUpdates: true) else {
            return
        }
        transitionContext.containerView.insertSubview(toVC.view, aboveSubview: fromVC.view)
        let fromHeight = fromVC.view.frame.height / 2
        let final = CGRect(x: fromVC.view.frame.origin.x, y: fromHeight - 70, width: fromVC.view.frame.width, height: fromHeight + 70)
        let toOn = final.offsetBy(dx: 0, dy: fromVC.view.safeAreaLayoutGuide.layoutFrame.height)
        toVC.view.frame = toOn
        let foggingView = UIView(frame: snapshot.bounds)
        self.snapshot = foggingView
        foggingView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        snapshot.addSubview(foggingView)
        transitionContext.containerView.insertSubview(snapshot, belowSubview: toVC.view)
        let duration = self.transitionDuration(using: transitionContext)
        
        UIView.animate(withDuration: duration, animations: {
            toVC.view.frame = final
        }, completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}


@objc final class ExpandViewPresentAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    private var snapshot: UIView?
    private var expandingView: UIView?
    var startingRect: CGRect = .zero
    var color: UIColor?
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {

        guard let fromViewController = transitionContext.viewController(forKey: .from),
              let toViewController = transitionContext.viewController(forKey: .to),
              let presentedControllerView = transitionContext.view(forKey: .to) else {
            return
        }

        toViewController.beginAppearanceTransition(true, animated: true)
        let originalCenter = presentedControllerView.center
        let originalSize = presentedControllerView.frame.size

        let final = fromViewController.view.frame
        
        expandingView = UIView()
        expandingView?.backgroundColor = color
        expandingView?.frame = startingRect
        transitionContext.containerView.addSubview(expandingView!)

        presentedControllerView.center = startingRect.origin
        presentedControllerView.frame = fromViewController.view.bounds
        presentedControllerView.transform = CGAffineTransform(scaleX: 1, y: 0.001)
        presentedControllerView.alpha = 0
        transitionContext.containerView.addSubview(presentedControllerView)
        let duration = transitionDuration(using: transitionContext)

        UIView.animate(withDuration: duration, animations: {
            self.expandingView?.frame = final
            presentedControllerView.transform = CGAffineTransform.identity
            presentedControllerView.alpha = 1
            presentedControllerView.center = originalCenter
        }, completion: { (_) in
            transitionContext.completeTransition(true)
            self.expandingView?.isHidden = true
            if toViewController.modalPresentationStyle == .custom {
                toViewController.endAppearanceTransition()
            }
            fromViewController.endAppearanceTransition()
        })
    }
}
