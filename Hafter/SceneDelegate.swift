//
//  SceneDelegate.swift
//  Hafter
//
//  Created by Artur Olar on 28.03.2022.
//

import UIKit
import FirebaseCore

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private(set) var router: AppRouter?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        FirebaseApp.configure()
        
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.overrideUserInterfaceStyle = .light
            router = AppRouter(window: window)
            router?.run()
            
            self.window = window
            self.window?.makeKeyAndVisible()
        }
    }

//  MARK: Private
    private func configureFirebase() {
        // FirebaseApp.configure()
    }
}

