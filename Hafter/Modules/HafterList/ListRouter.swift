//
//  ListRouter.swift
//  Hafter
//
//  Created by Artur Olar on 07.04.2022.
//

import UIKit

protocol ListOutputProtocol: AnyObject {
    
}

protocol ListRouterProtocol: RouterProtocol {
    
}

final class ListRouter: BaseRouter {
    weak var output: ListOutputProtocol?
}

extension ListRouter: ListRouterProtocol {
    
}
