//
//  AddRouter.swift
//  Hafter
//
//  Created by Artur Olar on 01.04.2022.
//

import UIKit

protocol AddOutputProtocol: AnyObject {
    func added(movie: HereafterMovie, controller: UIViewController)
}

protocol AddRouterProtocol: RouterProtocol {
    func add(movie: HereafterMovie, controller: UIViewController)
    func showDetail(movie: DetailedMovie)
}

final class AddRouter: BaseRouter {
    weak var output: AddOutputProtocol?
}

extension AddRouter: AddRouterProtocol {
    
    func add(movie: HereafterMovie, controller: UIViewController) {
        output?.added(movie: movie, controller: controller)
    }
    
    func showDetail(movie: DetailedMovie) {
        guard let detailVC = DetailBuilder.build(movie: movie, output: self) else {
            return
        }
        presenter?.present(detailVC, animated: true)
    }
}

extension AddRouter: DetailOutputProtocol {
    
}
