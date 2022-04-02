//
//  TMDbNetworkDataProvider.swift
//  Hafter
//
//  Created by Artur Olar on 01.04.2022.
//

import Combine
import Foundation

final class TMDbNetworkDataProvider {
    
    struct Constants {
        static let BASE_ULR = "https://api.themoviedb.org/3/"
        static let SLASH = "/"
        static let QUESTION_MARK = "?"
    }

    private let session: URLSession
    
    init() {
        let configuration = URLSessionConfiguration.default
        configuration.urlCredentialStorage = nil
        session = URLSession(configuration: configuration)
    }

    private func makeRequest(by requestConfig: RequestConfig) -> URLRequest? {
        var request: URLRequest?

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
            let urlString: String = {
                var url = Constants.BASE_ULR
                if let additionalPath = path, additionalPath.isEmpty == false {
                    url.append(additionalPath)
                }
                url.append(Constants.QUESTION_MARK)
                url.append(requestConfig.parametersString())
                return url
            }()
            
            guard let url = URL(string: urlString) else {
                return nil
            }
            request = URLRequest(url: url)

            return request
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
            request?.httpMethod = requestConfig.requestType.rawValue
            request?.setValue(TMDbSettings.shared.apiKeyV4, forHTTPHeaderField: "Authorization")
            request?.setValue("application/json;charset=utf-8", forHTTPHeaderField: "Content-Type")
            
            let params = requestConfig.parametersString()
            if !params.isEmpty {
                let paramData = params.data(using: .utf8)
                request?.httpBody = paramData
            }
            
            return request
        case .delete:
            return nil
        case .put:
            return nil
        }

    }
}

extension TMDbNetworkDataProvider: NetworkDataProviderProtocol {
    
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
                    print(String(data: data, encoding: .utf8) ?? "Error status code - \(statusCode)")
                    throw NetworkErrors.statusCode(statusCode)
                }
            }.mapError { error -> NetworkErrors in
                return NetworkErrors.map(error)
            }.eraseToAnyPublisher()
    }

}

final class HTTPBasicAuthenticationSessionTaskDelegate: NSObject, URLSessionTaskDelegate {
    
    private let credential: URLCredential
    
    init(user: String, password: String) {
        self.credential = URLCredential(user: user, password: password, persistence: .forSession)
    }
    
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, credential)
    }
}
