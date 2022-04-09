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
            return "If noth. else"
        case .viewed:
            return "Viewed"
        }
    }
    
    var typeColor: UIColor {
        switch self {
        case .foremost:
            return UIColor(red: 180 / 255.0, green: 215 / 255.0, blue: 213 / 255.0, alpha: 1.0)
        case .possibly:
            return UIColor(red: 224 / 255.0, green: 215 / 255.0, blue: 238 / 255.0, alpha: 1.0)
        case .ifNothingElse:
            return UIColor(red: 238 / 255.0, green: 231 / 255.0, blue: 227 / 255.0, alpha: 1.0)
        case .viewed:
            return UIColor(red: 184 / 255.0, green: 208 / 255.0, blue: 232 / 255.0, alpha: 1.0)
        }
    }
}

final class HereafterMovie: NSObject {
    var type: HereafterMovieType
    let movie: Movie
    
    init(type: HereafterMovieType, movie: Movie) {
        self.type = type
        self.movie = movie
    }
}
