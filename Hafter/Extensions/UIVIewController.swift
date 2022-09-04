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
    
    func setupMainTitleView() -> UIView {
        let view = UIView()
        
        let imageView = UIImageView()
        imageView.image = UIImage.image(named: "hafter_logo_circle")
        let label = UILabel()
        label.text = "hereafter"
        
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        imageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: label.bottomAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor).isActive = true
        
        label.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 5).isActive = true
        label.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        return view
    }
}
