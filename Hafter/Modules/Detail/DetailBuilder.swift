//
//  DetailBuilder.swift
//  Hafter
//
//  Created by Artur Olar on 03.09.2022.
//

import UIKit

final class DetailBuilder {
    
    static func build(movie: DetailedMovie, output: DetailOutputProtocol?) -> UIViewController? {
        let detailStoryboard = UIStoryboard(name: "Detail", bundle: nil)
        if let detailVC = detailStoryboard.instantiateInitialViewController() as? DetailViewController {
            let router = DetailRouter(presenter: detailVC)
            router.output = output
            let viewModel = DetailViewModel(router: router, movie: movie)
            viewModel.viewProtocol = detailVC
            detailVC.viewModel = viewModel
            return detailVC
        }
        return nil
    }
}
