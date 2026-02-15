//
//  RandomizeBuild.swift
//  Hafter
//
//  Created by Artur Olar on 09.04.2022.
//

import UIKit

final class RandomizeBuilder {
    
    static func build(output: RandomizeOutputProtocol?, movies: [HereafterMovie], imageLoader: ImageLoaderProtocol) -> UIViewController? {
        let randomizeVC = RandomizeViewController()
        let router = RandomizeRouter(presenter: randomizeVC)
        router.output = output

        let viewModel = RandomizeViewModel(router: router, movies: movies, imageLoader: imageLoader)
        randomizeVC.viewModel = viewModel
        randomizeVC.transitioningDelegate = randomizeVC
        return randomizeVC
    }
}
