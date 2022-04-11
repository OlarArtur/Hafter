//
//  HereafterViewModel.swift
//  Hafter
//
//  Created by Artur Olar on 29.03.2022.
//

import Foundation

protocol HereafterViewModelProtocol {
    func randomize()
    func add()
    func openMenu()
    func openViewed()
    func openList(type: HereafterMovieType)
}

final class HereafterViewModel<Router: HereafterRouterProtocol>: BaseViewModel<Router> {
    
    weak var viewProtocol: HereafterViewProtocol?
}

extension HereafterViewModel: HereafterViewModelProtocol {
    
    func randomize() {
        router?.randomize()
    }
    
    func add() {
        router?.add()
    }
    
    func openMenu() {
        router?.openMenu()
    }
    
    func openList(type: HereafterMovieType) {
        router?.openList(type: type)
    }
    
    func openViewed() {
        router?.openViewed()
    }
}
