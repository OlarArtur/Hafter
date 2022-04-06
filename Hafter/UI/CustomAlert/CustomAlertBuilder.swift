//
//  CustomAlertBuilder.swift
//  Hafter
//
//  Created by Artur Olar on 06.04.2022.
//

import UIKit

protocol AlertViewOutput: UIView {
    var outputAction: (() -> Void)? { get set }
}

final class CustomAlertBuilder {
    
    static func build(with alertView: AlertViewOutput, actions: [CustomAlertAction] = []) -> UIViewController? {
        let statusModuleStoryboard = UIStoryboard(name: "CustomAlert", bundle: nil)
        if let alertVC = statusModuleStoryboard.instantiateInitialViewController() as? CustomAlertViewController {
            alertVC.add(alertView: alertView, actions: actions)
            return alertVC
        }
        return nil
    }
}
