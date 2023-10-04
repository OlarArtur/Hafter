//
//  HereafterRouter.swift
//  Hafter
//
//  Created by Artur Olar on 29.03.2022.
//

import Foundation

protocol HereafterOutputProtocol: AnyObject {
    func randomize()
    func add(completion: @escaping () -> Void)
    func openMenu()
    func openViewed()
    func openList(type: HereafterMovieType, rect: CGRect)
    func update(movie: HereafterMovie, completion: @escaping (Bool) -> Void)
}

protocol HereafterRouterProtocol: RouterProtocol {
    func randomize()
    func add(completion: @escaping () -> Void)
    func openMenu()
    func openViewed()
    func openList(type: HereafterMovieType, rect: CGRect)
    func update(movie: HereafterMovie, completion: @escaping (Bool) -> Void)
}

final class HereafterRouter: BaseRouter {
    weak var output: HereafterOutputProtocol?
}

extension HereafterRouter: HereafterRouterProtocol {
    
    func randomize() {
        output?.randomize()
    }
    
    func add(completion: @escaping () -> Void) {
        output?.add(completion: completion)
    }
    
    func openMenu() {
        output?.openMenu()
    }
    
    func openViewed() {
        output?.openViewed()
    }
    
    func openList(type: HereafterMovieType, rect: CGRect) {
        output?.openList(type: type, rect: rect)
    }
    
    func update(movie: HereafterMovie, completion: @escaping (Bool) -> Void) {
        output?.update(movie: movie, completion: completion)
    }
}
