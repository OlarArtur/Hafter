//
//  ViewedShelf.swift
//  Hafter
//
//  Sorting and captions for movies that have been watched.
//

import Foundation

enum ViewedShelf {

    struct Item: Equatable {
        var id: String
        var watchedDate: Date?
        var rating: Int?
    }

    static func clampRating(_ value: Int) -> Int {
        min(5, max(1, value))
    }

    /// Newest watched date first. Movies without a date stay at the bottom.
    static func sorted(_ items: [Item]) -> [Item] {
        items.sorted { lhs, rhs in
            switch (lhs.watchedDate, rhs.watchedDate) {
            case let (left?, right?):
                return left > right
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                return lhs.id < rhs.id
            }
        }
    }

    static func caption(rating: Int?, date: Date?) -> String? {
        let stars = rating.map { "\(clampRating($0))/5" }
        let day: String? = date.map { value in
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: value)
        }
        let parts = [stars, day].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
