//
//  HereafterMainViewModel.swift
//  Hafter
//
//  Created by Artur Olar on 15.11.2023.
//

import Foundation

protocol HereafterViewModelProtocol {
    var selectedType: HereafterMovieType { get }
    func randomize()
    func add()
    func openMenu()
    func openViewed()
    func updateType(index: Int, type: HereafterMovieType)
    
    func select(type: HereafterMovieType, rect: CGRect)
    
    func numberOfItems() -> Int
    func itemFor(index: Int) -> Movie
    func swipeLeftTypes() -> [HereafterMovieType]
    func swipeRightTypes() -> [HereafterMovieType]
}

final class HereafterMainViewModel<Router: HereafterRouterProtocol>: BaseViewModel<Router> {
    
    weak var viewProtocol: HereafterViewProtocol?
    
    private let localDataService: LocalServiceProtocol
    private let type: HereafterMovieType = .foremost
    private var movies: [HereafterMovie] = []
    private let admissibleTypes: [HereafterMovieType] = HereafterMovieType.allCases
    
    private(set) var selectedType: HereafterMovieType = .foremost {
        didSet {
            loadMovies()
        }
    }
    
    init(router: Router, localDataService: LocalServiceProtocol) {
        self.localDataService = localDataService
        super.init(router: router)
    }
    
    func loadMovies() {
        movies = localDataService.getMovies(type: selectedType)
        viewProtocol?.reloadData()
    }
}

extension HereafterMainViewModel: HereafterViewModelProtocol {
    
    
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
    
    func select(type: HereafterMovieType, rect: CGRect) {
        selectedType = type
    }
    
    func randomize() {
        router?.randomize()
    }
    
    func add() {
        router?.add { [weak self] in
            guard let self = self else { return }
            self.movies = self.localDataService.getMovies(type: self.selectedType)
            self.viewProtocol?.reloadData()
        }
    }
    
    func openMenu() {
        router?.openMenu()
    }
    
    func openViewed() {
        router?.openViewed()
    }
    
    func updateType(index: Int, type: HereafterMovieType) {
        let viewedMoview = movies[index]
        viewedMoview.type = type
        router?.update(movie: viewedMoview) { [weak self] success in
            if success {
                self?.movies.remove(at: index)
                self?.viewProtocol?.reloadData()
            } else {
                self?.viewProtocol?.showError(error: ServiceError.localDataError)
            }
        }
    }
}
