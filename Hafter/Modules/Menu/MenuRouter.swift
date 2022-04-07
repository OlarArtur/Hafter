//
//  MenuRouter.swift
//  Hafter
//
//  Created by Artur Olar on 06.04.2022.
//

import UIKit

protocol MenuOutputProtocol: AnyObject {
    
}

protocol MenuRouterProtocol: RouterProtocol {
    
}

final class MenuRouter: BaseRouter {
    weak var output: MenuOutputProtocol?
}

extension MenuRouter: MenuRouterProtocol {
    
}

