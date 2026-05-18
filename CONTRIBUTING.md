# Contributing to Atlas

Atlas is a creator platform for GPS-anchored audio tours, built as a
multi-platform SwiftUI app for iPhone, iPad, Mac, and Apple Vision
Pro. If you're reading this, someone's pointed you at the codebase —
welcome.

This doc covers what you need on your machine to work on Atlas and
how changes land in `main`. For *what* Atlas is and *why*, the
canonical product spec is `atlas_claude_code_prompt.md` at repo root.

## First, read these (in order)

1. **`atlas_claude_code_prompt.md`** — the product spec. What Atlas
   is, who it's for, what V1 includes (and explicitly doesn't).
2. **`CLAUDE.md`** — the project's working notes: current state,
   architecture, conventions, what's shipped, what isn't.
3. **`ROADMAP.md`** — the milestone history and what's left for V1.
4. **`docs/authoring-tours.md`** — field-by-field guide to the tour
   data model. Even if you're not authoring content yourself,
   reading it grounds you in the data the app moves around.
5. **`docs/cdn-decision.md`** — open decision on audio hosting;
   relevant background if you're touching the audio playback or
   download paths.

Plan an hour for this on day one. The docs are written in plain
English with technical-term-in-parentheses analogies — read them
top to bottom, don't skim.

## What you'll need on your machine

### To write Swift / build the app

- **A Mac.** Apple Silicon (M1 or newer) ideal; Intel still works.
  iOS development is macOS-only — no Windows or Linux path exists.
- **macOS 26.2 or newer.**
- **Xcode 26** from the Mac App Store (~15GB download).
- **iOS 26.2 simulator runtime** (Xcode → Settings → Platforms;
  ~7GB download).
- **An Apple ID** signed into Xcode for code signing.
- **Apple Developer Program team access** to run on real devices
  or push to TestFlight. Ask the project owner to invite you to
  the team via App Store Connect — costs you nothing extra.

### To author tour content (record audio, write scripts)

- An audio recording setup: a USB microphone (Shure MV7, Blue
  Yeti, or similar) or a phone with the Ferrite app and a
  clip-on lavalier. A quiet room with soft furniture.
- An audio editor: GarageBand (free, Mac-only), Audacity (free,
  cross-platform), or Reaper (~$60, pro).
- Access to the shared asset folder for delivering masters and
  raw recordings — ask the project owner.

### To design (visuals, UX)

- A Figma account (free tier is enough for a single designer).
- An iPhone or iPad for on-device QA of visual work.
- Familiarity with Apple's Human Interface Guidelines (Apple's
  design source-of-truth doc).

## Branching & PRs

- `main` is protected — direct pushes are blocked.
- Work on a feature branch off `main`. Naming convention:
  - `claude/<short-description>` for Claude-driven work.
  - `<your-github-handle>/<short-description>` for human-driven work.
- Open a PR when ready; get one review; merge.
- **Keep PRs scoped.** One focused change reviews fast and lands
  fast. A sprawling refactor stalls.
- Commit messages: imperative mood, focus on *why* over *what*.
  Examples in `git log` once you clone.

## Building & running

```bash
# Build for macOS
xcodebuild -scheme "TRAVEL GUIDED TOUR" -configuration Debug build

# Build for iOS Simulator
xcodebuild -scheme "TRAVEL GUIDED TOUR" -destination "generic/platform=iOS Simulator" build
```

Or just open `TRAVEL GUIDED TOUR.xcodeproj` in Xcode and hit Run.

No test targets are configured yet.

## Before committing edits to `Tours.json`

Run the validator:

```bash
swift scripts/validate-tours.swift
```

It catches typos, missing fields, duplicate UUIDs, broken maker
references, and a dozen other things that would otherwise crash
the app at launch. Exit 0 = clean, 1 = errors, 2 = unparseable.
Full details in `docs/authoring-tours.md`.

For a belt-and-braces auto-validation, add a git pre-commit hook:

```bash
echo 'exec swift scripts/validate-tours.swift' > .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

## Code conventions

`CLAUDE.md`'s **Conventions** section is the source of truth:
`@Observable` not `ObservableObject`, `NavigationStack` not
`NavigationView`, `HeroImageView` for hero images, Apple
frameworks only (no third-party libraries in V1), audio playback
always via `AudioPlayerService`, Dynamic Type + Dark Mode support
on every screen. Read it before writing UI code.

For data model changes: if you touch `Tour.swift`, `Stop.swift`,
`Maker.swift`, or `TourCategory.swift`, update the mirror types
at the top of `scripts/validate-tours.swift` in the **same commit**.
The script's drift is a foot-gun otherwise.

## Documentation discipline

`CLAUDE.md` and `ROADMAP.md` are read at the start of every Claude
Code session. If your change makes either of them inaccurate —
ships a milestone, cuts scope, changes the on-disk folder layout —
update them in the **same commit** as the code. Stale docs poison
future sessions. The rule is documented in `CLAUDE.md`'s "Keep
these docs in sync" section.

Temporary session-bridge notes don't belong at repo root. If a
working session produces one, fold the permanent content into
`CLAUDE.md` / `ROADMAP.md` and archive the snapshot to `archive/`
with a `YYMMDD` date suffix.

## Communication

- **Async first.** Decisions written in PR descriptions and issue
  threads. Lets work happen across time zones.
- **Sync when needed.** Cadence is up to you and the project
  owner.
- **When in doubt, ask in a PR comment.** A two-line "I'm
  thinking about doing X — does that match your intent?" beats
  building the wrong thing for a week.
