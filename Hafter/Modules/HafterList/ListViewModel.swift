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
    var listTitle: String { get }

    func numberOfItems() -> Int
    func itemFor(index: Int) -> Movie
    func swipeLeftTypes() -> [HereafterMovieType]
    func swipeRightTypes() -> [HereafterMovieType]

    func updateType(index: Int, type: HereafterMovieType)
    func viewedCaption(index: Int) -> String?
    var onNeedsViewedDetails: ((@escaping (Int, Date) -> Void) -> Void)? { get set }
    func start()
}

final class ListViewModel<Router: ListRouterProtocol>: BaseViewModel<Router> {

    var reloadData: (() -> Void)?
    var showError: ((Error) -> Void)?
    
    private let localDataService: LocalServiceProtocol
    
    private let type: HereafterMovieType
    private var movies: [HereafterMovie] = []
    private let admissibleTypes: [HereafterMovieType]
    var onNeedsViewedDetails: ((@escaping (Int, Date) -> Void) -> Void)?
    
    init(router: Router, localDataService: LocalServiceProtocol, type: HereafterMovieType, admissibleTypes: [HereafterMovieType]) {
        self.localDataService = localDataService
        self.type = type
        self.admissibleTypes = admissibleTypes
        super.init(router: router)
    }
}

extension ListViewModel: ListViewModelProtocol {
    
    var backgrounColor: UIColor { type.typeColor }

    var listTitle: String { type.title }
    
    func start() {
        movies = localDataService.getMovies(type: type)
        if type == .viewed {
            let ranked = ViewedShelf.sorted(movies.map {
                ViewedShelf.Item(id: $0.movie.id, watchedDate: $0.watchedDate, rating: $0.rating)
            })
            let index = Dictionary(uniqueKeysWithValues: ranked.enumerated().map { ($1.id, $0) })
            movies.sort { (index[$0.movie.id] ?? 0) < (index[$1.movie.id] ?? 0) }
        }
    }

    func updateType(index: Int, type: HereafterMovieType) {
        let movie = movies[index]
        let save = { [weak self] in
            guard let self else { return }
            self.router?.update(movie: movie) { success in
                if success {
                    self.movies.remove(at: index)
                    self.reloadData?()
                } else {
                    self.showError?(ServiceError.localDataError)
                }
            }
        }
        guard type == .viewed else {
            movie.type = type
            movie.rating = nil
            movie.watchedDate = nil
            save()
            return
        }
        let finish: (Int, Date) -> Void = { rating, date in
            movie.type = .viewed
            movie.rating = ViewedShelf.clampRating(rating)
            movie.watchedDate = date
            save()
        }
        if let ask = onNeedsViewedDetails {
            ask(finish)
        } else {
            finish(5, Date())
        }
    }

    func viewedCaption(index: Int) -> String? {
        let movie = movies[index]
        guard movie.type == .viewed else { return nil }
        return ViewedShelf.caption(rating: movie.rating, date: movie.watchedDate)
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
