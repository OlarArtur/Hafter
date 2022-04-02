//
//  TMDbSettings.swift
//  Hafter
//
//  Created by Artur Olar on 01.04.2022.
//

import Foundation

final class TMDbSettings {
    
    private init() {}
    static let shared = TMDbSettings()
    
    var apiKeyV3: String {
        return "2ce627ffcd028d0e05d065c475d82831"
    }
    
    var apiKeyV4: String {
        return "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiIyY2U2MjdmZmNkMDI4ZDBlMDVkMDY1YzQ3NWQ4MjgzMSIsInN1YiI6IjYyNDZjOTMyYTNlNGJhMDA5ZjcxYmJkZSIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.02pSyZJLusICrXwwN3Gj8f7jImrJm2rOeBrR21MHM5A"
    }
}
