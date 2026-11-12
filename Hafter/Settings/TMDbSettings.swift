//
//  TMDbSettings.swift
//  Hafter
//
//  API keys are stored in Config.xcconfig → Info.plist.
//  Add Config.xcconfig to .gitignore before pushing to a public repository.
//

import Foundation

final class TMDbSettings {

    private init() {}
    static let shared = TMDbSettings()

    var apiKeyV3: String {
        Bundle.main.infoDictionary?["TMDbAPIKeyV3"] as? String ?? ""
    }

    var apiKeyV4: String {
        Bundle.main.infoDictionary?["TMDbAPIKeyV4"] as? String ?? ""
    }
}
