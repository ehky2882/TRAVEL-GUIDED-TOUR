# Automatic TestFlight builds from GitHub (CI)

**What this gives you:** whenever you want to test a change, a Mac in GitHub's cloud
builds + signs the app and uploads it to TestFlight — so a testable version shows up on
your phone with no Mac needed from you. It's what lets a web session (Claude) build app
features that you then review on-device.

The automation lives in [`.github/workflows/testflight.yml`](../.github/workflows/testflight.yml).

## One-time setup (owner — ~10 minutes, dashboard only)

### Part A — create Apple's "pass" (App Store Connect API key)
1. Go to **appstoreconnect.apple.com** → **Users and Access** → the **Integrations** tab
   (top) → **App Store Connect API**.
2. Click the **＋** to generate a new key.
   - **Name:** `GitHub CI`
   - **Access:** **App Manager** (enough to upload builds + auto-manage signing).
3. Click **Generate**, then **Download** the key file (`AuthKey_XXXXXXXX.p8`).
   ⚠️ **You can only download it once — save it somewhere safe.**
4. On that same Keys page, note two IDs:
   - the **Key ID** (shown next to your new key, ~10 characters), and
   - the **Issuer ID** (shown near the top of the page, a long UUID).

### Part B — paste 3 secrets into GitHub
Repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**,
three times:

| Secret name | Value |
|---|---|
| `APP_STORE_CONNECT_KEY_ID` | the **Key ID** from step A4 |
| `APP_STORE_CONNECT_ISSUER_ID` | the **Issuer ID** from step A4 |
| `APP_STORE_CONNECT_API_KEY` | open `AuthKey_XXXX.p8` in TextEdit, **Select All → Copy**, paste the whole thing (including the `-----BEGIN…` / `-----END…` lines) |

> These are write credentials — keep them only in GitHub secrets, never in the repo/app.

### Part C — make the trigger label (once)
Repo → **Issues** or **Pull requests** → **Labels** → **New label** → name it exactly
**`build`**. (Or it's created automatically the first time you apply it.)

## Build notes are required (never ship a mystery build)
Every build must carry notes so the owner knows what it is and what to try. When you
**Run workflow**, fill the **Build notes** box with two short sections:

```
What changed:
- <feature / fix in this build, plain English>

What to test:
- <concrete on-device step>
- <anything device-only, e.g. "needs 2 phones for group sync">
```

The notes show in the Actions run's **job summary** and the final log line. Claude also
posts them in chat and (if a PR exists) in the PR body. This is CLAUDE.md automation rule #9.
_(Future enhancement: push these straight into TestFlight's "What to Test" field via the App
Store Connect API — needs a validation build to wire up.)_

## How to get a build after that
Either:
- Add the **`build`** label to any pull request (notes come from the PR body), **or**
- **Actions** tab → **TestFlight build** → **Run workflow** → fill **Build notes** → Run.

Then wait: the build takes ~10–15 min, then Apple processes it for a few more minutes, and
it appears in the **TestFlight** app on your phone (you're an internal tester, so no beta
review). Every build stacks up under **Previous Builds** — install/switch between them
freely (one at a time per phone).

## Notes / gotchas
- **Cost:** Mac build minutes bill ~10× Linux, so builds run **on demand only**, never on
  every push.
- **First run may need a small fix.** iOS signing-in-CI is finicky; if the first build
  fails, the error in the Actions log usually points right at it (often a signing/role
  detail), and it's a quick tweak.
- **Which build is which:** builds are numbered by timestamp (`1.0 (2026…)`). Labelling each
  build with its PR number in the TestFlight "What to Test" notes is an easy follow-up (needs
  a small extra upload step / fastlane) — not in v1.
- The existing simulator CI (`ci.yml`) is unchanged; this is a separate, opt-in workflow.
