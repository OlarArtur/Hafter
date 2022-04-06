//
//  AddViewModel.swift
//  Hafter
//
//  Created by Artur Olar on 01.04.2022.
//

import UIKit
import Combine

protocol AddViewModelProtocol {
    
    var reloadData: (() -> Void)? { get set }
    var showError: ((Error) -> Void)? { get set }
    var updateTitle: ((String?) -> Void)? { get set }
    
    func numberOfItems() -> Int
    func itemFor(index: Int) -> String
    func select(index: Int)
    
    func updateSelectedType(type: HereafterMovieType)
    func clear()
    func search(query: String)
    func add(controller: UIViewController)
}

final class AddViewModel<Router: AddRouterProtocol>: BaseViewModel<Router> {
    
    deinit {
        cancelable?.cancel()
    }
    
    var reloadData: (() -> Void)?
    var showError: ((Error) -> Void)?
    var updateTitle: ((String?) -> Void)?
    
    private var cancelable: AnyCancellable?
    private let networkService: MediaServiceProtocol
    
    private var currentTitle: String = ""
    
    private var selectedType: HereafterMovieType = .foremost
    private var selectedMovie: Movie? {
        didSet {
            guard let selectedMovie = selectedMovie else {
                updateTitle?(nil)
                return
            }
            updateTitle?(createTitle(movie: selectedMovie))
        }
    }
    
    private var movies: [Movie] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.reloadData?()
            }
        }
    }
    
    init(router: Router, networkService: MediaServiceProtocol) {
        self.networkService = networkService
        super.init(router: router)
    }
}

extension AddViewModel: AddViewModelProtocol {
    
    func add(controller: UIViewController) {
        let emptyMovie = Movie(title: currentTitle)
        let hereafterMovie = HereafterMovie(type: selectedType, movie: selectedMovie ?? emptyMovie)
        router?.add(movie: hereafterMovie, controller: controller)
    }
    
    func clear() {
        selectedMovie = nil
    }
    
    func numberOfItems() -> Int {
        return movies.count
    }
    
    func itemFor(index: Int) -> String {
        return createTitle(movie: movies[index])
    }
    
    func select(index: Int) {
        selectedMovie = movies[index]
    }
    
    func search(query: String) {
        
        cancelable = networkService.search(query: query)
            .sink(receiveCompletion: { [weak self] (completion) in
                switch completion {
                case .failure(let error):
                    print(error)
                    DispatchQueue.main.async {
                        self?.showError?(error)
                    }
                case .finished:
                    print("Success")
                }
            }) { [weak self] (value) in
                guard let moviesResult = value?.results else {
                    return
                }
                self?.movies = moviesResult
            }
    }
    
    func updateSelectedType(type: HereafterMovieType) {
        selectedType = type
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
