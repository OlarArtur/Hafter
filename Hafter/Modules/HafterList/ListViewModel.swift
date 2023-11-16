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
    
    var backgrounColor: UIColor { get }
    
    func numberOfItems() -> Int
    func itemFor(index: Int) -> Movie
    func swipeLeftTypes() -> [HereafterMovieType]
    func swipeRightTypes() -> [HereafterMovieType]
    
    func updateType(index: Int, type: HereafterMovieType)
    func start()
}

final class ListViewModel<Router: ListRouterProtocol>: BaseViewModel<Router> {

    var reloadData: (() -> Void)?
    var showError: ((Error) -> Void)?
    
    private let localDataService: LocalServiceProtocol
    
    private let type: HereafterMovieType
    private var movies: [HereafterMovie] = []
    private let admissibleTypes: [HereafterMovieType]
    
    init(router: Router, localDataService: LocalServiceProtocol, type: HereafterMovieType, admissibleTypes: [HereafterMovieType]) {
        self.localDataService = localDataService
        self.type = type
        self.admissibleTypes = admissibleTypes
        super.init(router: router)
    }
}

extension ListViewModel: ListViewModelProtocol {
    
    var backgrounColor: UIColor {
        return type.typeColor
    }
    
    func start() {
        movies = localDataService.getMovies(type: type)
    }
    
    func updateType(index: Int, type: HereafterMovieType) {
        let viewedMoview = movies[index]
        viewedMoview.type = type
        router?.update(movie: viewedMoview) { [weak self] success in
            if success {
                self?.movies.remove(at: index)
                self?.reloadData?()
            } else {
                self?.showError?(ServiceError.localDataError)
            }
        }
    }
    
    func numberOfItems() -> Int {
        return movies.count
    }
    
    func itemFor(index: Int) -> Movie {
        return movies[index].movie
    }
    
    func swipeLeftTypes() -> [HereafterMovieType] {
        return admissibleTypes.filter { $0 != .viewed }
    }
    
    func swipeRightTypes() -> [HereafterMovieType] {
        return [.viewed]
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
