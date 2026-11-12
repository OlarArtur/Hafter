//
//  FirebaseBootstrap.swift
//  Hafter
//
//  Configures Firebase once, and installs App Check before that configure call.
//  The TMDb proxy accepts either a Firebase Auth ID token or an App Check token.
//  Movie search is available while signed out, so App Check covers that path.
//

import FirebaseAppCheck
import FirebaseCore

enum FirebaseBootstrap {

    static func configure() {
        guard FirebaseApp.app() == nil else { return }
        AppCheck.setAppCheckProviderFactory(HafterAppCheckProviderFactory())
        FirebaseApp.configure()
    }
}

/// Release uses DeviceCheck, which does not need an extra entitlement.
/// App Attest would require the App Attest capability on the App ID.
/// Debug uses the App Check debug provider. The debug token is printed in the
/// Xcode console and must be registered in the Firebase console before a
/// signed-out Debug build can call the TMDb proxy. Signing in, or the
/// Debug direct-key fallback, does not need that token.
private final class HafterAppCheckProviderFactory: NSObject, AppCheckProviderFactory {

    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        #if DEBUG
        return AppCheckDebugProvider(app: app)
        #else
        return DeviceCheckProvider(app: app)
        #endif
    }
}
