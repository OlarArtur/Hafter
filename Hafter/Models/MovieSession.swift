//
//  MovieSession.swift
//  Hafter
//

import Foundation

enum SessionMode: String, CaseIterable {
    case swipe
    case vote
    case random

    var title: String {
        switch self {
        case .swipe:  return "Swipe Yes/No"
        case .vote:   return "Vote"
        case .random: return "Random Pick"
        }
    }

    var systemImage: String {
        switch self {
        case .swipe:  return "hand.draw"
        case .vote:   return "checkmark.circle"
        case .random: return "dice"
        }
    }
}

enum SessionStatus: String {
    case pending
    case active
    case done
}

struct SessionMovie: Equatable {
    let id: String
    let title: String
    let posterPath: String?
    let year: String?

    var posterThumbnailURL: URL? {
        guard let posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w342" + posterPath)
    }

    var firestoreData: [String: Any] {
        var d: [String: Any] = ["id": id, "title": title]
        if let posterPath { d["posterPath"] = posterPath }
        if let year { d["year"] = year }
        return d
    }

    init(id: String, title: String, posterPath: String?, year: String?) {
        self.id = id
        self.title = title
        self.posterPath = posterPath
        self.year = year
    }

    init?(data: [String: Any]) {
        guard let id = data["id"] as? String,
              let title = data["title"] as? String else { return nil }
        self.id = id
        self.title = title
        self.posterPath = data["posterPath"] as? String
        self.year = data["year"] as? String
    }
}

struct MovieSession {
    let id: String
    let createdBy: String
    var participants: [String]
    var status: SessionStatus
    let mode: SessionMode
    let sourceList: String
    var movies: [SessionMovie]
    /// votes[uid][movieId] = "yes" | "no"
    var votes: [String: [String: String]]
    var result: String?
    let createdAt: Date

    init(id: String, createdBy: String, participants: [String], status: SessionStatus,
         mode: SessionMode, sourceList: String, movies: [SessionMovie],
         votes: [String: [String: String]] = [:], result: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.createdBy = createdBy
        self.participants = participants
        self.status = status
        self.mode = mode
        self.sourceList = sourceList
        self.movies = movies
        self.votes = votes
        self.result = result
        self.createdAt = createdAt
    }

    init?(id: String, data: [String: Any]) {
        guard let createdBy = data["createdBy"] as? String,
              let participants = data["participants"] as? [String],
              let statusRaw = data["status"] as? String,
              let status = SessionStatus(rawValue: statusRaw),
              let modeRaw = data["mode"] as? String,
              let mode = SessionMode(rawValue: modeRaw),
              let sourceList = data["sourceList"] as? String,
              let moviesData = data["movies"] as? [[String: Any]] else { return nil }

        self.id = id
        self.createdBy = createdBy
        self.participants = participants
        self.status = status
        self.mode = mode
        self.sourceList = sourceList
        self.movies = moviesData.compactMap { SessionMovie(data: $0) }
        self.votes = data["votes"] as? [String: [String: String]] ?? [:]
        self.result = data["result"] as? String
        self.createdAt = (data["createdAt"] as? Double).map { Date(timeIntervalSince1970: $0) } ?? Date()
    }

    var firestoreData: [String: Any] {
        var d: [String: Any] = [
            "createdBy": createdBy,
            "participants": participants,
            "status": status.rawValue,
            "mode": mode.rawValue,
            "sourceList": sourceList,
            "movies": movies.map { $0.firestoreData },
            "votes": votes,
            "createdAt": createdAt.timeIntervalSince1970
        ]
        if let result { d["result"] = result }
        return d
    }

    func votesForUser(_ uid: String) -> [String: String] {
        votes[uid] ?? [:]
    }

    /// True when the user has voted on every movie (used in Swipe mode).
    func hasUserFinishedVoting(_ uid: String) -> Bool {
        let userVotes = votesForUser(uid)
        return userVotes.count >= movies.count
    }

    /// True when the user has cast at least one vote (used in Vote mode — one pick per user).
    func hasUserVotedOnce(_ uid: String) -> Bool {
        !(votes[uid]?.isEmpty ?? true)
    }

    /// All participants finished swiping (Swipe mode).
    func allParticipantsFinished() -> Bool {
        participants.allSatisfy { hasUserFinishedVoting($0) }
    }

    /// All participants submitted their one pick (Vote mode).
    func allParticipantsVotedOnce() -> Bool {
        participants.allSatisfy { hasUserVotedOnce($0) }
    }

    /// Returns movies where ALL participants voted "yes"
    func matchingMovies() -> [SessionMovie] {
        movies.filter { movie in
            participants.allSatisfy { uid in votes[uid]?[movie.id] == "yes" }
        }
    }
}
