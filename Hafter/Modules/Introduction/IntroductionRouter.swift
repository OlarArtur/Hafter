//
//  IntroductionRouter.swift
//  Hafter
//
//  Created by Artur Olar on 29.03.2022.
//

import Foundation

protocol IntroductionRouterProtocol: RouterProtocol {
    func getStarted()
}

final class IntroductionRouter: BaseRouter {
    weak var output: IntroductionOutputProtocol?
}

extension IntroductionRouter: IntroductionRouterProtocol {

    func getStarted() {
        output?.introductionFinished()
    }
}
