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
    func hasMovie(id: String) -> Bool
    func ensureOnShelf(_ movie: SessionMovie, type: HereafterMovieType)
    func moveToViewed(id: String, completion: @escaping (Bool) -> Void)
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

    func hasMovie(id: String) -> Bool {
        getMovies(type: nil).contains { $0.movie.id == id }
    }

    func ensureOnShelf(_ movie: SessionMovie, type: HereafterMovieType) {
        guard hasMovie(id: movie.id) == false else { return }
        let item = Movie(
            id: movie.id,
            adult: false,
            backdropPath: nil,
            originalLanguage: "",
            title: movie.title,
            originalTitle: movie.title,
            overview: "",
            popularity: 0,
            posterPath: movie.posterPath,
            releaseDate: nil
        )
        save(movie: HereafterMovie(type: type, movie: item), completion: { _ in })
    }

    func moveToViewed(id: String, completion: @escaping (Bool) -> Void) {
        guard let existing = getMovies(type: nil).first(where: { $0.movie.id == id }) else {
            completion(false)
            return
        }
        existing.type = .viewed
        update(movie: existing, completion: completion)
    }
}

enum TonightSync {
    static func remember(session: MovieSession, local: LocalServiceProtocol) {
        guard session.status == .done,
              let resultID = session.result,
              let movie = session.movies.first(where: { $0.id == resultID }) else { return }
        if local.hasMovie(id: movie.id) == false {
            local.ensureOnShelf(movie, type: .foremost)
        }
        WidgetDataBridge.writeTonight(WidgetDataBridge.TonightEntry(
            sessionID: session.id,
            movieID: movie.id,
            title: movie.title,
            year: movie.year
        ))
    }

    static func markWatched(session: MovieSession, uid: String?, local: LocalServiceProtocol) {
        guard let resultID = session.result else { return }
        local.moveToViewed(id: resultID) { saved in
            if saved == false, let movie = session.movies.first(where: { $0.id == resultID }) {
                local.ensureOnShelf(movie, type: .viewed)
            }
        }
        WidgetDataBridge.writeTonight(nil)
        if let uid {
            FirestoreService.shared.markWatched(sessionID: session.id, uid: uid) { _ in }
        }
    }
}
