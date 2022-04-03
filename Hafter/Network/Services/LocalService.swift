//
//  LocalService.swift
//  Hafter
//
//  Created by Artur Olar on 02.04.2022.
//

import Foundation

protocol LocalServiceProtocol {
    func save(movie: HereafterMovie)
    func getMovies() -> [HereafterMovie]
}

final class LocalService {
    
    private let provider: LocalDataProviderProtocol

    init(provider: LocalDataProviderProtocol) {
        self.provider = provider
    }
}

extension LocalService: LocalServiceProtocol {
    
    func save(movie: HereafterMovie) {
        return provider.save(movie: movie)
    }
    
    func getMovies() -> [HereafterMovie] {
        return provider.getMovies()
    }
}
