//
//  ServiceError.swift
//  Hafter
//
//  Created by Artur Olar on 31.03.2022.
//

import Foundation

enum ServiceError: Error {
    case networkError(NetworkErrors)
    case parserError(ParsingError)
}
