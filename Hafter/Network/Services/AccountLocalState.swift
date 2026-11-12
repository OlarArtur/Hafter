//
//  AccountLocalState.swift
//  Hafter
//
//  Device state that belongs to the Firebase account, cleared after deletion.
//

import Foundation

enum AccountLocalState {

    /// Prefix for any future account-scoped defaults. Onboarding keys
    /// (`Hafter.IntroductionFinished`, `Hafter.isFirstLaunchingKey`) and the
    /// widget watchlist snapshot (`widget_foremost_movies`) do not use it.
    static let defaultsPrefix = "Hafter.account."

    /// Removes account-scoped defaults after the Firebase user has been deleted.
    ///
    /// What is intentionally left in place:
    /// - Core Data entity `DBHereafterMovie` is the on-device watchlist. It is
    ///   not keyed to the Firebase user, is available while signed out, and
    ///   contains no social records. There is no social cache to delete.
    /// - The App Group value `widget_foremost_movies` is a snapshot of that
    ///   watchlist for the widget, rewritten whenever the Foremost list loads.
    /// - Onboarding flags are device-level, not account-level.
    ///
    /// Firebase Auth stores the session in the keychain and clears it when the
    /// user is deleted.
    static func clearAfterAccountDeletion() {
        removePrefixedKeys(from: .standard)
        if let group = UserDefaults(suiteName: WidgetDataBridge.appGroupId) {
            removePrefixedKeys(from: group)
        }
    }

    private static func removePrefixedKeys(from defaults: UserDefaults) {
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(defaultsPrefix) {
            defaults.removeObject(forKey: key)
        }
    }
}
