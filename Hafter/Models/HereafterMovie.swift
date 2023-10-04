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
            // 4C98CF
            return #colorLiteral(red: 0.2980392157, green: 0.5960784314, blue: 0.8117647059, alpha: 1)
        case .possibly:
            // 4873A6
            return #colorLiteral(red: 0.2823529412, green: 0.4509803922, blue: 0.6509803922, alpha: 1)
        case .ifNothingElse:
            // 5B538A
            return #colorLiteral(red: 0.3568627451, green: 0.3254901961, blue: 0.5411764706, alpha: 1)
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
