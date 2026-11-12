//
//  TMDbSettings.swift
//  Hafter
//
//  Release builds call the Cloud Functions proxy and do not contain a TMDb key.
//  Debug builds can fall back to api.themoviedb.org when Config.xcconfig sets
//  TMDB_USE_DIRECT_API = YES and TMDB_DIRECT_API_KEY_V3. That key is written
//  into the Debug Info.plist only. The old TMDB_API_KEY_V3 name is not read.
//  See functions/README.md.
//

import FirebaseCore
import Foundation

final class TMDbSettings {

    static let shared = TMDbSettings()

    /// Must match the region in functions/src/index.ts.
    static let proxyRegion = "us-central1"
    static let proxyFunctionName = "tmdb"

    private init() {}

    /// True only for a Debug build that opted into the direct key.
    var usesDirectAPI: Bool {
        #if DEBUG
        guard string("TMDbUseDirectAPI") == "YES" else { return false }
        return !apiKeyV3.isEmpty
        #else
        return false
        #endif
    }

    #if DEBUG
    var apiKeyV3: String { string("TMDbAPIKeyV3") }
    #endif

    /// Override with TMDB_PROXY_BASE_URL when the deploy URL is not the
    /// default cloudfunctions.net host. Empty means "derive from the Firebase project id".
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
