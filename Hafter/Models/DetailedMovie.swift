//
//  DetailedMovie.swift
//  Hafter
//
//  Created by Artur Olar on 03.09.2022.
//

import Foundation

final class DetailedMovie: Movie {
    
    enum CodingKeys: String, CodingKey {
        case genres
        case budget
        case runtime
    }
    
    let genres: [Genre]
    let budget: Int
    let runtime: Double?
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        genres = try container.decode([Genre].self, forKey: .genres)
        budget = try container.decode(Int.self, forKey: .budget)
        runtime = try? container.decode(Double.self, forKey: .runtime)
        try super.init(from: decoder)
    }
}

struct Genre: Codable {
    let id: Int
    let name: String
}
