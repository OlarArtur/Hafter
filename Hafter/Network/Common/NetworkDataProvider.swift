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

enum NetworkErrors: Error, LocalizedError {
    case general
    case unauthorized
    case incorrectInputParams
    case statusCode(Int)
    case other(Error)

    var errorDescription: String? {
        switch self {
        case .general:
            return "The movie service didn't respond. Try again."
        case .unauthorized:
            return "Movie search isn't authorized yet. Check your connection and try again."
        case .incorrectInputParams:
            return "That movie request was invalid."
        case .statusCode(let code):
            switch code {
            case 401, 403:
                return "Movie search isn't authorized yet. Check your connection and try again."
            case 429:
                return "Too many movie searches. Wait a moment and try again."
            default:
                return "The movie service returned an error (\(code))."
            }
        case .other(let error):
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain {
                return "Couldn't reach the movie service. Check your connection and try again."
            }
            return error.localizedDescription
        }
    }

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
