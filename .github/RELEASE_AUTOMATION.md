# Automated Play Store Releases (CI/CD)

Push to `main` → GitHub Actions builds a signed `.aab` → saves it as a
downloadable workflow artifact. Play Console upload is prepared but disabled
until Google publishing credentials are added later. The workflow lives in
`.github/workflows/release.yml`.

## One-time setup

### 1. Create a Google Play service account (when Play upload is enabled)

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

Only the four Android signing secrets are required for build-only automation.
`PLAY_SERVICE_ACCOUNT_JSON` can be added later.

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

Merge or push a commit to `main`. No release tag is required:

```bash
git push origin main
```

Or trigger it by hand: repo → **Actions → Build Android App Bundle → Run
workflow**, and pick a track (`internal` / `alpha` / `beta` / `production`).

Each successful run has an **Artifacts** section containing
`app-release-aab`, retained for 14 days.

## Enable Play upload later

1. Add the `PLAY_SERVICE_ACCOUNT_JSON` repository secret.
2. Add an Actions repository variable named `ENABLE_PLAY_UPLOAD` with the
   value `true`.

The next `main` push will build the AAB and upload it to the selected track.

### Tracks

- `internal` — fastest, up to 100 testers. Good for closed testing.
- `alpha` / `beta` — closed/open testing tracks.
- `production` — public release.

A `main` push defaults to the active **alpha closed-testing** track. Production
cannot be selected until Google approves production access for this app. Once
approved, change the default `track` in `release.yml` from `alpha` to
`production`.

## What the workflow does, step by step

1. Checks out the code and sets up Java 17 + Flutter 3.47.4.
2. `flutter pub get` and `flutter test` (release is blocked if tests fail).
3. Decodes the keystore from the secret and writes a CI `key.properties`.
4. Builds with a unique GitHub-run-based Android `versionCode`, plus
   `--dart-define-from-file=config/prod.json`, so the app points at production
   and every upload has a higher version code.
5. Saves the `.aab` as a downloadable workflow artifact (backup).
6. Uploads the `.aab` to the Play Console on the chosen track.
7. Deletes the keystore/secrets from the runner.

## Version names

Bump the human-readable version name in `pubspec.yaml` when the product version
changes. The workflow supplies a unique build number automatically:

```yaml
version: 1.0.2+3   # the workflow overrides +N with a unique build number
```
