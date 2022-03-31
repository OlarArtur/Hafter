//
//  AppRouter.swift
//  Hafter
//
//  Created by Artur Olar on 29.03.2022.
//

import UIKit

final class AppRouter {
    
    private(set) var window: UIWindow
    private var baseNavigationController: UINavigationController?
    
    init(window: UIWindow) {
        self.window = window
    }
    
    func run() {
        start()
    }
    
    var rootViewController: UIViewController? {
        return window.rootViewController
    }
    
    internal func start() {
        let introductionFinished = Settings.shared.introductionFinished
        
        if introductionFinished {
            showMainStoryboard()
        } else {
            let introductionNavVC = IntroductionBuilder.build(output: self)
            window.rootViewController = introductionNavVC
            window.makeKeyAndVisible()
        }
    }
    
    func showMainStoryboard(animated: Bool = false) {
        let dummyView = UIViewController()
        window.rootViewController = dummyView
        window.makeKeyAndVisible()
        
        guard let hereafterViewController = HereafterBuilder.build(output: self) else { return }
        let navigationVC = NavigationControllerViewController(rootViewController: hereafterViewController)
        baseNavigationController = navigationVC
        window.setRootViewController(navigationVC, animated: animated, completion: nil)
    }
    
}

private extension AppRouter {
    
}

extension AppRouter: IntroductionOutputProtocol {
    
    func introductionFinished() {
        Settings.shared.introductionFinished = true
        showMainStoryboard()
    }
}

extension AppRouter: HereafterOutputProtocol {
    
}
