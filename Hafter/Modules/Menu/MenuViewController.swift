//
//  MenuViewController.swift
//  Hafter
//
//  Created by Artur Olar on 06.04.2022.
//

import UIKit

final class MenuViewController: BaseViewController<MenuViewModelProtocol> {
    
    deinit {
        print("deinit MenuViewController")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        view.addGestureRecognizer(tap)
    }
    
    @objc private func tapAction() {
        dismiss(animated: true)
    }
}

extension MenuViewController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PresentMenuAnimator()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return MenuDismissAnimator()
    }
}
