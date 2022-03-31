//
//  IntroductionViewModel.swift
//  Hafter
//
//  Created by Artur Olar on 29.03.2022.
//

import Foundation

protocol IntroductionViewModelProtocol {
    func getStarted()
}

final class IntroductionViewModel<Router: IntroductionRouterProtocol>: BaseViewModel<Router> {
    
    weak var viewProtocol: IntroductionViewProtocol?
    
}

extension IntroductionViewModel: IntroductionViewModelProtocol {
    
    func getStarted() {
        router?.getStarted()
    }
}
