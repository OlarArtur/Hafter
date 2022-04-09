//
//  ListBuilder.swift
//  Hafter
//
//  Created by Artur Olar on 07.04.2022.
//

import UIKit

final class ListBuilder {
    
    static func build(type: HereafterMovieType, output: ListOutputProtocol?, localDataService: LocalServiceProtocol, admissibleTypes: [HereafterMovieType]) -> UIViewController? {
        let addStoryboard = UIStoryboard(name: "List", bundle: nil)
        if let listVC = addStoryboard.instantiateInitialViewController() as? ListViewController {
            let router = ListRouter(presenter: listVC)
            router.output = output
           
            let viewModel = ListViewModel(router: router, localDataService: localDataService, type: type, admissibleTypes: admissibleTypes)
            listVC.viewModel = viewModel
            return listVC
        }
        return nil
    }
}
