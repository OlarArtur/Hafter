//
//  LocalService.swift
//  Hafter
//
//  Created by Artur Olar on 02.04.2022.
//

import Foundation

protocol LocalServiceProtocol {
    func update(movie: HereafterMovie, completion: @escaping (Bool) -> Void)
    func save(movie: HereafterMovie, completion: @escaping (Bool) -> Void)
    func getMovies(type: HereafterMovieType?) -> [HereafterMovie]
}

final class LocalService {
    
    private let provider: LocalDataProviderProtocol

    init(provider: LocalDataProviderProtocol) {
        self.provider = provider
    }
}

extension LocalService: LocalServiceProtocol {
    
    func save(movie: HereafterMovie, completion: @escaping (Bool) -> Void) {
        return provider.save(movie: movie, completion: completion)
    }
    
    func getMovies(type: HereafterMovieType?) -> [HereafterMovie] {
        return provider.getMovies(type: type)
    }
    
    func update(movie: HereafterMovie, completion: @escaping (Bool) -> Void) {
        provider.update(movie: movie, completion: completion)
    }
}
