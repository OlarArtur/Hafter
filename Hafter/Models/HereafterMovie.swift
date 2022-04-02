//
//  HereafterMovie.swift
//  Hafter
//
//  Created by Artur Olar on 02.04.2022.
//

import Foundation

enum HereafterMovieType {
    case foremost
    case possibly
    case ifNothingElse
}

final class HereafterMovie {
    let type: HereafterMovieType
    let movie: Movie
    
    init(type: HereafterMovieType, movie: Movie) {
        self.type = type
        self.movie = movie
    }
}
