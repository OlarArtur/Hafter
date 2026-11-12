# Hafter TMDb proxy

The iOS app used to ship the TMDb v3 key inside the IPA (`Config.xcconfig` → `Info.plist` → `TMDbSettings`). Release builds now call this Cloud Function instead. The function holds the key in Secret Manager and forwards only the two endpoints the app uses:

- `GET /search/movie?query=`
- `GET /movie/{numericId}`

Anything else, including a client-supplied `api_key`, is dropped.

## Blaze plan

Cloud Functions and Secret Manager require the Firebase project to be on the **Blaze (pay as you go)** plan. The Spark plan cannot deploy this function. Blaze still includes a free usage tier; you need the plan so Google can bill if traffic exceeds it.

## Deploy

From the repo root, on a machine logged into the Hafter Firebase project (`firebase login` and `firebase use <project-id>`):

```sh
cd functions
npm install
npm test
cd ..

firebase functions:secrets:set TMDB_API_KEY
firebase deploy --only functions
```

`firebase functions:secrets:set TMDB_API_KEY` prompts for the TMDb **v3** key (the same value that used to be `TMDB_API_KEY_V3`). Do not pass the key as a shell argument if your shell history is shared. The v4 key is unused: the app never calls a v4-only endpoint.

The deploy log prints the function URL. For this 2nd gen function the stable URL the app builds is:

```text
https://us-central1-<project-id>.cloudfunctions.net/tmdb
```

The app derives that from `FirebaseApp`'s project id and the `us-central1` region in `TMDbSettings`. If the URL printed by deploy is different (a Cloud Run host such as `https://tmdb-<hash>-uc.a.run.app`), set the override in the gitignored `Hafter/Config.xcconfig`:

```text
TMDB_PROXY_BASE_URL = https://tmdb-xxxxxxxx-uc.a.run.app
```

That value is not a secret. It is read from Info.plist as `TMDbProxyBaseURL`.

Confirm the secret is bound without printing it:

```sh
firebase functions:secrets:access TMDB_API_KEY >/dev/null && echo "secret is set"
```

## Who can call it

The Cloud Run invoker is public so the app can reach the function without a Google IAM identity. The function itself rejects the request unless one of these verifies:

1. `Authorization: Bearer <Firebase Auth ID token>`
2. `X-Firebase-AppCheck: <App Check token>` (only when no Authorization header is present)

A bad bearer token is rejected even if an App Check token is also attached.

Signed-in movie search works with Firebase Auth alone. Signed-out search (the Add and detail screens before Sign in with Apple) needs App Check:

1. Firebase console → App Check → register the iOS app (`app.olar.Hafter`) with the **DeviceCheck** provider.
2. Release builds use `DeviceCheckProvider`. No extra entitlement is required.
3. Debug builds use `AppCheckDebugProvider`. On first proxy request Xcode prints an App Check debug token. Register that token in the console, or sign in, or use the direct-key fallback below.

There is a per-instance limit of 120 requests per minute per Firebase uid (or per App Check subject). Search results are cached in memory for 10 minutes and movie details for 6 hours. Scaling to more instances raises the effective limit because the buckets are not shared.

## Debug fallback to the direct key

Release builds do not read a TMDb key and do not write one into Info.plist.

Debug builds can still call `api.themoviedb.org` when `Hafter/Config.xcconfig` (gitignored) contains:

```text
TMDB_USE_DIRECT_API = YES
TMDB_DIRECT_API_KEY_V3 = your_v3_key
```

Copy `Hafter/Config.xcconfig.example` if you do not already have that file. `TMDB_DIRECT_API_KEY_V3` is copied into the Debug Info.plist only. A Release / TestFlight / App Store archive does not have that build setting, so the key is not in the shipping app. The previous `TMDB_API_KEY_V3` / `TMDB_API_KEY_V4` names are no longer read; leaving them in an old `Config.xcconfig` does not put them in the binary. Leave `TMDB_USE_DIRECT_API` unset to exercise the proxy from a Debug build. Search and detail use the v3 key.

## What to verify on a device

This repo cannot compile the iOS app. After deploying:

1. Archive a **Release** build and confirm `TMDbAPIKeyV3` and `TMDbAPIKeyV4` are absent from the app's Info.plist (`plutil -p` on the unpacked IPA, or the built product's Info.plist).
2. Signed out, search for a movie of 3+ characters and open its detail. Posters still load from `image.tmdb.org` (no key).
3. Repeat while signed in.
4. Turn on airplane mode and confirm the search error is visible.
5. With `TMDB_USE_DIRECT_API = YES` and `TMDB_DIRECT_API_KEY_V3` set, in a Debug build only, confirm search still works with no function deployed.
