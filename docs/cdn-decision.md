# CDN decision brief — where does Atlas host its audio?

> **Status:** decision pending; brief written 2026-05-18.
> When you make the decision, replace the "Status" line with the
> picked option + date, and the brief stays as the record of *why*.

## TL;DR — my recommendation: **Cloudflare R2**

Pick Cloudflare R2 for V1 audio hosting. It's the cheapest at every
scale Atlas might plausibly hit, the setup is manageable for one
person in an afternoon, and — most importantly — it removes the
"what if Atlas goes viral and the hosting bill bankrupts me" tail
risk that haunts every content app on AWS.

If you'd rather not deal with any hosting service at all and you're
fine shipping new audio as App Store updates, **Apple On-Demand
Resources** is a strong runner-up. Don't pick AWS S3 + CloudFront
unless you already have AWS expertise — the complexity-to-benefit
ratio is bad at this size.

---

## The decision, in plain English

Every audio clip Atlas plays lives as an MP3 file (MP3 = the standard
spoken-audio file format — like a Word doc, but for audio) on a
server somewhere on the internet. The app's `Tours.json` has URLs
that point at those files. When someone presses Play, the app
fetches the file from that URL over the network and plays it.

Right now those URLs are placeholders — `https://atlas-tours.example/...`
which doesn't resolve to anything. To ship V1 content for real, you
have to:

1. **Pick a hosting service** — *this brief.*
2. **Sign up and set it up** — varies; see "Setup complexity" below.
3. **Upload the recorded MP3s** to that service.
4. **Replace the placeholder URLs** in `Tours.json` with the real
   URLs the service gives you.

A **CDN** ("Content Delivery Network" — think: a chain of audio-file
warehouses around the world, so a listener in Tokyo doesn't wait for
the file to travel from a single server in Virginia) is the kind of
service that's good at step 1. The decision is which one.

## Atlas at V1, in numbers

So the cost math makes sense, let's pin down rough scale.

- **Files per tour:** 1 audio clip per stop, plus optional intro.
  Single-piece tour = 1 file. 5-stop walking tour = 5–6 files.
- **File size:** 128kbps MP3 mono is plenty for spoken audio
  (~1MB per minute). A 5-minute stop ≈ 5MB.
- **Catalog size at V1:** 5–15 tours × 20 minutes average ≈ 100–300MB
  of audio total. Tiny by any modern standard.
- **Listener downloads:** unknowable pre-launch. Could be 50/month
  (friends + small launch), could be 5,000/month (one decent press
  hit). The hosting bill scales with this; one number to know is
  that a listener who downloads a full 20-minute tour pulls roughly
  20MB.

I'll quote three listener scenarios in the cost table below:
**100/month** (tiny launch), **1,000/month** (modest traction),
**10,000/month** (good month, post-press).

## The three options

### 1. Cloudflare R2

**What it is.** Cloudflare's storage service. You create a "bucket"
(a folder in the cloud), upload MP3s into it, and they become
accessible via HTTPS URLs.

**The signature feature:** Cloudflare charges $0 for egress
("egress" = data leaving the service when a listener downloads a
file). Every other major hosting service charges per gigabyte
downloaded. For a content business with unknown traffic, this is
genuinely game-changing — your hosting cost stops scaling with
success.

**Costs (current pricing — verify before signing up):**
- Storage: $0.015 per GB per month. Atlas at 300MB = $0.0045/month.
- Egress: $0, regardless of how much gets downloaded.
- Operations (each download is one "Class B operation"): $0.36 per
  million. You'd hit thousands of operations a month at V1 scale,
  so effectively zero.

**Setup work:** Sign up for a Cloudflare account, create an R2
bucket, optionally point a custom domain at it (e.g.
`audio.atlas.app`) — Cloudflare gives you SSL automatically. Upload
files via the web dashboard or `rclone` (a free file-sync tool).
Half a day, start to finish, if it's your first time.

**Watch-outs:** R2 is younger than S3 (launched 2022) so there's
less StackOverflow history when something goes wrong. In practice
it's been stable. Single-vendor risk if Cloudflare has a bad
outage day — but that risk is shared by every option here.

### 2. AWS S3 + CloudFront

**What it is.** Amazon's storage service (S3) is the industry
default for static files; CloudFront is Amazon's CDN layered on top
to make downloads fast worldwide.

**Costs (current pricing — verify):**
- S3 storage: $0.023 per GB per month. Atlas at 300MB ≈ $0.007/month.
- CloudFront egress: ~$0.085 per GB for the first 10TB/month (US/EU
  regions; higher in Asia/SA). **This is the cost concern.**
- A grab-bag of small operations charges.

**Setup work:** AWS account, S3 bucket with the right access
policies, CloudFront distribution pointing at the bucket, an
"Origin Access Control" so people can only reach files via
CloudFront (not S3 directly), an SSL certificate via ACM, DNS
configuration on your domain. Realistically a full day's work for
someone unfamiliar with AWS. The AWS console is the opposite of
welcoming.

**Watch-outs:** AWS bills can surprise you. If a tour goes viral
and you haven't set up billing alerts, you can wake up to a $500
bill. This is the single biggest risk for a solo operator. The
remedy is setting up billing alarms during setup, which adds to
the complexity.

### 3. Apple On-Demand Resources (ODR)

**What it is.** A built-in Apple feature where audio files ship
with the app itself — you "tag" each file in the Xcode project,
upload them to App Store Connect along with the app, and Apple
serves them on demand to listeners via Apple's own CDN.
**The audio doesn't live on a separate hosting service at all.**

**Costs:** $0/month. Apple eats the hosting cost as part of App
Store distribution.

**Setup work:** Easy on the technical side — just tag files in
Xcode and ship. But there's a workflow cost: see "Watch-outs."

**Watch-outs (the real ones):**
- **App Store review cycle for every new tour.** ODR files only
  update when you ship a new app version. Want to add a new walking
  tour next Tuesday? You ship a new build and wait 1–2 days for
  Apple to approve it. No trickle-launching content; no quickly
  fixing a mispronounced word in an audio clip.
- **iOS-only.** Files are only accessible inside the app, on Apple
  devices. If post-V1 you want to share a tour preview as a web
  link, run a marketing site that plays clips, or eventually
  release an Android version — those audio files have to be
  re-hosted somewhere else anyway.
- **Size limits.** Currently 20GB total per app, 512MB per "tag."
  Atlas at V1 is comfortably under both, but a future of 200 tours
  could approach them.

### 4. Firebase Storage (Google Cloud Storage with Firebase tooling)

**What it is.** Google Cloud Storage under the hood with Firebase's
friendlier SDK and dashboard on top.

**Costs (current pricing — verify):**
- Storage: $0.026 per GB per month (close to S3).
- Egress: $0.12 per GB after a small free tier (1GB/day free
  download). At Atlas's 1k-listener scale (~666MB/day on average),
  you stay in the free tier; at 10k listeners (~6.6GB/day) you
  pay for ~5.6GB/day overage.
- A small grab-bag of per-operation charges.

**Setup work:** Create a Firebase project, enable Cloud Storage,
configure security rules so files are publicly readable, upload via
the web dashboard. Maybe 2–3 hours first time. Easier than AWS;
slightly more involved than R2 (security rules are a real concept
to learn).

**Watch-outs:** Pricing follows the same curve as S3+CloudFront —
download fees scale with success. Vendor lock-in to the Google
ecosystem. Security-rules language is a learning curve if Atlas
ever wants per-user access (post-V1).

**No reason to pick this over R2 specifically** unless you already
use Firebase for other things (Auth, Firestore, etc.) and want to
keep everything in one console.

### 5. Supabase Storage

**What it is.** Supabase is a Postgres-backed Backend-as-a-Service
(think open-source Firebase alternative). Their storage product
sits alongside their database, auth, and edge functions, sharing
one project + dashboard.

**Costs (current pricing — verify):**
- Free tier: 1GB storage + 5GB bandwidth/month. Atlas's V1 scale
  fits comfortably.
- Pro plan: **$25/month minimum**, includes 100GB storage + 250GB
  bandwidth. Egress over 250GB/month is ~$0.09/GB.

**Setup work:** Create a Supabase project, create a storage bucket,
set policies, upload via the dashboard. Comparable to Firebase —
maybe 2–3 hours first time.

**Watch-outs:** Supabase's value proposition is the *bundle* —
database + auth + edge functions + storage. If you're only using
the storage piece, you're either paying for capabilities you don't
need (Pro plan) or hitting free-tier limits quickly. The Pro plan
becomes *good* value the moment Atlas adds a backend (post-V1 maker
dashboard, user accounts). For V1 storage-only it's overspend.

**Worth reconsidering when** Atlas decides it needs a real backend
— Supabase's all-in-one positioning makes it attractive as a single
vendor at that point.

### 6. Apple CloudKit Assets

**What it is.** CloudKit is Apple's developer-platform database +
storage service. Different from iCloud Drive (consumer file
storage, which can't serve direct MP3 URLs). CloudKit Assets are
binary blobs attached to records in your app's CloudKit container —
the iOS app fetches them via the CloudKit SDK.

**Costs:** $0 forever — Apple absorbs the hosting cost for any app
in the Apple Developer Program. Atlas's catalog size is many orders
of magnitude under the free quota.

**Setup work:** Medium. CloudKit Assets aren't plain HTTPS URLs —
they're `CKAsset` references, accessed via the CloudKit SDK. Atlas's
current player and downloader expect `URL` strings; switching to
CloudKit would mean modifying `AudioPlayerService`, `TourDownloader`,
and the `Tour`/`Stop` data model. A real day's work, not a paste-in.

**Watch-outs:**
- **iOS-only (and macOS / visionOS — anything in Apple's ecosystem).**
  No web access, no Android, no shared tour links that open in a
  browser. Same constraint as ODR, just without the App Store
  review cadence (CloudKit content can update independently — this
  is its key advantage over ODR).
- **CloudKit Web Services exists** but requires server-to-server
  auth tokens, making it impractical for public content.
- **More code to maintain** — every additional layer is a
  maintenance surface.

**Worth reconsidering when** Atlas commits to iOS-only forever and
you want truly zero infrastructure cost. The code overhead is the
price.

### (Not in the running, but worth naming)

- **GitHub LFS** — Git's large-file feature, served via raw URLs.
  Bandwidth-capped, slow as a download target, against GitHub's
  ToS at production scale. Don't.
- **iCloud Drive** (consumer) — different from CloudKit Assets.
  Shared links wrap files in HTML download pages; AVPlayer can't
  resolve them. Not usable for app audio.
- **Your own VPS (a rented server)** — possible but you become the
  sysadmin. A trap for solo operators.

---

## Costs side-by-side at four traffic levels

Assuming 300MB catalog, average listener downloads 20MB (one tour):

| Listeners/month | Egress | R2 | S3 + CloudFront | ODR | Firebase | Supabase | CloudKit |
|---|---|---|---|---|---|---|---|
| 100 (launch friends) | 2 GB | ~$0 | ~$0.20 | $0 | $0 (free tier) | $0 (free tier) | $0 |
| 1,000 (modest)       | 20 GB | ~$0 | ~$2 | $0 | $0 (free tier) | $0 (free tier) | $0 |
| 10,000 (good month)  | 200 GB | ~$0 | ~$17 | $0 | ~$20 | $25 (Pro plan) | $0 |
| 100,000 (viral hit)  | 2 TB | ~$0 | ~$170 | $0 | ~$240 | $25 + ~$160 overage | $0 |

R2 and CloudKit stay flat with success. ODR is also flat but
constrained by App Store cadence. S3+CF and Firebase scale
linearly. Supabase has a soft floor ($25 Pro plan) once you exceed
the small free tier.

## Capabilities side-by-side

| Option | Setup | Public HTTPS URLs anywhere | Update without App Store | Code changes needed | Best fit when |
|---|---|---|---|---|---|
| **Cloudflare R2** ⭐ | Easy (half-day) | ✅ | ✅ | None | Default for content with unknowable traffic |
| AWS S3 + CloudFront | Hard (full day) | ✅ | ✅ | None | You already have AWS expertise |
| Apple ODR | Easy (Xcode-only) | ❌ iOS-only | ❌ tied to App Store | None | iOS-only forever, infrequent updates |
| Firebase Storage | Easy (~3 hrs) | ✅ | ✅ | None | You already use Firebase for other things |
| Supabase Storage | Easy (~3 hrs) | ✅ | ✅ | None | You also need database + auth + edge functions |
| CloudKit Assets | Medium (SDK code) | ❌ iOS-only | ✅ (advantage over ODR) | Real changes | iOS-only forever, willing to write CloudKit code |

---

## Setup complexity, ranked

1. **ODR** — easiest. ~1 hour. Drag files into Xcode, configure
   tags, ship. The cost is paid later in the App Store review cycle.
2. **Firebase / Supabase** — easy. ~2–3 hours. Friendly web
   dashboards, security rules to learn but manageable.
3. **R2** — medium. ~4 hours first time. Cloudflare account →
   bucket → custom domain → upload. Familiar pattern, fairly
   friendly UI.
4. **CloudKit Assets** — medium. Code changes are the cost — the
   Apple-side setup is trivial, but `AudioPlayerService` and
   `TourDownloader` need real edits to swap `URL` for `CKAsset`.
5. **S3 + CloudFront** — hard. ~1 full day first time. Multiple
   AWS services to wire together, hostile UI, real risk of
   configuration mistakes (open buckets, billing accidents).

---

## Risk profile for a solo operator

- **R2:** low. Costs are predictable (essentially zero). One
  vendor to learn. Files are HTTPS-accessible anywhere — no
  lock-in to a specific app distribution channel.
- **S3+CF:** medium-high. The egress bill can scale unexpectedly.
  Configuration mistakes can be expensive (publicly-listable
  buckets, unbounded data transfer). Mitigations exist (billing
  alarms, OAC) but they're more setup steps and more things to get
  wrong.
- **ODR:** low cost risk, but real **product** risk. The constraint
  "new audio = new app submission" means you can't post-launch
  iterate on the catalog at your pace — Apple's review queue sets
  the pace. That's a strategic choice, not just a cost choice.
- **Firebase:** medium. Same egress-scales-with-success problem as
  S3+CF. Slightly friendlier UI, fewer ways to misconfigure.
- **Supabase:** low-medium. Pricing has a soft floor ($25 Pro)
  but is predictable. The risk is paying for capabilities you
  don't use.
- **CloudKit:** low cost risk. The real risk is **product lock-in
  to Apple's ecosystem** — any future web previews, shared links,
  or Android port means re-hosting everything elsewhere.

---

## Recommendation

**Cloudflare R2.**

Reasoning in order of weight:

1. **Zero egress** removes the "what if a tour goes viral" tail
   risk for a content business. You can't predict your downloads.
   You shouldn't have to.
2. **Files are accessible from anywhere via HTTPS.** Future-proofs
   against post-V1 needs: web previews, shared tour links,
   eventual Android.
3. **Setup is solo-operator manageable.** Not as effortless as
   ODR, but nowhere near the AWS jungle.
4. **Effective cost: $0/month at V1 scale.** No worse than ODR or
   CloudKit on bill, dramatically better on iteration speed
   (versus ODR) and platform flexibility (versus CloudKit).
5. **No code changes.** Just `URL(string:)` like today — no
   `CKAsset` plumbing, no SDK-specific glue.

**When R2 would lose** (and what wins instead):

- **Atlas commits to iOS/Apple-only forever** → CloudKit Assets
  becomes attractive ($0 lifetime, no review cadence). The cost is
  real code work and platform lock-in.
- **Atlas adds a backend later** (maker dashboard, user accounts,
  paid tours) → Supabase becomes attractive as a one-stop platform.
  At that point, you'd be paying $25/month for the bundle anyway;
  storage rides along.
- **Atlas already lives on Firebase or AWS** for unrelated reasons
  → consolidate on what your team knows.

None of these apply today. Reconsider when one does.

The case for ODR over R2: if you're certain your catalog will
update at the cadence of app releases (every few months) and you
don't anticipate any web/shared/preview use case, ODR's "zero
infrastructure" is appealing. The case for S3+CF over R2 is real
only if you already have AWS familiarity or a specific reason
(e.g., other Atlas infrastructure that lives on AWS).

---

## What you'd do once you decide

If R2:

1. Sign up for a Cloudflare account.
2. Enable R2 (requires a credit card on file, but no charge at this scale).
3. Create a bucket named e.g. `atlas-tours-prod`.
4. Set up a custom subdomain (e.g. `audio.atlas.app`) pointing at
   the bucket, so URLs read `https://audio.atlas.app/highline/stop-1.mp3`
   instead of an opaque Cloudflare URL.
5. Set up a CORS / access policy that allows public reads
   (essential — the app fetches these without auth) but blocks
   public listing (defense in depth).
6. Decide a file-naming convention. Suggested:
   `<tour-slug>/<stop-order>-<stop-slug>.mp3` —
   e.g. `highline/0-gansevoort.mp3`. Keeps URLs human-readable in
   `Tours.json` for easy debugging.
7. Upload your first test MP3, verify it plays from a browser, then
   plug the URL into `Tours.json` and verify the app plays it.
8. Update `docs/authoring-tours.md` — replace the
   `atlas-tours.example/...` placeholder convention note with the
   real URL pattern.

If ODR: the work happens inside Xcode; the Apple docs are the
canonical reference. Less repo-level prep.

If S3+CF: I'd want to sit down with you on the setup specifically
to avoid the billing/security pitfalls — say so and I'll write a
follow-on setup guide.

---

## Open follow-up questions before you commit

These don't need to be answered to *pick* R2, but you'll want a
view on them before the audio actually ships:

1. **Custom domain or default URL?** A custom domain
   (`audio.atlas.app/...`) is more brandable and decouples you
   from future hosting moves (if you switch providers later, the
   URLs in old `Tours.json` snapshots still work via a redirect).
   Recommended.
2. **One bucket or one-per-environment?** For V1, one bucket is
   fine. Post-V1, if you ever want a staging environment, a
   separate `atlas-tours-staging` bucket avoids contaminating
   production.
3. **Backup strategy.** Cloud storage is durable but not
   irreplaceable — a fat-finger delete is unrecoverable. Keep the
   master MP3 files on your laptop / in a separate backup before
   uploading.
4. **Hot-fixing audio.** With R2 you can replace a file at the
   same URL anytime, but the app's offline cache (`TourDownloader`)
   may serve the old version. Decide whether you want to version
   filenames (`stop-1-v2.mp3`) when you re-master.
