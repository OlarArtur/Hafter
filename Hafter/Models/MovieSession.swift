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
    /// Firebase uids whose chosen list includes this movie. More than one means it is shared.
    var contributors: [String]

    var isShared: Bool { contributors.count > 1 }

    var sharedLabel: String? {
        guard isShared else { return nil }
        return "On \(contributors.count) lists"
    }

    var posterThumbnailURL: URL? {
        guard let posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w342" + posterPath)
    }

    var firestoreData: [String: Any] {
        var d: [String: Any] = ["id": id, "title": title]
        if let posterPath { d["posterPath"] = posterPath }
        if let year { d["year"] = year }
        if contributors.isEmpty == false { d["contributors"] = contributors }
        return d
    }

    init(id: String, title: String, posterPath: String?, year: String?, contributors: [String] = []) {
        self.id = id
        self.title = title
        self.posterPath = posterPath
        self.year = year
        self.contributors = contributors
    }

    init?(data: [String: Any]) {
        guard let id = data["id"] as? String,
              let title = data["title"] as? String else { return nil }
        self.id = id
        self.title = title
        self.posterPath = data["posterPath"] as? String
        self.year = data["year"] as? String
        self.contributors = data["contributors"] as? [String] ?? []
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
    /// uid -> shelf name that person contributed, such as "foremost".
    var contributions: [String: String]
    /// votes[uid][movieId] = "yes" | "no"
    var votes: [String: [String: String]]
    var result: String?
    /// Participants who have marked the winning movie as watched.
    var watchedBy: [String]
    let createdAt: Date

    init(id: String, createdBy: String, participants: [String], status: SessionStatus,
         mode: SessionMode, sourceList: String, movies: [SessionMovie],
         contributions: [String: String] = [:],
         votes: [String: [String: String]] = [:], result: String? = nil,
         watchedBy: [String] = [], createdAt: Date = Date()) {
        self.id = id
        self.createdBy = createdBy
        self.participants = participants
        self.status = status
        self.mode = mode
        self.sourceList = sourceList
        self.movies = movies
        self.contributions = contributions
        self.votes = votes
        self.result = result
        self.watchedBy = watchedBy
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
        self.contributions = data["contributions"] as? [String: String] ?? [:]
        self.votes = data["votes"] as? [String: [String: String]] ?? [:]
        self.result = data["result"] as? String
        self.watchedBy = data["watchedBy"] as? [String] ?? []
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
            "contributions": contributions,
            "votes": votes,
            "createdAt": createdAt.timeIntervalSince1970
        ]
        if let result { d["result"] = result }
        if watchedBy.isEmpty == false { d["watchedBy"] = watchedBy }
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

extension MovieSession {
    /// Invites that were never accepted stop being offered after a week.
    /// The session document is left in place; the invitee leaves it so the
    /// creator is not stuck waiting on someone who will not vote.
    static let inviteLifetime: TimeInterval = 7 * 24 * 60 * 60

    var isExpiredPendingInvite: Bool {
        status == .pending && Date().timeIntervalSince(createdAt) > Self.inviteLifetime
    }

    var isStaleDoneInvite: Bool {
        status == .done && Date().timeIntervalSince(createdAt) > Self.inviteLifetime
    }

    /// Swipe and vote can be closed once every remaining participant has voted.
    /// Someone who declined is no longer in `participants`.
    func isReadyToFinalise() -> Bool {
        switch mode {
        case .swipe:
            return allParticipantsFinished()
        case .vote:
            return allParticipantsVotedOnce()
        case .random:
            return false
        }
    }

    func pickedResultID() -> String? {
        switch mode {
        case .swipe:
            return matchingMovies().randomElement()?.id
        case .vote:
            var tally: [String: Int] = [:]
            for uid in participants {
                for (movieID, _) in votes[uid] ?? [:] {
                    tally[movieID, default: 0] += 1
                }
            }
            guard let maxVotes = tally.values.max(), maxVotes > 0 else { return nil }
            return tally.filter { $0.value == maxVotes }.map(\.key).randomElement()
        case .random:
            return result
        }
    }
}
