//
//  UIWindow.swift
//  Hafter
//
//  Created by Artur Olar on 29.03.2022.
//

import UIKit

extension UIWindow {
    
    func setRootViewController(_ controller: UIViewController, animated: Bool, completion: ((Bool) -> Void)?) {
        let present = { [weak self] in
            guard let strongSelf = self else {
                completion?(false)
                return
            }
            if animated {
                UIView.transition(with: strongSelf, duration: CATransaction.animationDuration(), options: [.transitionCrossDissolve], animations: { [weak self] in
                    self?.rootViewController = controller
                    }, completion: completion)
            } else {
                strongSelf.rootViewController = controller
                completion?(true)
            }
        }
        present()
    }
}
