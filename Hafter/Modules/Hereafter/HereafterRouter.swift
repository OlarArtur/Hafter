//
//  HereafterRouter.swift
//  Hafter
//
//  Created by Artur Olar on 29.03.2022.
//

import Foundation

protocol HereafterOutputProtocol: AnyObject {
    func add()
}

protocol HereafterRouterProtocol: RouterProtocol {
    func start()
    func add()
}

final class HereafterRouter: BaseRouter {
    weak var output: HereafterOutputProtocol?
}

extension HereafterRouter: HereafterRouterProtocol {
    
    func start() {
        
    }
    
    func add() {
        output?.add()
    }
}
