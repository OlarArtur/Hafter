//
//  Settings.swift
//  Hafter
//
//  Created by Artur Olar on 29.03.2022.
//

import Foundation

private enum SettingsKeys: String {
    case isFirstLaunchingKey = "Hafter.isFirstLaunchingKey"
    case introductionFinished = "Hafter.IntroductionFinished"
}

final class Settings {
    
    private init() {}
    static let shared = Settings()
    
    var isFirstLaunching: Bool {
        return UserDefaults.standard.string(forKey: SettingsKeys.isFirstLaunchingKey.rawValue) == nil
    }
    
    var introductionFinished: Bool {
        get {
            return UserDefaults.standard.bool(forKey: SettingsKeys.introductionFinished.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: SettingsKeys.introductionFinished.rawValue)
        }
    }
}
