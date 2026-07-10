# APK releases (GitHub Actions)

| Repository | Role |
|------------|------|
| [solendav/PurchaseJournal](https://github.com/solendav/PurchaseJournal) | Source code + CI workflow |
| [solendav/PurchaseJournal-apk](https://github.com/solendav/PurchaseJournal-apk) | Public APK downloads |

## One-time setup (source repo secrets)

In **PurchaseJournal** → Settings → Secrets and variables → Actions:

| Secret | Value |
|--------|--------|
| `RELEASES_REPO` | `solendav/PurchaseJournal-apk` |
| `RELEASES_REPO_TOKEN` | GitHub PAT with `contents:write` on the APK repo |
| `DART_DEFINES_PROD_JSON` | `{"API_BASE_URL":"https://purchase-journal-backend.vercel.app/"}` |

## Trigger a build

**Option A — tag push**

```bash
git tag v1.0.0
git push origin v1.0.0
```

**Option B — manual**

Actions → **Release APK** → Run workflow

## Download URL pattern

```
https://github.com/solendav/PurchaseJournal-apk/releases/download/v1.0.0/purchasejournal.apk
```
