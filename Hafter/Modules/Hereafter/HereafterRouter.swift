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
    func openViewed()
    func openList(type: HereafterMovieType)
}

protocol HereafterRouterProtocol: RouterProtocol {
    func add()
    func openMenu()
    func openViewed()
    func openList(type: HereafterMovieType)
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
    
    func openViewed() {
        output?.openViewed()
    }
    
    func openList(type: HereafterMovieType) {
        output?.openList(type: type)
    }
}
