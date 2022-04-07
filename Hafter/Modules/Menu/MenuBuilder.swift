//
//  MenuBuilder.swift
//  Hafter
//
//  Created by Artur Olar on 06.04.2022.
//

import UIKit

final class MenuBuilder {
    
    static func build(output: MenuOutputProtocol?) -> UIViewController? {
        let menuStoryboard = UIStoryboard(name: "Menu", bundle: nil)
        if let menuVC = menuStoryboard.instantiateInitialViewController() as? MenuViewController {
            let router = MenuRouter(presenter: menuVC)
            router.output = output
            
            let viewModel = MenuViewModel(router: router)
            menuVC.viewModel = viewModel
            return menuVC
        }
        return nil
    }
}
