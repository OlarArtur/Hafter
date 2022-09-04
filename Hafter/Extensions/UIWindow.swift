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
            guard let self = self else {
                completion?(false)
                return
            }
            if animated {
                UIView.transition(with: self, duration: CATransaction.animationDuration(), options: [.transitionCrossDissolve], animations: { [weak self] in
                    self?.rootViewController = controller
                    }, completion: completion)
            } else {
                self.rootViewController = controller
                completion?(true)
            }
        }
        present()
    }
}
