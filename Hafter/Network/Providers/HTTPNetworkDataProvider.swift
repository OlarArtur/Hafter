//
//  HTTPNetworkDataProvider.swift
//  Hafter
//
//  Created by Artur Olar on 31.03.2022.
//

import Combine
import Foundation

final class HTTPNetworkDataProvider {
    //Fake json API for testing  https://api.mocki.io/v1/
    struct Constants {
        static let BASE_ULR = "https://api.mocki.io/v1/"
        static let SLASH = "/"
        static let QUESTION_MARK = "?"
    }

    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.default
        session = URLSession(configuration: configuration)
    }

    private func makeRequest(by requestConfig: RequestConfig) -> URLRequest? {
        let params = requestConfig.params

        let path: String? = {
            guard var path = requestConfig.path, path.isEmpty == false else {
                return nil
            }

            if path.hasPrefix(Constants.SLASH) {
                path.remove(at: path.startIndex)
            }

            if path.hasSuffix(Constants.SLASH) {
                path.remove(at: path.endIndex)
            }

            return path
        }()

        switch requestConfig.requestType {
        case .get:
            return makeQueryRequest(path: path, method: "GET", params: params)
        case .post:
            return makeBodyRequest(path: path, method: "POST", params: params)
        case .put:
            return makeBodyRequest(path: path, method: "PUT", params: params)
        case .delete:
            return makeQueryRequest(path: path, method: "DELETE", params: params)
        }
    }

    /// GET and DELETE share the query-string URL. Only string values are sent,
    /// matching the previous GET behavior.
    private func makeQueryRequest(path: String?, method: String, params: [String: AnyHashable]?) -> URLRequest? {
        let paramsString = params?.map { (key, value) -> String? in
            guard let value = value as? String else {
                return nil
            }
            return "\(key)=\(value)"
        }.compactMap { $0 }.joined(separator: "&")

        var url = Constants.BASE_ULR
        if let additionalPath = path, additionalPath.isEmpty == false {
            url.append(additionalPath)
        }
        if let requestParamsString = paramsString, requestParamsString.isEmpty == false {
            url.append(Constants.QUESTION_MARK)
            url.append(requestParamsString)
        }
        guard let requestURL = URL(string: url) else { return nil }
        var request = URLRequest(url: requestURL)
        request.httpMethod = method
        return request
    }

    /// POST and PUT send the parameter dictionary as a JSON body.
    private func makeBodyRequest(path: String?, method: String, params: [String: AnyHashable]?) -> URLRequest? {
        var url = Constants.BASE_ULR
        if let additionalPath = path, additionalPath.isEmpty == false {
            url.append(additionalPath)
        }
        guard let requestURL = URL(string: url) else { return nil }
        var request = URLRequest(url: requestURL)
        request.httpMethod = method
        if let params, let data = try? JSONSerialization.data(withJSONObject: params, options: .prettyPrinted) {
            request.httpBody = data
        }
        return request
    }
}

extension HTTPNetworkDataProvider: NetworkDataProviderProtocol {
    
    func doRequest(requestConfig: RequestConfig) -> AnyPublisher<Data?, NetworkErrors> {
        guard let request = makeRequest(by: requestConfig) else {
            return Fail(error: .incorrectInputParams).eraseToAnyPublisher()
        }

        return session.dataTaskPublisher(for: request)
            .tryMap { (data, response) -> Data? in
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
                    throw NetworkErrors.general
                }
                switch statusCode {
                case 200...299:
                    return data
                default:
                    throw NetworkErrors.statusCode(statusCode)
                }
            }.mapError { error -> NetworkErrors in
                return NetworkErrors.map(error)
            }.eraseToAnyPublisher()
    }
}
