# Option 4: Source repo + public APK releases

| Repo | Purpose |
|------|---------|
| [solendav/PurchaseJournal](https://github.com/solendav/PurchaseJournal) | Full source (mobile + backend) |
| [solendav/PurchaseJournal-apk](https://github.com/solendav/PurchaseJournal-apk) | Public APK downloads only (`purchasejournal.apk`) |

GitHub Actions in the source repo builds the APK and uploads it to a release on the public repo.

## One-time setup

### 1. Public releases repo

Use [solendav/PurchaseJournal-apk](https://github.com/solendav/PurchaseJournal-apk).

The repo can start empty — the Release APK workflow seeds a README automatically before the first release.

### 2. Create a token that can write releases

1. GitHub → **Settings** → **Developer settings** → **Personal access tokens**
2. Prefer a **fine-grained** token:
   - Repository access: **Only select repositories** → `PurchaseJournal-apk`
   - Permissions → Repository → **Contents: Read and write**
3. Copy the token (shown once)

### 3. Add secrets on the source repo

In **PurchaseJournal** → **Settings** → **Secrets and variables** → **Actions**:

| Secret | Value |
|--------|--------|
| `RELEASES_REPO` | `solendav/PurchaseJournal-apk` |
| `RELEASES_REPO_TOKEN` | the token from step 2 |
| `DART_DEFINES_PROD_JSON` | *(recommended)* full JSON copied from `mobile/dart_defines.prod.json.example` |

The workflow always injects `GITHUB_REPO` from `RELEASES_REPO` so in-app updates hit the public repo.

## Publish a release

The workflow builds the **commit that triggered it**, not always the latest `main`. If a tag was created before ML Kit was removed, create a new tag on the latest commit.

### Automated (recommended)

```bash
git pull origin main
git tag v1.0.1
git push origin v1.0.1
```

Or: **Actions** → **Release APK** → **Run workflow** → branch **main**.

Download URL after publish:

```
https://github.com/solendav/PurchaseJournal-apk/releases/download/v1.0.1/purchasejournal.apk
```

### Manual fallback

```bash
cd mobile && flutter build apk --release --dart-define-from-file=dart_defines.prod.json
```

Copy `build/app/outputs/flutter-apk/app-release.apk` → `purchasejournal.apk` and upload to GitHub Releases.

Do **not** commit APKs into either git repo.

## In-app updates

The app can call:

```
https://api.github.com/repos/solendav/PurchaseJournal-apk/releases/latest
```

Default is set in `AppEnv.githubRepo` / `dart_defines.prod.json` (`GITHUB_REPO`). Keep the releases repo **public**.
