//
//  HereafterMovie.swift
//  Hafter
//
//  Created by Artur Olar on 02.04.2022.
//

import UIKit

enum HereafterMovieType: String, CaseIterable {
    case foremost
    case possibly
    case ifNothingElse
    case viewed
    
    var title: String {
        switch self {
        case .foremost:
            return "Foremost"
        case .possibly:
            return "Possibly"
        case .ifNothingElse:
            return "If Nothing Else"
        case .viewed:
            return "Viewed"
        }
    }
    
    var typeColor: UIColor {
        switch self {
        case .foremost:     return DS.Color.tierForemost
        case .possibly:     return DS.Color.tierPossibly
        case .ifNothingElse: return DS.Color.tierIfNothingElse
        case .viewed:       return DS.Color.tierViewed
        }
    }
}

final class HereafterMovie: NSObject {
    var type: HereafterMovieType
    let movie: Movie
    var tags: [String]

    init(type: HereafterMovieType, movie: Movie, tags: [String] = []) {
        self.type = type
        self.movie = movie
        self.tags = tags
    }
}
