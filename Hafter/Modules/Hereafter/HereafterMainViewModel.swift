//
//  HereafterMainViewModel.swift
//  Hafter
//
//  Created by Artur Olar on 15.11.2023.
//

import Foundation
import Combine

enum MovieSortOrder: CaseIterable {
    case alphabetical
    case yearNewest
    case popularity

    var title: String {
        switch self {
        case .alphabetical: return "Title A–Z"
        case .yearNewest:   return "Year: newest first"
        case .popularity:   return "Most popular"
        }
    }

    var systemImage: String {
        switch self {
        case .alphabetical: return "textformat.abc"
        case .yearNewest:   return "calendar"
        case .popularity:   return "star"
        }
    }
}

protocol HereafterViewModelProtocol {
    var selectedType: HereafterMovieType { get }
    var sortOrder: MovieSortOrder { get }
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

    func didSelect(index: Int)
    func applySearch(query: String)
    func applySort(order: MovieSortOrder)
    func reloadLists()
}

final class HereafterMainViewModel<Router: HereafterRouterProtocol>: BaseViewModel<Router> {

    deinit {
        cancelable?.cancel()
    }

    weak var viewProtocol: HereafterViewProtocol?
    private let networkService: MediaServiceProtocol
    private var cancelable: AnyCancellable?

    private let localDataService: LocalServiceProtocol
    private var allMovies: [HereafterMovie] = []
    private var filteredMovies: [HereafterMovie] = []
    private var searchQuery: String = ""
    private let admissibleTypes: [HereafterMovieType] = HereafterMovieType.allCases

    private(set) var selectedType: HereafterMovieType = .foremost {
        didSet { loadMovies() }
    }

    private(set) var sortOrder: MovieSortOrder = .alphabetical

    init(router: Router, localDataService: LocalServiceProtocol, networkService: MediaServiceProtocol) {
        self.networkService = networkService
        self.localDataService = localDataService
        super.init(router: router)
    }

    func loadMovies() {
        allMovies = localDataService.getMovies(type: selectedType)
        // Always keep the widget in sync regardless of which tab is active
        let foremostMovies = selectedType == .foremost
            ? allMovies
            : localDataService.getMovies(type: .foremost)
        WidgetDataBridge.write(movies: foremostMovies)
        recomputeFiltered()
    }

    private func recomputeFiltered() {
        var result = allMovies
        if !searchQuery.isEmpty {
            result = result.filter {
                $0.movie.title.localizedCaseInsensitiveContains(searchQuery) ||
                $0.movie.originalTitle.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        switch sortOrder {
        case .alphabetical:
            result.sort { $0.movie.title.localizedCompare($1.movie.title) == .orderedAscending }
        case .yearNewest:
            result.sort { ($0.movie.releaseDate ?? .distantPast) > ($1.movie.releaseDate ?? .distantPast) }
        case .popularity:
            result.sort { $0.movie.popularity > $1.movie.popularity }
        }
        filteredMovies = result
        viewProtocol?.reloadData()
    }
}

extension HereafterMainViewModel: HereafterViewModelProtocol {

    func didSelect(index: Int) {
        cancelable = networkService.detailFor(id: filteredMovies[index].movie.id)
            .sink(receiveCompletion: { [weak self] (completion) in
                switch completion {
                case .failure(let error):
                    print(error)
                    DispatchQueue.main.async {
                        self?.viewProtocol?.showError(error: error)
                    }
                case .finished:
                    print("Success")
                }
            }, receiveValue: { [weak self] (value) in
                guard let movie = value, let self else { return }
                DispatchQueue.main.async {
                    self.router?.selected(movie, type: self.selectedType)
                }
            })
    }

    func numberOfItems() -> Int {
        return filteredMovies.count
    }

    func itemFor(index: Int) -> Movie {
        return filteredMovies[index].movie
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
            guard let self else { return }
            self.loadMovies()
        }
    }

    func openMenu() {
        router?.openMenu()
    }

    func openViewed() {
        router?.openViewed()
    }

    func updateType(index: Int, type: HereafterMovieType) {
        let movie = filteredMovies[index]
        movie.type = type
        router?.update(movie: movie) { [weak self] success in
            if success {
                self?.loadMovies()
            } else {
                self?.viewProtocol?.showError(error: ServiceError.localDataError)
            }
        }
    }

    func applySearch(query: String) {
        searchQuery = query
        recomputeFiltered()
    }

    func applySort(order: MovieSortOrder) {
        sortOrder = order
        recomputeFiltered()
    }

    func reloadLists() {
        loadMovies()
    }
}
