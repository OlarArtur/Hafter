//
//  HereafterViewModel.swift
//  Hafter
//
//  Created by Artur Olar on 29.03.2022.
//

import Foundation

protocol HereafterViewModelProtocol {
    func add()
}

final class HereafterViewModel<Router: HereafterRouterProtocol>: BaseViewModel<Router> {
    
    weak var viewProtocol: HereafterViewProtocol?
}

extension HereafterViewModel: HereafterViewModelProtocol {
    
    func add() {
        router?.add()
    }
}
