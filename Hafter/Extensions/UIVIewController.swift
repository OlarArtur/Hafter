//
//  UIVIewController.swift
//  Hafter
//
//  Created by Artur Olar on 01.04.2022.
//

import UIKit

extension UIViewController {
    
    func showAlert(title: String, message: String, actionTitle: String?) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: actionTitle ?? "Yes", style: .default))
        present(ac, animated: true)
    }
}
