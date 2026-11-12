# Hafter

iOS app (UIKit) for a personal movie list, plus friends and shared picking sessions.

## TMDb

Search and movie detail call `https://api.themoviedb.org` directly. The v3 key lives only in the gitignored `Hafter/Config.xcconfig` and is copied into the app Info.plist for Debug and Release.

```sh
cp Hafter/Config.xcconfig.example Hafter/Config.xcconfig
```

Set `TMDB_API_KEY_V3` in that file, then rebuild. Do not commit the file. The older name `TMDB_DIRECT_API_KEY_V3` is not read. If the key is missing, search fails and Xcode logs:

```text
[TMDb] Missing API key. Set TMDB_API_KEY_V3 in Hafter/Config.xcconfig ...
```

`TMDB_USE_PROXY` defaults to `NO`. Leave it that way. The app does not call Cloud Functions, and movie search does not need the Blaze plan or a deployed function. Auth and Firestore stay on the Spark plan. App Check is not installed while the proxy is off, so it cannot block sign-in, friends, or search.

Posters still load from `image.tmdb.org` and do not use the key.

## Optional proxy

`functions/` is a Cloud Functions proxy that can hold the TMDb key outside the app. It is not used until `TMDB_USE_PROXY` is `YES` and the function is deployed. Turning that on requires the Firebase Blaze plan. Steps are in [functions/README.md](functions/README.md). With the flag set to `YES`, the app installs App Check before `FirebaseApp.configure()` and sends search through the proxy instead of calling TMDb itself.

## Firebase in the app

`AppDelegate` calls `FirebaseBootstrap.configure()` once. That is the only startup path.

## Free Apple team

`HAFTER_FREE_SIGNING` defaults to `YES` so the project signs with a free Personal Team. That build leaves out iCloud, Sign in with Apple, and the App Group. Shelves, tags, ratings, dates, TMDb search, the random pick, and Siri keep working. Friends and sessions show "Requires full build". The widget shows a placeholder because a free team cannot share an App Group. Set `HAFTER_FREE_SIGNING = NO` in `Hafter/Config.xcconfig` after you enroll in the paid program.

## iCloud

The personal shelves, tags, ratings, and watched dates sync through the private iCloud database (`iCloud.app.olar.Hafter`) when that container is enabled for the App ID. If iCloud is signed out or the container is missing, the list stays on the device and the widget keeps using the App Group snapshot. CloudKit private storage does not need the Blaze plan.
