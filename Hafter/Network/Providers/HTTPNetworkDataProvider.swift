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
        var request: URLRequest?
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
            let paramsString = params?.map { (key, value) -> String? in
                guard let value = value as? String else {
                    return nil
                }

                return "\(key)=\(value)"
            }.compactMap { $0 }.joined(separator: "&")

            let urlString: String = {
                var url = Constants.BASE_ULR
                if let additionalPath = path, additionalPath.isEmpty == false {
                    url.append(additionalPath)
                }

                if let requestParamsString = paramsString, requestParamsString.isEmpty == false {
                    url.append(Constants.QUESTION_MARK)
                    url.append(requestParamsString)
                }
                return url
            }()

            guard let url = URL(string: urlString) else {
                return nil
            }
            request = URLRequest(url: url)
            request?.httpMethod = "GET"
        case .post:
            let urlString: String = {
                var url = Constants.BASE_ULR
                if let additionalPath = path, additionalPath.isEmpty == false {
                    url.append(additionalPath)
                }
                return url
            }()

            guard let url = URL(string: urlString) else {
                return nil
            }
            request = URLRequest(url: url)
            request?.httpMethod = "POST"
            if let params = params, let data = try? JSONSerialization.data(withJSONObject: params, options: .prettyPrinted) {
                request?.httpBody = data
            }
        case .put:
            //TODO: should be implemented
            return nil
        case .delete:
            //TODO: should be implemented
            return nil
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
