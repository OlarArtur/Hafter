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
}

final class ListViewModel<Router: ListRouterProtocol>: BaseViewModel<Router> {

    var reloadData: (() -> Void)?
    var showError: ((Error) -> Void)?
    
    private let localDataService: LocalServiceProtocol
    
    private var currentTitle: String = ""
    
    init(router: Router, localDataService: LocalServiceProtocol) {
        self.localDataService = localDataService
        super.init(router: router)
    }
}

extension ListViewModel: ListViewModelProtocol {
    
    
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
