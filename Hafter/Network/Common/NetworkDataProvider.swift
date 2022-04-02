//
//  NetworkDataProvider.swift
//  Hafter
//
//  Created by Artur Olar on 31.03.2022.
//

import Combine
import Foundation

enum NetworkRequestType: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

enum NetworkErrors: Error {
    case general
    case unauthorized
    case incorrectInputParams
    case statusCode(Int)
    case other(Error)

    static func map(_ error: Error) -> NetworkErrors {
        return (error as? NetworkErrors) ?? .other(error)
    }
}

struct RequestConfig {
    
    let requestType: NetworkRequestType
    let params: [String: AnyHashable]?
    let path: String?
}

protocol NetworkDataProviderProtocol {
    
    func doRequest(requestConfig: RequestConfig) -> AnyPublisher<Data?, NetworkErrors>
}

extension RequestConfig {
    
    func parametersString() -> String {
        var string: String = ""
        params?.forEach {
            if string.isEmpty {
                string.append("\($0.key)=\($0.value)")
                return
            }
            string.append("&\($0.key)=\($0.value)")
        }
        return string
    }
}
