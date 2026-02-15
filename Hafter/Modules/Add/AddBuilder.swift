//
//  AddBuilder.swift
//  Hafter
//
//  Created by Artur Olar on 01.04.2022.
//

import UIKit

final class AddBuilder {
    
    static func build(output: AddOutputProtocol?) -> UIViewController? {
        let addVC = AddViewController()
        let router = AddRouter(presenter: addVC)
        router.output = output

        let localProvider = LocalDataProvider()
        let networkProvider = TMDbNetworkDataProvider()
        let parser = MovieParser()
        let networkService = TMDbService(networkProvider: networkProvider, localProvider: localProvider, parser: parser)
        let viewModel = AddViewModel(router: router, networkService: networkService)
        addVC.viewModel = viewModel
        return addVC
    }
}
