# Troubleshooting — Xcode + git landmines

Recurring incidents this project has hit, with prevention and recovery
for each. Read this before opening Xcode at the start of a session, or
when something inexplicable happens mid-rebase. Add to this file
whenever a new landmine bites.

---

## 1. "Why doesn't my simulator reflect last night's work?"

**Symptom.** You build + run the app, and changes you remember making
aren't there. The simulator looks like an older version of `main`.

**Cause.** Work was on a feature branch (or parked branch) that never
got merged — you're now running off `main`, which is behind. Easy to
forget across nights/sessions.

**Prevention.**
- End every session by either merging your work via PR or pushing the
  branch to origin and noting it in `archive/HANDOFF-YYMMDD.md`.
- Don't leave parked branches lingering. Either revive within ~1 week
  or extract the useful pieces and delete.
- Use the session-start ritual in `CLAUDE.md` § "Session-start
  ritual" before opening Xcode.

**Recovery.**
```bash
git branch -a                       # what branches exist?
git log --oneline --all --graph -20 # where's the work hiding?
git checkout claude/<branch-name>   # switch to it before building
```
If the branch is stale against `main`, rebase before building so you
don't see old behavior:
```bash
git rebase main
```

---

## 2. Rebase fails with "would be overwritten by checkout" despite a clean working tree

**Symptom.** `git status` says nothing's modified, but `git rebase`,
`git checkout`, or `git pull` refuses with:
> error: Your local changes to the following files would be overwritten
> by checkout: <path>. Please commit your changes or stash them.

**Cause.** Xcode is open and holding file handles on
`project.pbxproj`, Swift sources, or derived-data state. Git sees the
locked handles as "uncommitted changes" even when the file content
matches HEAD.

**Prevention.** Quit Xcode (Cmd-Q, not just close window) before any
non-trivial git operation: rebase, branch checkout, pull with merges.

**Recovery (Xcode still open and you don't want to quit).**
```bash
git stash --include-untracked    # often prints "No local changes to
                                 # save" but releases the lock anyway
git rebase main                  # now succeeds
git stash pop                    # usually a no-op
```

If that doesn't work, fully quit Xcode and retry.

---

## 3. Phantom `xcodeproj` directory at a nested path

**Symptom.** Xcode shows a confusing dialog about "saving" or
"re-saving" the workspace at a different location. You click through.
Later, you find an empty `.xcodeproj` directory at a nested path like
`~/Desktop/TRAVEL GUIDED TOUR/TRAVEL GUIDED TOUR/TRAVEL GUIDED TOUR.xcodeproj/`
that contains only `project.xcworkspace/` (no `project.pbxproj`).
Two `TRAVEL GUIDED TOUR` entries appear in Xcode's File → Open Recent.

**Cause.** Some Xcode dialogs (workspace re-save, "Convert to current
project format", certain refactor flows) silently create a new
project bundle at the location you accept in the save panel. If the
default path is wrong (Xcode often picks the working directory
inside the source folder, not the repo root), you get a phantom
sibling.

**Prevention.**
- When Xcode shows a "save as" or "re-save" dialog, **read the path
  before clicking**. The only valid xcodeproj is the canonical one at
  the repo root: `~/Desktop/TRAVEL GUIDED TOUR/TRAVEL GUIDED TOUR.xcodeproj/`.
- If the dialog wants to write anywhere else, **cancel**, then ask
  what's actually being requested before retrying.

**Recovery.**
```bash
# Verify the canonical xcodeproj exists and has its pbxproj:
ls -la "TRAVEL GUIDED TOUR.xcodeproj/"
# Should show: project.pbxproj + project.xcworkspace/ + xcshareddata/

# Find phantom xcodeprojs:
find . -maxdepth 4 -name "*.xcodeproj" -not -path "./.git/*"
# Should show only one. Delete any others:
rm -rf "<path-to-phantom-xcodeproj>"

# Clear Xcode's Recents (Xcode → File → Open Recent → Clear Menu),
# then File → Open... at the canonical path.
```

---

## 4. `git pull` after `gh pr merge --squash --delete-branch` fails with HEAD.lock

**Symptom.** Right after running `gh pr merge --squash --delete-branch`,
`git pull` (or any other write op) fails with:
> fatal: cannot lock ref 'HEAD': Unable to create '.git/HEAD.lock':
> File exists.

**Cause.** `gh pr merge` runs as a background process that holds
`.git/HEAD.lock` while it switches local checkout away from the deleted
branch. If you `git pull` immediately, gh is still finishing.

**Prevention.** Wait for the gh command to fully exit before running
any other git command in the same repo. (When running gh in the
background via the Bash tool with `run_in_background: true`, wait for
the completion notification.)

**Recovery.**
```bash
ps aux | grep -E "gh|git" | grep -v grep   # confirm no gh process running
rm -f .git/HEAD.lock                       # safe ONLY when no process is running
git pull --ff-only
```
Never delete `HEAD.lock` while a git or gh process is still alive — it
can corrupt refs.

---

## 5. Parked branch goes stale against `main`

**Symptom.** You return to a feature branch after `main` has had
several PRs merged. Rebase produces conflicts in files you didn't
even touch on your branch.

**Cause.** The same files were edited on both `main` (via merged PRs)
and your parked branch. The longer a branch sits unmerged, the more
likely this is.

**Prevention.**
- **Don't park branches for design-direction commitments any longer
  than necessary.** The 2026-05-18 AllTrails branch sat ~2 days and
  hit a `HomeView.swift` conflict from PR #23's intervening navigation
  fix. Tolerable, but it would have been worse at 2 weeks.
- If you must park, document on the branch what's unique to it (so
  if rebase becomes hostile, you can extract the unique commits and
  abandon the rebase). Record in `ROADMAP.md` § "Parked work" with
  the branch name and the date it was parked.

**Recovery.**
```bash
git fetch origin
git checkout claude/<branch-name>
git rebase main                            # resolve conflicts as they come
# If rebase becomes unworkable, abandon and cherry-pick:
git rebase --abort
git log <branch-name> --oneline            # find the unique commits
git checkout -b claude/<new-branch> main
git cherry-pick <hash1> <hash2> ...        # bring just the work
```

---

## 6. Audio "CANNOT OPEN" on a tour that should play

**Symptom.** Tour plays the silent placeholder ("Atlas Sample Audio…")
or fails with "Cannot open" in AVPlayer. Stop has a real audio URL.

**Cause.** GitHub Releases serves binary assets with
`Content-Type: application/octet-stream` (via a redirect with
`rsct=application%2Foctet-stream` in the signed URL's query). AVPlayer
refuses to open a stream that isn't MIME-typed as audio.

**Prevention.** Host V1 audio on the `gh-pages` branch (Pages serves
`.mp3` with `Content-Type: audio/mp3`), not on GitHub Releases. See
`docs/cdn-decision.md` for the full rationale.

**Recovery.**
1. Verify the MIME type: `curl -sI <audio-url> | grep -i content-type`.
   Should be `audio/mp3` (Pages) or `audio/mpeg`. If `application/octet-stream`,
   move the file to Pages.
2. Push the audio to `gh-pages` and update `Resources/Tours.json` to
   the Pages URL (`https://<user>.github.io/<repo>/audio/<file>.mp3`).

---

## 7. CI test job: "Unable to find a device matching the provided destination specifier"

**Symptom.** The `Run unit tests` job on GitHub Actions fails with:
> xcodebuild: error: Unable to find a device matching the provided
> destination specifier: { platform:iOS Simulator, OS:latest, name:iPhone 16 }
>
> Available destinations for the "TRAVEL GUIDED TOUR" scheme:
>     { platform:macOS, … }
>     { platform:iOS, id:dvtdevice-DVTiPhonePlaceholder-iphoneos:placeholder, name:Any iOS Device }
>     { platform:iOS Simulator, id:dvtdevice-…-iphonesimulator:placeholder, name:Any iOS Simulator Device }

…with no concrete iOS Simulator devices in the available list. Build
job passes (it uses the abstract `generic/platform=iOS Simulator`,
which works for `build` but not `test`).

**Cause.** GitHub Actions runner-pool variance. Some `macos-latest`
runners come with pre-created iPhone simulators ready to use, others
have only Xcode + iOS runtimes installed and no concrete devices.
On the latter, a name-based destination (`name=iPhone 16`) matches
nothing — there's no device with that name, just the abstract
placeholder. PR #33 / #34 ran on the lucky runners; PR #35 didn't.

**Prevention.** Don't depend on pre-created simulators. The workflow
now explicitly creates + boots a simulator at the start of the test
job (`.github/workflows/ci.yml` → "Prepare iOS simulator" step), so
the state is the same regardless of which runner image we get.

**Recovery (if this regresses).** Re-run the failed job once — you
might get a different runner with concrete devices. If it keeps
failing, check that the "Prepare iOS simulator" step exists and is
running. If iOS runtimes themselves are missing on the runner
(unlikely but possible during Xcode major-version transitions),
that's a separate problem — pin to a specific `macos-X` runner
image until the latest stabilizes.

---

## When to add to this doc

Add a new section here when the same incident bites twice, or when
recovery took more than 10 minutes the first time. Keep each section
short (symptom → cause → prevention → recovery). Cross-link to
relevant ROADMAP sections or other docs instead of duplicating.
