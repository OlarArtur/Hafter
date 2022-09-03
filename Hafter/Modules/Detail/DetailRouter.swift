//
//  DetailRouter.swift
//  Hafter
//
//  Created by Artur Olar on 03.09.2022.
//

import Foundation

protocol DetailOutputProtocol: AnyObject {

}

protocol DetailRouterProtocol: RouterProtocol {

}

final class DetailRouter: BaseRouter {
    weak var output: DetailOutputProtocol?
}

extension DetailRouter: DetailRouterProtocol {
    
}
