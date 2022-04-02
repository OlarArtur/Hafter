//
//  AddRouter.swift
//  Hafter
//
//  Created by Artur Olar on 01.04.2022.
//

import Foundation
import UIKit

protocol AddOutputProtocol: AnyObject {
    func added(movie: Movie, controller: UIViewController)
}

protocol AddRouterProtocol: RouterProtocol {
    func add(movie: Movie, controller: UIViewController)
}

final class AddRouter: BaseRouter {
    weak var output: AddOutputProtocol?
}

extension AddRouter: AddRouterProtocol {
    
    func add(movie: Movie, controller: UIViewController) {
        output?.added(movie: movie, controller: controller)
    }
}
