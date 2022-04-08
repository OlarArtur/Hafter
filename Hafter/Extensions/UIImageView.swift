//
//  UIImageView.swift
//  Hafter
//
//  Created by Artur Olar on 08.04.2022.
//

import UIKit

extension UIImageView {
    
    func transition(to image: UIImage?) {
        UIView.transition(with: self, duration: 0.2, options: [.transitionCrossDissolve], animations: {
            self.image = image
        }, completion: nil)
    }
}
