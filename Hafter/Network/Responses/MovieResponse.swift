//
//  MovieResponse.swift
//  Hafter
//
//  Created by Artur Olar on 01.04.2022.
//

import Foundation

final class MovieResponse: Codable {
    
    enum CodingKeys: String, CodingKey {
        case page
        case results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
    
    let page: Int
    let results: [Movie]
    let totalPages: Int
    let totalResults: Int
}
