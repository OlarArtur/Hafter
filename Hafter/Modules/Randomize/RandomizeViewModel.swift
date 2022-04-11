//
//  RandomizeViewModel.swift
//  Hafter
//
//  Created by Artur Olar on 09.04.2022.
//

import UIKit

protocol RandomizeViewModelProtocol {
    var reload: (() -> Void)? { get set }
    
    func getMovie() -> Movie?
    func getPoster(completion: @escaping (UIImage?) -> Void)
    func switchTo(type: HereafterMovieType?)
}

final class RandomizeViewModel<Router: RandomizeRouterProtocol>: BaseViewModel<Router> {
    
    private let movies: [HereafterMovie]
    private let imageLoader: ImageLoaderProtocol
    private var randomizedMovie: Movie?
    
    var reload: (() -> Void)?
    
    private var type: HereafterMovieType? {
        didSet {
            reload?()
        }
    }
    
    init(router: Router, movies: [HereafterMovie], imageLoader: ImageLoaderProtocol) {
        self.movies = movies
        self.imageLoader = imageLoader
        super.init(router: router)
    }
}

extension RandomizeViewModel: RandomizeViewModelProtocol {
    
    func getMovie() -> Movie? {
        let movie: Movie?
        if let type = type {
            let moviesFiltered = movies.filter { $0.type == type }
            movie = moviesFiltered.randomElement()?.movie
        } else {
            movie = movies.randomElement()?.movie
        }
        randomizedMovie = movie
        return movie
    }
    
    func getPoster(completion: @escaping (UIImage?) -> Void) {
        if let posterURL = randomizedMovie?.posterImageURL() {
            imageLoader.imageFromUrl(url: posterURL) { image in
                completion(image ?? UIImage.image(named: ImageConstants.posterholder))
            }
        } else {
            completion(UIImage.image(named: ImageConstants.posterholder))
        }
    }
    
    func switchTo(type: HereafterMovieType?) {
        self.type = type
    }
}

private extension RandomizeViewModel {
    
}
