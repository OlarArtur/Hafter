//
//  IntroductionBuilder.swift
//  Hafter
//
//  Created by Artur Olar on 29.03.2022.
//

import UIKit

protocol IntroductionOutputProtocol: AnyObject {
    func introductionFinished()
}

final class IntroductionBuilder {
    
    static func build(output: IntroductionOutputProtocol?) -> UIViewController? {
        let introductionStoryboard = UIStoryboard(name: "Introduction", bundle: nil)
        if let introductionVC = introductionStoryboard.instantiateInitialViewController() as? IntroductionViewController {
            let router = IntroductionRouter(presenter: introductionVC)
            router.output = output
            let viewModel = IntroductionViewModel(router: router)
            viewModel.viewProtocol = introductionVC
            introductionVC.viewModel = viewModel
            return introductionVC
        }
        return nil
    }
}
