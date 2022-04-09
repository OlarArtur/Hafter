//
//  ListRouter.swift
//  Hafter
//
//  Created by Artur Olar on 07.04.2022.
//

import UIKit

protocol ListOutputProtocol: AnyObject {
    func update(movie: HereafterMovie, completion: @escaping (Bool) -> Void)
}

protocol ListRouterProtocol: RouterProtocol {
    func update(movie: HereafterMovie, completion: @escaping (Bool) -> Void)
}

final class ListRouter: BaseRouter {
    weak var output: ListOutputProtocol?
}

extension ListRouter: ListRouterProtocol {
    
    func update(movie: HereafterMovie, completion: @escaping (Bool) -> Void) {
        output?.update(movie: movie, completion: completion)
    }
}
