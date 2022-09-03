//
//  DetailViewModel.swift
//  Hafter
//
//  Created by Artur Olar on 03.09.2022.
//

import Foundation
import UIKit

protocol DetailViewModelProtocol {
    
    func getMovie() -> DetailedMovie
}

final class DetailViewModel<Router: DetailRouterProtocol>: BaseViewModel<Router> {
    
    weak var viewProtocol: DetailViewProtocol?
    private let movie: DetailedMovie
    
    init(router: Router, movie: DetailedMovie) {
        self.movie = movie
        super.init(router: router)
    }
}

extension DetailViewModel: DetailViewModelProtocol {
    
    func getMovie() -> DetailedMovie {
        return movie
    }
}
