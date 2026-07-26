# FaceDeliver — Flutter app

Native Android/iOS client for the FaceDeliver event-photo platform. It talks
directly to the Express API in [`../backend`](../backend); the Next.js app in
[`../frontend`](../frontend) remains the web surface.

Both audiences the platform serves live in this one app, separated by role:

| Guest | Organiser (`admin`) |
| --- | --- |
| Scan the event QR code | Create events, share the QR |
| Register with a selfie + consent | Upload galleries from the camera roll |
| Personal gallery of matched photos | Watch matching and processing state |
| Save a photo, or the whole album as a ZIP | Delivery analytics per event |
| Delete every piece of personal data | Plans, quota and Razorpay checkout |

## Running it

The app and the API are independent processes. The backend runs wherever you
like and the app is simply told its address — there is no tunnel or port
forwarding tying the two together.

**1. Start the backend** (in `../backend`):

```bash
npm run dev          # listens on 0.0.0.0:5001
```

**2. Point the app at it.** Environment lives in `config/dev.json`, so the run
command stays short:

```json
{
  "API_BASE_URL": "http://192.168.1.20:5001/api",
  "WEB_ORIGIN": "http://192.168.1.20:3000"
}
```

Replace the address with the machine running the backend — `ipconfig getifaddr
en0` on macOS, `hostname -I` on Linux. Keep the `/api` suffix; it matches the
Express mount points.

**3. Run:**

```bash
flutter pub get
flutter run --dart-define-from-file=config/dev.json
```

Phone and backend machine must be on the same network. That is the only
coupling — restart either side independently, and hot reload keeps working.

Release builds read `config/prod.json` instead:

```bash
flutter build apk --release --dart-define-from-file=config/prod.json
```

`WEB_ORIGIN` only affects the registration link encoded in an event's QR code.
It must match wherever the Next.js `/register` route is served, so a guest
scanning with a plain camera app still lands somewhere useful.

Without either flag the app falls back to `http://10.0.2.2:5001/api` on Android
(the emulator's route to its host) and `http://localhost:5001/api` elsewhere.

### Why plain HTTP works in development but not in production

Android refuses cleartext traffic by default, and this project keeps that true
for anything it ships:

- `src/main/res/xml/network_security_config.xml` — used by **release** builds.
  Refuses cleartext outright.
- `src/debug/res/xml/network_security_config.xml` — replaces it in **debug**
  builds via Gradle resource merging. Permits cleartext to any host, so the app
  can reach a laptop at whatever LAN address it has today.

On iOS, `NSAllowsLocalNetworking` in `Info.plist` covers the same ground.

Production traffic is HTTPS with no exception.

## How it is put together

```
lib/
  core/
    config/       API base URL, retention window, batch sizes
    network/      Dio wrapper that speaks this API's `{ error }` dialect
    router/       go_router with role-aware redirects
    storage/      token + user in the keystore/keychain
    theme/        colour, type and spacing tokens
    utils/        formatting, QR payload parsing, image compression
  data/
    models/       one class per API payload
    repositories/ one per API domain: auth, guests, admin, billing
  state/          SessionController — the router's refreshListenable
  features/       splash, auth, guest/*, admin/*
  widgets/        the shared component set
```

A single `ApiClient` is shared by every repository, so the bearer token and the
401-triggered sign-out are wired in exactly one place. The web client routes
requests through a Next.js proxy to keep the token in an HttpOnly cookie — a
browser constraint that does not apply here, where the token lives in the
platform keystore instead.

### Decisions worth knowing

- **`Event.code` is the public key.** QR links, guest registration, photo
  uploads and download stats all key off the code. The document `_id` is used
  only for admin routing.
- **Uploads are compressed on device and sent in batches of 30.** The API
  accepts 300 files per request but rate-limits uploads to 30 requests a
  minute, and venue Wi-Fi drops often — a failed batch of 30 costs far less
  than a failed batch of 300.
- **A 202 does not mean the photos are ready.** Face detection and matching run
  in a background worker; the event screen surfaces `pendingProcessing`,
  `activeJobs` and `failedPhotos` so an organiser can tell the difference
  between queued, running and dead.
- **Checkout success is not activation.** The plan and quota only change after
  the server verifies the Razorpay signature.
- **Consent is a hard gate.** The API rejects registration without it, and the
  UI states what is collected, where it is stored and when it is deleted before
  asking.
- **Billing is admin-scoped, not event-scoped.** One subscription covers every
  event an organiser owns.

### Typography

Sora ships upstream only as a variable font, so `assets/fonts/Sora-Variable.ttf`
is bundled and weights are selected with a `wght` font variation (see `AppText`
in `core/theme/app_theme.dart`). Nothing is fetched at runtime, so type renders
identically offline and on first launch.

## Platform notes

- **Identifier** — `in.facedeliver.app` on both platforms. Change it before
  shipping to your own store listings.
- **Signing** — the Android release build is still signed with the debug key
  (`android/app/build.gradle.kts`). Replace it before distributing.
- **iOS** — camera and photo-library usage descriptions are in `Info.plist`.
  Building for iOS needs a full Xcode installation.

## Not included

The superadmin console (revenue ledger, cross-tenant subscription oversight)
stays on the web. It is an internal back-office tool with no field use, so it
would only add surface area here.
