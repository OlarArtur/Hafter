//
//  TMDbSettings.swift
//  Hafter
//
//  Movie search calls api.themoviedb.org with TMDB_API_KEY_V3 from the gitignored
//  Config.xcconfig, copied into Info.plist for Debug and Release.
//  Set TMDB_USE_PROXY = YES to send those calls through the Cloud Functions
//  proxy in functions/ instead. That path is off until there is a reason to
//  pay for Blaze. See README.md and functions/README.md.
//

import FirebaseCore
import Foundation

final class TMDbSettings {

    static let shared = TMDbSettings()

    /// Must match the region in functions/src/index.ts.
    static let proxyRegion = "us-central1"
    static let proxyFunctionName = "tmdb"

    private init() {}

    /// Default is direct TMDb. Only the string YES turns the proxy on.
    var usesProxy: Bool {
        string("TMDbUseProxy") == "YES"
    }

    /// v3 key from Info.plist (`TMDB_API_KEY_V3`). Empty when the xcconfig value was not set.
    var apiKeyV3: String { string("TMDbAPIKeyV3") }

    /// Override with TMDB_PROXY_BASE_URL when the deploy URL is not the
    /// default cloudfunctions.net host. Empty means "derive from the Firebase project id".
    /// Used only when `usesProxy` is true.
    var proxyBaseURL: URL? {
        let override = string("TMDbProxyBaseURL")
        if override.hasPrefix("https://"), let url = URL(string: override) {
            return url
        }
        guard let projectID = FirebaseApp.app()?.options.projectID, !projectID.isEmpty else {
            return nil
        }
        return URL(string: "https://\(Self.proxyRegion)-\(projectID).cloudfunctions.net/\(Self.proxyFunctionName)")
    }

    private func string(_ key: String) -> String {
        let raw = (Bundle.main.infoDictionary?[key] as? String) ?? ""
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty || value.hasPrefix("$(") {
            return ""
        }
        return value
    }
}
