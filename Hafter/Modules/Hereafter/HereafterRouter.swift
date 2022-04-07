//
//  HereafterRouter.swift
//  Hafter
//
//  Created by Artur Olar on 29.03.2022.
//

import Foundation

protocol HereafterOutputProtocol: AnyObject {
    func add()
    func openMenu()
}

protocol HereafterRouterProtocol: RouterProtocol {
    func add()
    func openMenu()
}

final class HereafterRouter: BaseRouter {
    weak var output: HereafterOutputProtocol?
}

extension HereafterRouter: HereafterRouterProtocol {
    
    func add() {
        output?.add()
    }
    
    func openMenu() {
        output?.openMenu()
    }
}
