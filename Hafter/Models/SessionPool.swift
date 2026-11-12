//
//  SessionPool.swift
//  Hafter
//
//  Merges each participant's shelf into one session catalog.
//

import Foundation

enum SessionPool {

    struct Incoming: Equatable {
        var id: String
        var title: String
        var posterPath: String?
        var year: String?
    }

    /// Keeps the existing order. A movie already in the pool gains `uid` once.
    /// New movies are appended with that person as the only contributor.
    static func merge(_ movies: [SessionMovie], incoming: [Incoming], uid: String) -> [SessionMovie] {
        guard uid.isEmpty == false else { return movies }
        var result = movies
        for item in incoming {
            guard item.id.isEmpty == false else { continue }
            if let index = result.firstIndex(where: { $0.id == item.id }) {
                if result[index].contributors.contains(uid) == false {
                    result[index].contributors.append(uid)
                }
            } else {
                result.append(SessionMovie(
                    id: item.id,
                    title: item.title,
                    posterPath: item.posterPath,
                    year: item.year,
                    contributors: [uid]
                ))
            }
        }
        return result
    }

    static func sharedMovies(_ movies: [SessionMovie]) -> [SessionMovie] {
        movies.filter { $0.isShared }
    }

    static func everyoneHasContributed(participants: [String], contributions: [String: String]) -> Bool {
        guard participants.isEmpty == false else { return false }
        return participants.allSatisfy { contributions[$0]?.isEmpty == false }
    }
}
