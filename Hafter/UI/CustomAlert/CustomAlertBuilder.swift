//
//  CustomAlertBuilder.swift
//  Hafter
//
//  Created by Artur Olar on 06.04.2022.
//

import UIKit

protocol AlertViewOutput: UIView {
    associatedtype OutputResult
    var outputAction: ((OutputResult) -> Void)? { get set }
}

final class CustomAlertBuilder<T: AlertViewOutput> {
    
    static func build(with alertView: T, actions: [CustomAlertAction] = []) -> UIViewController? {
        let statusModuleStoryboard = UIStoryboard(name: "CustomAlert", bundle: nil)
        if let alertVC = statusModuleStoryboard.instantiateInitialViewController() as? CustomAlertViewController {
            alertVC.add(alertView: alertView, actions: actions)
            return alertVC
        }
        return nil
    }
}
