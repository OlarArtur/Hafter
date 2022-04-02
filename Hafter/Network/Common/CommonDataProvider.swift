//
//  CommonDataProvider.swift
//  Hafter
//
//  Created by Artur Olar on 31.03.2022.
//

import Foundation
import Combine

enum ParsingError: Error {
    case invalidData
}

protocol DataParserProtocol {
    func parse<T: Decodable>(data: Data) -> AnyPublisher<T, ParsingError>
    func decode(data: Data) -> AnyPublisher<String?, ParsingError>
}

extension DataParserProtocol {
    
    func parse<T: Decodable>(data: Data) -> AnyPublisher<T, ParsingError> {

        let decoder = JSONDecoder()

        guard let result = try? decoder.decode(T.self, from: data) else {
            return Fail(error: .invalidData).eraseToAnyPublisher()
        }
        
        return Result.Publisher(result).eraseToAnyPublisher()
    }
    
    func decode(data: Data) -> AnyPublisher<String?, ParsingError> {
        
        guard let result = String(data: data, encoding: .utf8) else {
            return Fail(error: .invalidData).eraseToAnyPublisher()
        }
        return Result.Publisher(result).eraseToAnyPublisher()
    }
}

final class CommonDataParser: DataParserProtocol {

}
