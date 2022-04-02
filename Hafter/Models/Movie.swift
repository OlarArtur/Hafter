//
//  Movie.swift
//  Hafter
//
//  Created by Artur Olar on 01.04.2022.
//

import Foundation

final class Movie: Codable {
    
    enum CodingKeys: String, CodingKey {
        case adult
        case backdropPath = "backdrop_path"
        case originalLanguage = "original_language"
        case title
        case originalTitle = "original_title"
        case overview
        case popularity
        case posterPath = "poster_path"
        case releaseDate = "release_date"
    }
    
    init(title: String) {
        self.adult = false
        self.backdropPath = nil
        self.originalLanguage = ""
        self.title = title
        self.originalTitle = ""
        self.overview = ""
        self.popularity = 0
        self.posterPath = nil
        self.releaseDate = nil
    }
    
    let adult: Bool
    let backdropPath: String?
    let originalLanguage: String
    let title: String
    let originalTitle: String
    let overview: String
    let popularity: Double
    let posterPath: String?
    let releaseDate: Date?
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        adult = try container.decode(Bool.self, forKey: .adult)
        backdropPath = try? container.decode(String.self, forKey: .backdropPath)
        originalLanguage = try container.decode(String.self, forKey: .originalLanguage)
        title = try container.decode(String.self, forKey: .title)
        originalTitle = try container.decode(String.self, forKey: .originalTitle)
        overview = try container.decode(String.self, forKey: .overview)
        popularity = try container.decode(Double.self, forKey: .popularity)
        posterPath = try? container.decode(String.self, forKey: .posterPath)
        
        let releaseDateString = try container.decode(String.self, forKey: .releaseDate)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        releaseDate = dateFormatter.date(from: releaseDateString)
    }
}
