//
//  TMDbService.swift
//  Hafter
//
//  Created by Artur Olar on 01.04.2022.
//

import Combine

protocol MediaServiceProtocol {
    func search(query: String) -> AnyPublisher<MovieResponse?, ServiceError>
    func detailFor(id: String) -> AnyPublisher<DetailedMovie?, ServiceError>
}

final class TMDbService {
    
    private let networkProvider: NetworkDataProviderProtocol
    private let localProvider: LocalDataProviderProtocol
    private let parser: DataParserProtocol

    init(networkProvider: NetworkDataProviderProtocol,
        localProvider: LocalDataProviderProtocol,
        parser: DataParserProtocol
    ) {
        self.networkProvider = networkProvider
        self.localProvider = localProvider
        self.parser = parser
    }
}

extension TMDbService: MediaServiceProtocol {
    
    func search(query: String) -> AnyPublisher<MovieResponse?, ServiceError> {
        let params = ["query" : query,
                      "api_key" : TMDbSettings.shared.apiKeyV3]
        let requestConfig = RequestConfig(requestType: .get, params: params, path: "/search/movie")
        
        return networkProvider.doRequest(requestConfig: requestConfig)
            .mapError {
                ServiceError.networkError($0)
            }
            .flatMap { [weak self] data -> AnyPublisher<MovieResponse?, ServiceError> in
                guard let self = self,
                    let data = data else {
                        return Result.Publisher(nil).eraseToAnyPublisher()
                }
                let result: AnyPublisher<MovieResponse?, ServiceError> =
                    self.parser
                    .parse(data: data)
                    .mapError { ServiceError.parserError($0) }
                    .eraseToAnyPublisher()
                return result
            }
            .eraseToAnyPublisher()
    }
    
    func detailFor(id: String) -> AnyPublisher<DetailedMovie?, ServiceError> {
        
        let params = ["api_key" : TMDbSettings.shared.apiKeyV3]
        let requestConfig = RequestConfig(requestType: .get, params: params, path: "/movie/\(id)")
        
        return networkProvider.doRequest(requestConfig: requestConfig)
            .mapError {
                ServiceError.networkError($0)
            }
            .flatMap { [weak self] data -> AnyPublisher<DetailedMovie?, ServiceError> in
                guard let self = self,
                    let data = data else {
                        return Result.Publisher(nil).eraseToAnyPublisher()
                }
                let result: AnyPublisher<DetailedMovie?, ServiceError> =
                    self.parser
                    .parse(data: data)
                    .mapError { ServiceError.parserError($0) }
                    .eraseToAnyPublisher()
                return result
            }
            .eraseToAnyPublisher()
    }
}
