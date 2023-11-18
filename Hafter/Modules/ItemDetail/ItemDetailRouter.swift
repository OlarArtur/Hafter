//
//  ItemDetailRouter.swift
//  Hafter
//
//  Created by Artur Olar on 16.11.2023.
//

import Foundation

protocol ItemDetailOutputProtocol: AnyObject {
    
}

protocol ItemDetailRouterProtocol: RouterProtocol {
    
}

final class ItemDetailRouter: BaseRouter {
    weak var output: ItemDetailOutputProtocol?
}

extension ItemDetailRouter: ItemDetailRouterProtocol {
    
}
