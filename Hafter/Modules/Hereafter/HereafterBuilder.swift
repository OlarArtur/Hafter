//
//  HereafterBuilder.swift
//  Hafter
//
//  Created by Artur Olar on 29.03.2022.
//

import UIKit

final class HereafterBuilder {
    
    static func build(localDataService: LocalServiceProtocol, output: HereafterOutputProtocol?) -> UIViewController? {
        let hereafterStoryboard = UIStoryboard(name: "HereAfterMain", bundle: nil)
        if let hereafterVC = hereafterStoryboard.instantiateInitialViewController() as? HereAfterMainViewController {
            let router = HereafterRouter(presenter: hereafterVC)
            router.output = output
            let viewModel = HereafterMainViewModel(router: router, localDataService: localDataService)
            viewModel.viewProtocol = hereafterVC
            hereafterVC.viewModel = viewModel
            return hereafterVC
        }
        return nil
    }
}
