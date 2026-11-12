//
//  Constants.swift
//  Hafter
//
//  Created by Artur Olar on 08.04.2022.
//

import UIKit
import WidgetKit

// MARK: - Design System

enum DS {

    // MARK: Color

    enum Color {
        // Tier palette
        static let tierForemost      = UIColor(red: 180/255, green: 215/255, blue: 213/255, alpha: 1)
        static let tierPossibly      = UIColor(red: 224/255, green: 215/255, blue: 238/255, alpha: 1)
        static let tierIfNothingElse = UIColor(red: 238/255, green: 231/255, blue: 227/255, alpha: 1)
        static let tierViewed        = UIColor(red: 184/255, green: 208/255, blue: 232/255, alpha: 1)

        // Brand
        static let accent            = UIColor(red: 0.51, green: 0.58, blue: 0.99, alpha: 1)
        static let accentDim         = UIColor(red: 0.51, green: 0.58, blue: 0.99, alpha: 0.26)
        static let brandIndigo       = UIColor(red: 0.26, green: 0.32, blue: 0.72, alpha: 1)
        static let labelMuted        = UIColor(red: 0.357, green: 0.325, blue: 0.541, alpha: 1)

        // UI controls
        static let sidebarBackground = UIColor(red: 0.81, green: 1, blue: 1, alpha: 1)
        static let navIconDark       = UIColor(red: 0.149, green: 0.196, blue: 0.220, alpha: 1)
        static let navIconLight      = UIColor(red: 0.659, green: 0.722, blue: 0.784, alpha: 1)
        static let iconMuted         = UIColor(red: 0.35, green: 0.42, blue: 0.52, alpha: 1)
        static let iconDark          = UIColor(red: 0.14, green: 0.13, blue: 0.21, alpha: 1)
        static let iconAdd           = UIColor(red: 0.188, green: 0.69, blue: 0.78, alpha: 1)
    }

    // MARK: Typography

    enum Typography {
        static let display  = UIFont.systemFont(ofSize: 38, weight: .semibold)
        static let title1   = UIFont.systemFont(ofSize: 20, weight: .bold)
        static let title2   = UIFont.systemFont(ofSize: 17, weight: .semibold)
        static let body     = UIFont.systemFont(ofSize: 16, weight: .medium)
        static let callout  = UIFont.systemFont(ofSize: 15, weight: .regular)
        static let footnote = UIFont.systemFont(ofSize: 14, weight: .medium)
        static let caption  = UIFont.systemFont(ofSize: 13, weight: .regular)
    }

    // MARK: Radius

    enum Radius {
        static let sheet:   CGFloat = 40
        static let card:    CGFloat = 20
        static let chip:    CGFloat = 10
        static let button:  CGFloat = 14
        static let poster:  CGFloat = 8
        static let small:   CGFloat = 6
    }

    // MARK: Spacing

    enum Spacing {
        static let xs: CGFloat = 8
        static let s:  CGFloat = 12
        static let m:  CGFloat = 20
        static let l:  CGFloat = 24
        static let xl: CGFloat = 40
    }
}

// MARK: - Widget data bridge

enum WidgetDataBridge {
    static let appGroupId = "group.app.olar.Hafter"
    static let moviesKey  = "widget_foremost_movies"
    static let tonightKey = "widget_tonight_pick"

    struct MovieEntry: Codable {
        let title: String
        let year: String?
        let posterPath: String?
    }

    struct TonightEntry: Codable, Equatable {
        var sessionID: String
        var movieID: String
        var title: String
        var year: String?
    }

    static func write(movies: [HereafterMovie]) {
        let entries = movies.prefix(30).map {
            MovieEntry(title: $0.movie.title,
                       year: $0.movie.year(),
                       posterPath: $0.movie.posterPath)
        }
        guard let data = try? JSONEncoder().encode(entries) else { return }
        defaults.set(data, forKey: moviesKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func readMovies() -> [MovieEntry] {
        guard let data = defaults.data(forKey: moviesKey),
              let entries = try? JSONDecoder().decode([MovieEntry].self, from: data)
        else { return [] }
        return entries
    }

    static func writeTonight(_ entry: TonightEntry?) {
        if let entry, let data = try? JSONEncoder().encode(entry) {
            defaults.set(data, forKey: tonightKey)
        } else {
            defaults.removeObject(forKey: tonightKey)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func readTonight() -> TonightEntry? {
        guard let data = defaults.data(forKey: tonightKey),
              let entry = try? JSONDecoder().decode(TonightEntry.self, from: data)
        else { return nil }
        return entry
    }

    /// Free Personal Teams cannot sign an App Group, so the list stays in the
    /// app process. Siri still reads it. The widget cannot see it and shows a placeholder.
    private static var defaults: UserDefaults {
        #if FREE_SIGNING
        return .standard
        #else
        return UserDefaults(suiteName: appGroupId) ?? .standard
        #endif
    }
}

// MARK: - Legacy constants (kept for backward compatibility)

final class ImageConstants {
    static var viewed = "viewed"
    static var menu = "menu"
    static var foremost = "foremost"
    static var possibly = "possibly"
    static var ifNothingElse = "if_nothing_else"
    static var foremostLarge = "formost_large_circle"
    static var possiblyLarge = "possibly_large_circle"
    static var ifNothingElseLarge = "if_nothing_else_large_circle"
    static var dropListArrow = "drop_list_arrow"
    static var posterholder = "posterholder"
    static var back = "back"
}

final class ColorConstants {
    static var main          = DS.Color.tierForemost
    static var formost       = DS.Color.tierForemost
    static var possibly      = DS.Color.tierPossibly
    static var ifNothingElse = DS.Color.tierIfNothingElse
}
