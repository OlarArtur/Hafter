# Hafter TMDb proxy (not in use)

The app does **not** call this function today. Debug and Release both call `https://api.themoviedb.org` with `TMDB_API_KEY_V3` from the gitignored `Hafter/Config.xcconfig`. See the repo [README](../README.md).

`TMDB_USE_PROXY` defaults to `NO`. Movie search, sign-in, and Firestore work without the Blaze plan and without deploying anything in this folder. App Check is not installed while the proxy is off.

Keep this code. When there is a reason to take the key out of the app binary, flip the setting and deploy. No other code change is required.

## Switch the app over

In `Hafter/Config.xcconfig`:

```text
TMDB_USE_PROXY = YES
```

Rebuild. The first search logs `[TMDb] TMDB_USE_PROXY is YES`. The app then calls the function instead of TMDb, and `FirebaseBootstrap` installs App Check before configuring Firebase. The v3 key in the app is ignored on that path.

You still need a deployed function. Until this flag is `YES`, do not enable Blaze for this.

## What the function does

It holds the v3 key in the secret `TMDB_API_KEY` and forwards only:

- `GET /search/movie?query=`
- `GET /movie/{numericId}`

Anything else, including a client-supplied `api_key`, is dropped. Callers must present a Firebase Auth ID token or an App Check token. There is an in-memory cache (10 minutes for search, 6 hours for details) and a per-instance limit of 120 requests per minute.

## Blaze plan

Deploying Cloud Functions requires the Firebase **Blaze** plan. The Spark plan cannot deploy this function. Do this only when you are ready to turn `TMDB_USE_PROXY` on.

## Deploy

From the repo root, on a machine logged into the Hafter Firebase project:

```sh
cd functions
npm install
npm test
cd ..

firebase functions:secrets:set TMDB_API_KEY
firebase deploy --only functions
```

`firebase functions:secrets:set` prompts for the same v3 key as `TMDB_API_KEY_V3`. Do not pass the key on the command line. The v4 key is unused.

The app calls:

```text
https://us-central1-<project-id>.cloudfunctions.net/tmdb
```

If deploy prints a different URL, set it in `Hafter/Config.xcconfig` (not a secret):

```text
TMDB_PROXY_BASE_URL = https://tmdb-xxxxxxxx-uc.a.run.app
```

That value is read from Info.plist as `TMDbProxyBaseURL`.

Signed-out search through the proxy needs App Check:

1. Firebase console → App Check → register `app.olar.Hafter` with **DeviceCheck**.
2. Release builds use `DeviceCheckProvider`.
3. Debug builds use `AppCheckDebugProvider`. Register the debug token printed in the Xcode console, or sign in before searching.

Signed-in search works with Firebase Auth alone.
