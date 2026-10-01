# Automated Play Store Releases (CI/CD)

Push a version tag → GitHub Actions builds a signed `.aab` → uploads to the
Play Console automatically. The workflow lives in
`.github/workflows/release.yml`.

## One-time setup

### 1. Create a Google Play service account (the "robot" that uploads)

This is the part only you can do — it needs your Google account.

1. **Google Cloud Console** → create (or pick) a project.
2. Enable the **Google Play Android Developer API** for that project.
   (APIs & Services → Library → search it → Enable.)
3. **IAM & Admin → Service Accounts → Create service account.**
   - Name it e.g. `play-publisher`.
   - Skip the optional role grants, click Done.
4. Open the new service account → **Keys → Add key → Create new key → JSON**.
   A `.json` file downloads. **This is `PLAY_SERVICE_ACCOUNT_JSON`.** Keep it
   secret — anyone with it can publish your app.
5. **Google Play Console** → **Users and permissions → Invite new user.**
   - Email = the service account's email (ends in
     `...iam.gserviceaccount.com`).
   - Grant **Admin (all permissions)** for this app, or at minimum:
     *Release to testing tracks* + *Release apps to production*.
   - Save. (Permission can take a little while to propagate.)

> The very first upload of a brand-new app, and the first time a service
> account uploads, sometimes must be done **manually** through the Play
> Console UI. After that the API uploads work. If the first automated run
> fails with a permissions/"app not found" error, upload one `.aab` by hand
> once, then re-run.

### 2. Add the GitHub repository secrets

Repo → **Settings → Secrets and variables → Actions → New repository secret.**
Add these five:

| Secret name                 | Value |
|-----------------------------|-------|
| `ANDROID_KEYSTORE_BASE64`   | base64 of your upload keystore (command below) |
| `KEYSTORE_PASSWORD`         | your keystore store password |
| `KEY_PASSWORD`              | your key password |
| `KEY_ALIAS`                 | `facedeliver-upload` |
| `PLAY_SERVICE_ACCOUNT_JSON` | the full contents of the JSON from step 1.4 |

Generate the keystore base64 (run locally, from the `flutter-app` folder):

```bash
base64 -i android/keystore/facedeliver-upload-key.jks | pbcopy
```

That copies the base64 string to your clipboard — paste it as the value of
`ANDROID_KEYSTORE_BASE64`.

> The real keystore and passwords live only in GitHub Secrets and on your
> machine. They are never committed — `android/key.properties`, `*.jks` and
> `*.keystore` are already in `.gitignore`.

## How to release

The workflow does **not** fire on an ordinary push to `main`. It fires on a
**version tag**, so you decide exactly which commit ships:

```bash
# after committing your changes and bumping version in pubspec.yaml
git tag v1.0.1
git push origin v1.0.1
```

Or trigger it by hand: repo → **Actions → Release to Play Store → Run
workflow**, and pick a track (`internal` / `alpha` / `beta` / `production`).

### Tracks

- `internal` — fastest, up to 100 testers. Good for closed testing.
- `alpha` / `beta` — closed/open testing tracks.
- `production` — public release.

A tag push defaults to the **internal** track. Change the default in
`release.yml` (the `track:` line) if you want.

## What the workflow does, step by step

1. Checks out the code and sets up Java 17 + Flutter 3.47.4.
2. `flutter pub get` and `flutter test` (release is blocked if tests fail).
3. Decodes the keystore from the secret and writes a CI `key.properties`.
4. `flutter build appbundle --release --dart-define-from-file=config/prod.json`
   — so the shipped app points at the production backend.
5. Saves the `.aab` as a downloadable workflow artifact (backup).
6. Uploads the `.aab` to the Play Console on the chosen track.
7. Deletes the keystore/secrets from the runner.

## Remember before each release

Bump the version in `pubspec.yaml` — the Play Store rejects a duplicate
`versionCode`:

```yaml
version: 1.0.2+3   # name+code; the +N must always increase
```
