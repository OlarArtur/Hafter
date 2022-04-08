//
//  ListViewModel.swift
//  Hafter
//
//  Created by Artur Olar on 07.04.2022.
//

import UIKit

protocol ListViewModelProtocol {
    var showError: ((Error) -> Void)? { get set }
    var reloadData: (() -> Void)? { get set }
    
    func numberOfItems() -> Int
    func itemFor(index: Int) -> Movie
    
    func start()
}

final class ListViewModel<Router: ListRouterProtocol>: BaseViewModel<Router> {

    var reloadData: (() -> Void)?
    var showError: ((Error) -> Void)?
    
    private let localDataService: LocalServiceProtocol
    
    private let type: HereafterMovieType
    private var movies: [HereafterMovie] = []
    
    init(router: Router, localDataService: LocalServiceProtocol, type: HereafterMovieType) {
        self.localDataService = localDataService
        self.type = type
        super.init(router: router)
    }
}

extension ListViewModel: ListViewModelProtocol {
    
    func start() {
        movies = localDataService.getMovies(type: type)
    }
    
    func numberOfItems() -> Int {
        return movies.count
    }
    
    func itemFor(index: Int) -> Movie {
        return movies[index].movie
    }
}

private extension AddViewModel {
    
    func createTitle(movie: Movie) -> String {
        var title = movie.title
        if let date = movie.releaseDate {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year], from: date)
            if let year = components.year {
                title.append("(\(year))")
            }
        }
        return title
    }
}
