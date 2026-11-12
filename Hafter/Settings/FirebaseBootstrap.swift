//
//  FirebaseBootstrap.swift
//  Hafter
//
//  Configures Firebase once. App Check is installed only when the TMDb proxy
//  is switched on (`TMDB_USE_PROXY = YES`). With the proxy off, nothing in the
//  app asks App Check for a token, and Auth and Firestore do not depend on it.
//

import FirebaseAppCheck
import FirebaseCore

enum FirebaseBootstrap {

    static func configure() {
        guard FirebaseApp.app() == nil else { return }
        if TMDbSettings.shared.usesProxy {
            AppCheck.setAppCheckProviderFactory(HafterAppCheckProviderFactory())
        }
        FirebaseApp.configure()
    }
}

/// Release uses DeviceCheck, which does not need an extra entitlement.
/// App Attest would require the App Attest capability on the App ID.
/// Debug uses the App Check debug provider. The debug token is printed in the
/// Xcode console on the first proxy request and must be registered in the
/// Firebase console before a signed-out build can call the proxy.
private final class HafterAppCheckProviderFactory: NSObject, AppCheckProviderFactory {

    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        #if DEBUG
        return AppCheckDebugProvider(app: app)
        #else
        return DeviceCheckProvider(app: app)
        #endif
    }
}
