//
//  CustomAlertPresenter.swift
//  Hafter
//
//  Created by Artur Olar on 06.04.2022.
//

import UIKit

protocol CustomAlertRouterProtocol {
    func showChooserView(completion: ((HereafterMovieType) -> Void)?)
}

extension CustomAlertRouterProtocol {
    
    func showChooserView(completion: ((HereafterMovieType) -> Void)?) {
        let typeChooserView = TypeChooserView(completion: completion)
        typeChooserView.outputAction = completion
        guard let alert = CustomAlertBuilder.build(with: typeChooserView) else {
            return
        }
        alert.transitioningDelegate = alert as? UIViewControllerTransitioningDelegate
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        windowScene?.windows.filter { $0.isKeyWindow }.first?.rootViewController?.topmostPresenter.present(alert, animated: true, completion: nil)
    }
}
