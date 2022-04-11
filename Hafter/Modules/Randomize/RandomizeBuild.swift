//
//  RandomizeBuild.swift
//  Hafter
//
//  Created by Artur Olar on 09.04.2022.
//

import UIKit

final class RandomizeBuilder {
    
    static func build(output: RandomizeOutputProtocol?, movies: [HereafterMovie], imageLoader: ImageLoaderProtocol) -> UIViewController? {
        let randomizeStoryboard = UIStoryboard(name: "Randomize", bundle: nil)
        if let randomizeVC = randomizeStoryboard.instantiateInitialViewController() as? RandomizeViewController {
            let router = RandomizeRouter(presenter: randomizeVC)
            router.output = output
           
            let viewModel = RandomizeViewModel(router: router, movies: movies, imageLoader: imageLoader)
            randomizeVC.viewModel = viewModel
            randomizeVC.transitioningDelegate = randomizeVC
            return randomizeVC
        }
        return nil
    }
}
