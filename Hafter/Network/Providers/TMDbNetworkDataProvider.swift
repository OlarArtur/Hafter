//
//  TMDbNetworkDataProvider.swift
//  Hafter
//
//  Created by Artur Olar on 01.04.2022.
//

import Combine
import FirebaseAppCheck
import FirebaseAuth
import FirebaseCore
import Foundation

/// Talks to the TMDb proxy (or, in an opted-in Debug build, to TMDb directly).
/// Only the endpoints `TMDbService` uses are built here: search and movie detail.
final class TMDbNetworkDataProvider {

    private struct Call {
        let path: String
        let query: [URLQueryItem]
    }

    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.urlCredentialStorage = nil
        configuration.timeoutIntervalForRequest = 30
        session = URLSession(configuration: configuration)
    }

    /// Search and numeric movie detail only. Other paths are refused so a
    /// future caller cannot relay arbitrary TMDb traffic through the user's token.
    private func allowedCall(_ requestConfig: RequestConfig) -> Call? {
        guard requestConfig.requestType == .get else { return nil }
        guard var path = requestConfig.path, path.isEmpty == false else { return nil }
        if path.hasPrefix("/") { path.removeFirst() }
        if path.hasSuffix("/") { path.removeLast() }

        if path == "search/movie" {
            guard let query = requestConfig.params?["query"] as? String else { return nil }
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.isEmpty == false, trimmed.count <= 200 else { return nil }
            return Call(path: path, query: [URLQueryItem(name: "query", value: trimmed)])
        }

        let prefix = "movie/"
        guard path.hasPrefix(prefix) else { return nil }
        let id = String(path.dropFirst(prefix.count))
        guard id.range(of: #"^\d+$"#, options: .regularExpression) != nil else { return nil }
        return Call(path: path, query: [])
    }

    private func perform(_ request: URLRequest) -> AnyPublisher<Data?, NetworkErrors> {
        session.dataTaskPublisher(for: request)
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
            }
            .mapError { error -> NetworkErrors in
                NetworkErrors.map(error)
            }
            .eraseToAnyPublisher()
    }

    private func url(base: URL, call: Call, extraQuery: [URLQueryItem]) -> URL? {
        let baseString = base.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard var components = URLComponents(string: baseString + "/" + call.path) else { return nil }
        let items = call.query + extraQuery
        components.queryItems = items.isEmpty ? nil : items
        return components.url
    }

    #if DEBUG
    private func directRequest(for call: Call) -> URLRequest? {
        let key = TMDbSettings.shared.apiKeyV3
        guard key.isEmpty == false,
              let base = URL(string: "https://api.themoviedb.org/3"),
              let url = url(base: base, call: call, extraQuery: [URLQueryItem(name: "api_key", value: key)]) else {
            return nil
        }
        return URLRequest(url: url)
    }
    #endif

    private func proxyRequest(for call: Call, headers: [String: String]) -> URLRequest? {
        guard let base = TMDbSettings.shared.proxyBaseURL,
              let url = url(base: base, call: call, extraQuery: []) else {
            return nil
        }
        var request = URLRequest(url: url)
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        return request
    }

    /// Auth when the user is signed in, App Check otherwise (and also when both exist).
    /// The proxy accepts either. A missing token fails the request instead of calling TMDb.
    private func proxyHeaders() -> AnyPublisher<[String: String], NetworkErrors> {
        let appCheckToken = Future<String?, Never> { promise in
            guard FirebaseApp.app() != nil else {
                promise(.success(nil))
                return
            }
            AppCheck.appCheck().token(forcingRefresh: false) { token, _ in
                promise(.success(token?.token))
            }
        }
        let idToken = Future<String?, Never> { promise in
            guard let user = Auth.auth().currentUser else {
                promise(.success(nil))
                return
            }
            user.getIDToken { token, _ in
                promise(.success(token))
            }
        }

        return appCheckToken
            .zip(idToken)
            .tryMap { appCheck, auth -> [String: String] in
                var headers: [String: String] = [:]
                if let auth, auth.isEmpty == false {
                    headers["Authorization"] = "Bearer \(auth)"
                }
                if let appCheck, appCheck.isEmpty == false {
                    headers["X-Firebase-AppCheck"] = appCheck
                }
                if headers.isEmpty {
                    throw NetworkErrors.unauthorized
                }
                return headers
            }
            .mapError { NetworkErrors.map($0) }
            .eraseToAnyPublisher()
    }
}

extension TMDbNetworkDataProvider: NetworkDataProviderProtocol {

    func doRequest(requestConfig: RequestConfig) -> AnyPublisher<Data?, NetworkErrors> {
        guard let call = allowedCall(requestConfig) else {
            return Fail(error: .incorrectInputParams).eraseToAnyPublisher()
        }

        #if DEBUG
        if TMDbSettings.shared.usesDirectAPI {
            guard let request = directRequest(for: call) else {
                return Fail(error: .incorrectInputParams).eraseToAnyPublisher()
            }
            return perform(request)
        }
        #endif

        return proxyHeaders()
            .flatMap { [weak self] headers -> AnyPublisher<Data?, NetworkErrors> in
                guard let self, let request = self.proxyRequest(for: call, headers: headers) else {
                    return Fail(error: .incorrectInputParams).eraseToAnyPublisher()
                }
                return self.perform(request)
            }
            .eraseToAnyPublisher()
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
