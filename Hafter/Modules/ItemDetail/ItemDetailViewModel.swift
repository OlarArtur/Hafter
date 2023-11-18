//
//  ItemDetailViewModel.swift
//  Hafter
//
//  Created by Artur Olar on 16.11.2023.
//

import UIKit

protocol ItemDetailViewModelProtocol {
    var title: String { get }
    var overview: String { get }
    var budget: String { get }
    var genres: [String] { get }
    var color: UIColor { get }
    func getPoster(completion: @escaping (UIImage?) -> Void)
}

final class ItemDetailViewModel<Router: ItemDetailRouterProtocol>: BaseViewModel<Router> {
    
    private let localDataService: LocalServiceProtocol
    private let movie: DetailedMovie
    private let type: HereafterMovieType
    
    private let imageLoader = ImageLoader()
    
    init(movie: DetailedMovie, type: HereafterMovieType, router: Router, localDataService: LocalServiceProtocol) {
        self.movie = movie
        self.type = type
        self.localDataService = localDataService
        super.init(router: router)
    }
}

extension ItemDetailViewModel: ItemDetailViewModelProtocol {
    
    var color: UIColor {
        return type.typeColor
    }
    
    var title: String {
        guard let year = movie.year() else {
            return movie.originalTitle
        }
        return movie.originalTitle + " (\(year))"
    }
    
    var overview: String {
        return movie.overview
    }
    
    var budget: String {
        return NumberFormatter.localizedString(from: NSNumber(value: movie.budget), number: .decimal)
    }
    
    var genres: [String] {
        return movie.genres.map { $0.name }
    }
    
    func getPoster(completion: @escaping (UIImage?) -> Void) {
        if let posterURL = movie.posterOriginalImageURL() {
            imageLoader.imageFromUrl(url: posterURL) { image in
                completion(image)
            }
        } else {
            completion(nil)
        }
    }
}
