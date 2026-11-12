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
    func getTags(movieId: String) -> [String]
    func updateTags(movieId: String, tags: [String], completion: @escaping (Bool) -> Void)
}

final class LocalService {
    
    private let provider: LocalDataProviderProtocol

    init(provider: LocalDataProviderProtocol) {
        self.provider = provider
    }
}

extension LocalService: LocalServiceProtocol {

    func save(movie: HereafterMovie, completion: @escaping (Bool) -> Void) {
        provider.save(movie: movie, completion: completion)
    }

    func getMovies(type: HereafterMovieType?) -> [HereafterMovie] {
        provider.getMovies(type: type)
    }

    func update(movie: HereafterMovie, completion: @escaping (Bool) -> Void) {
        provider.update(movie: movie, completion: completion)
    }

    func getTags(movieId: String) -> [String] {
        provider.getTags(movieId: movieId)
    }

    func updateTags(movieId: String, tags: [String], completion: @escaping (Bool) -> Void) {
        provider.updateTags(movieId: movieId, tags: tags, completion: completion)
    }
}
