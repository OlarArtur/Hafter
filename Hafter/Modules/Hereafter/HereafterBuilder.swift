//
//  HereafterBuilder.swift
//  Hafter
//
//  Created by Artur Olar on 29.03.2022.
//

import UIKit

final class HereafterBuilder {
    
    static func build(localDataService: LocalServiceProtocol, output: HereafterOutputProtocol?) -> UIViewController? {
        let hereafterVC = HereAfterMainViewController()
        let router = HereafterRouter(presenter: hereafterVC)
        router.output = output

        let localProvider = LocalDataProvider()
        let networkProvider = TMDbNetworkDataProvider()
        let parser = MovieParser()
        let networkService = TMDbService(networkProvider: networkProvider, localProvider: localProvider, parser: parser)
        let viewModel = HereafterMainViewModel(router: router, localDataService: localDataService, networkService: networkService)
        viewModel.viewProtocol = hereafterVC
        hereafterVC.viewModel = viewModel
        return hereafterVC
    }
}
