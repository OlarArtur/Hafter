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
        case .foremost:
            // B4D7D5
            // 2v 4C98CF
            return #colorLiteral(red: 0.7058823529, green: 0.8431372549, blue: 0.8352941176, alpha: 1)
        case .possibly:
            // E0D7EE
            // 2v4873A6
            return #colorLiteral(red: 0.8784313725, green: 0.8431372549, blue: 0.9333333333, alpha: 1)
        case .ifNothingElse:
            // EEE7E3
            // 2v 5B538A
            return #colorLiteral(red: 0.9333333333, green: 0.9058823529, blue: 0.8901960784, alpha: 1)
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
