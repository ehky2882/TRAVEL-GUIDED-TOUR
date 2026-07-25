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

**The notes are attached to the build in TestFlight itself** (since 2026-07-25): after the
upload, the workflow waits for Apple to finish processing and writes the notes into the
build's **"What to Test"** field, using fastlane **`upload_to_testflight` with
`distribute_only: true`** and the same API key. So in the TestFlight app on your phone, tap
any build and the description of what changed + what to test is right there — no more
mystery builds. If no notes were typed into the Run-workflow box, the workflow falls back to
the **PR title + body** (label trigger), then to the commit subject, so the field is never
blank. Notes also show in the Actions run's **job summary** and the final log line, and
Claude posts them in chat and (if a PR exists) in the PR body. This is CLAUDE.md automation
rule #9.

> ⚠️ **Two traps here, both already paid for. Don't re-enter them.**
>
> 1. **Do not switch this to `set_changelog`.** It targets the *App Store version's* release
>    notes and rejects `build_number` outright (*"Could not find option 'build_number'"*), so
>    it cannot address a specific TestFlight build. `upload_to_testflight` with
>    `distribute_only: true` is the documented path. (Cost: build 1.1 (36) shipped blank.)
> 2. **`app_platform: "ios"` is mandatory, not optional.** The docs call it optional, but
>    without it pilot *prompts* — *"Please enter the app's platform"* — and CI cannot answer,
>    so it dies instantly with *"Could not retrieve response as fastlane runs in
>    non-interactive mode."* (Cost: builds 1.1 (39) and (40) shipped blank.)

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
- **Apple certificate cap — now handled automatically (no owner action).** Archives used to
  fail fast (~40s) with *"Your account has reached the maximum number of certificates … No
  profiles for 'com.ehky.TRAVEL-GUIDED-TOUR' were found"*, and the owner had to manually
  revoke **Apple Development** certs in the developer portal before every few builds. Cause:
  cloud signing mints a **new Apple Development cert per build machine**, and every CI run is
  a fresh throwaway cloud Mac — so they accumulated to Apple's cap. The workflow now has a
  **"Free up Apple Development certificate slots"** step that uses the same App Store Connect
  API key to revoke DEVELOPMENT certs before archiving; automatic signing then regenerates
  just the one it needs. Distribution certs (the App Store upload identity) are never touched,
  and the step is `continue-on-error` so an API hiccup can't block a build. **Verified
  2026-07-24:** two archives had failed at the cap; with this step the next archive signed and
  uploaded cleanly (build 1.1 (35)).
  - *Dead end for reference:* forcing `CODE_SIGN_IDENTITY="Apple Distribution"` on the archive
    does **not** work — the project uses automatic signing, so Xcode errors with *"conflicting
    provisioning settings … switch to manual signing"* (and SPM deps then demand a dev team).
    Manual signing would require storing a cert + profile as secrets; the auto-revoke step
    achieves the same durability with no stored credentials.
- **First run may need a small fix.** iOS signing-in-CI is finicky; if the first build
  fails, the error in the Actions log usually points right at it (often a signing/role
  detail), and it's a quick tweak.
- **Which build is which:** every build carries its notes in TestFlight's "What to Test"
  field (see the Build-notes section above) — tap the build in the TestFlight app to read
  what's in it. Label-triggered builds are stamped with their PR number automatically.
- **The notes step can take a while:** after the upload, the workflow polls up to ~20 min
  for Apple to finish processing the build before it can attach the notes.
- **If notes ever go missing again, read the run's "Set TestFlight What to Test notes"
  step.** It now distinguishes the two failure modes instead of blurring them: a
  *configuration* error (bad parameter, bad credentials, wrong app) **stops immediately**
  and prints the real fastlane error as a red `::error::` annotation, while only a
  genuine *"build not processed yet"* condition is retried. The **Done** step then says
  explicitly whether the notes were attached. The run stays green either way — the build
  itself is already uploaded and installable — so **a green run does not by itself mean the
  notes landed**; check the Done line or the job summary.
  - **The classifier defaults to PERMANENT on purpose.** A wrong "permanent" call costs
    nothing — the step stops and prints the real error. A wrong "retryable" call hides that
    error for 20 minutes behind a false "Apple is still processing" message. That mistake
    has now been made twice: first by retrying *every* error (build 36), then by matching
    the bare word `processing`, which appears in fastlane's **own option list**
    (`skip_waiting_for_build_processing`) — so a permanent crash looked transient again
    (builds 39, 40). Match only on precise phrases; never on a word that can occur in help
    text.
- The existing simulator CI (`ci.yml`) is unchanged; this is a separate, opt-in workflow.
