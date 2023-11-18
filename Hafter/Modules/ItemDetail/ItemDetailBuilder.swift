//
//  ItemDetailBuilder.swift
//  Hafter
//
//  Created by Artur Olar on 16.11.2023.
//

import UIKit

final class ItemDetailBuilder {
    
    static func build(movie: DetailedMovie, type: HereafterMovieType, output: ItemDetailOutputProtocol? = nil, localDataService: LocalServiceProtocol) -> UIViewController? {
        let storyboard = UIStoryboard(name: "ItemDetail", bundle: nil)
        if let vc = storyboard.instantiateInitialViewController() as? ItemDetailViewController {
            let router = ItemDetailRouter(presenter: vc)
            router.output = output
           
            let viewModel = ItemDetailViewModel(movie: movie, type: type, router: router, localDataService: localDataService)
            vc.viewModel = viewModel
            vc.modalPresentationStyle = .fullScreen
            return vc
        }
        return nil
    }
}
