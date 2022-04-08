//
//  HereafterMovie.swift
//  Hafter
//
//  Created by Artur Olar on 02.04.2022.
//

import Foundation

enum HereafterMovieType: String, CaseIterable {
    case foremost
    case possibly
    case ifNothingElse
    case viewed
}

final class HereafterMovie {
    let type: HereafterMovieType
    let movie: Movie
    
    init(type: HereafterMovieType, movie: Movie) {
        self.type = type
        self.movie = movie
    }
}
