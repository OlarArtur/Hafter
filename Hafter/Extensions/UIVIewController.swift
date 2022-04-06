//
//  UIVIewController.swift
//  Hafter
//
//  Created by Artur Olar on 01.04.2022.
//

import UIKit

extension UIViewController {
    
    var topmostPresenter: UIViewController {
        guard let presented = presentedViewController, !presented.isBeingDismissed else {
            return self
        }
        return presented.topmostPresenter
    }
    
    func hide(animated: Bool, completion: (() -> ())? = nil) {
        if let navController = self as? UINavigationController {
            navController.popViewController(animated: animated)
        } else if let navController = self.navigationController {
            if navController.viewControllers.count == 1 {
                navController.dismiss(animated: animated, completion: completion)
            } else {
                navController.popViewController(animated: animated)
            }
        } else {
            dismiss(animated: animated, completion: completion)
        }
    }
    
    func showAlert(title: String, message: String, actionTitle: String?) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: actionTitle ?? "Yes", style: .default))
        present(ac, animated: true)
    }
}
