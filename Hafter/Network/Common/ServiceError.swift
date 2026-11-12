//
//  ServiceError.swift
//  Hafter
//
//  Created by Artur Olar on 31.03.2022.
//

import Foundation

enum ServiceError: Error, LocalizedError {
    case networkError(NetworkErrors)
    case parserError(ParsingError)
    case localDataError

    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return error.localizedDescription
        case .parserError:
            return "Couldn't read the movie data."
        case .localDataError:
            return "Couldn't read the movies saved on this device."
        }
    }
}
