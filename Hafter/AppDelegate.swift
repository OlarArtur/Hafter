//
//  AppDelegate.swift
//  Hafter
//
//  Created by Artur Olar on 28.03.2022.
//

import UIKit
import AppIntents

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if #available(iOS 16, *) {
            HafterShortcuts.updateAppShortcutParameters()
        }
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}

// MARK: - Siri / Shortcuts

@available(iOS 16, *)
struct GetRandomMovieIntent: AppIntent {
    static var title: LocalizedStringResource = "What to watch tonight?"
    static var description = IntentDescription(
        "Picks a random movie from your Foremost list in Hafter"
    )

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let movies = WidgetDataBridge.readMovies()
        guard !movies.isEmpty else {
            return .result(dialog: "Your Foremost list is empty — add some movies first!")
        }
        let pick = movies.randomElement()!
        if let year = pick.year {
            return .result(dialog: "How about \(pick.title) (\(year))?")
        }
        return .result(dialog: "How about \(pick.title)?")
    }
}

@available(iOS 16, *)
struct HafterShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetRandomMovieIntent(),
            phrases: [
                "What should I watch in \(.applicationName)?",
                "Pick a movie from \(.applicationName)",
                "\(.applicationName), what to watch?"
            ],
            shortTitle: "Random movie",
            systemImageName: "film"
        )
    }
}
