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
        let alertVC = CustomAlertViewController()
        alertVC.add(alertView: alertView, actions: actions)
        return alertVC
    }
}
