# Getting started with Claude Code — a guide for a complete beginner

You're going to be adding content to **Dozent** (the audio-tour app; the code
still calls it "Atlas"). This guide takes you from nothing to your first batch
of tours added and live.

**You will never use a terminal, and you will never write code.** You describe
what you want in plain English; Claude does the work and shows you the result.
That is genuinely the whole job.

Set aside about **30 minutes** for the one-time setup, then about **15 minutes**
for your first real task.

---

## Part 0 — What Edward needs to do first (send him this bit)

Two things, both one-off, both take two minutes:

1. **Add you to the repository on GitHub.** Go to
   `github.com/ehky2882/TRAVEL-GUIDED-TOUR` → **Settings** → **Collaborators
   and teams** → **Add people** → your GitHub username → give **Write** access.
   You'll get an email invitation — accept it.
2. **Confirm the Claude plan.** Claude Code needs a paid Claude plan
   (**Pro** or **Max**). Either put your account on one, or decide together
   whose account you'll use.

Don't go further until the GitHub invitation is accepted.

---

## Part 1 — One-time setup (~30 minutes)

### Step 1 — Make a GitHub account

GitHub is where the project's files live. It's free.

1. Go to **github.com** → **Sign up**.
2. Use an email you check. Pick any username.
3. Verify the email.
4. Send Edward your username so he can do Part 0, step 1.
5. Accept the invitation email when it arrives (the button says
   **Accept invitation**).

> **Do I need to learn GitHub?** No. You will almost never open it. It's just
> where the files sit. Claude talks to it for you.

### Step 2 — Make a Claude account with a paid plan

1. Go to **claude.ai** → sign up (use the same email if you like).
2. Upgrade to **Pro** (or **Max**). Claude Code isn't available on the free
   plan.

### Step 3 — Open Claude Code and connect GitHub

1. Go to **claude.ai/code** and sign in.
2. The first screen offers a desktop app. To stay in your browser — which is
   what Edward uses and what I'd suggest starting with — click
   **Continue on web** at the bottom of the page.
3. It will ask you to connect GitHub. Click through, and GitHub will show an
   authorization page. Click **Authorize**.
4. It may then offer to install the "Claude GitHub App" on your repositories.
   **Say yes / install it** — it lets Claude fix problems on its own later. (If
   you clicked **Skip**, that's fine too, nothing breaks.)
5. On a Pro or Max plan, Claude sets up your working environment automatically.
   Nothing to do.

**If you'd rather have a proper app than a browser tab**, download the Claude
desktop app for Mac or Windows from **claude.ai/download**, sign in, and click
the **Code** tab. It works the same way. (On Windows it will ask you to install
**Git for Windows** first — install it, restart the app, done.) Everything below
applies to both.

### Step 4 — Your first session (the "does this thing work" test)

At **claude.ai/code**:

1. Below the message box there's a **repository selector**. Click it and choose
   **ehky2882/TRAVEL-GUIDED-TOUR**.
2. Next to the message box is a **mode dropdown**. Choose **Accept edits** —
   that lets Claude get on with it without stopping to ask permission for every
   small thing.
3. Type this and press Enter:

   > Run the session-start script and tell me in plain English what state the
   > project is in. I'm new here — no jargon.

Claude will spend a couple of minutes and then explain the project's current
state back to you. **That's it — you've used Claude Code.** If that worked,
everything else is the same motion with a different request.

---

## Part 2 — Your first real job: adding link pins

A **link pin** is someone else's public post — a TikTok, Instagram Reel or
YouTube video about a place — pinned to that place on the map. In the app it
looks like a tour, but tapping it opens TikTok or Instagram instead of playing
audio. It's the fastest way to add content, which is why you're starting here.

### What you need to collect

For each post, two things:

| | |
|---|---|
| **The link** | Copy the post's URL — the "Share → Copy link" option in the app |
| **Where it is** | The place name is fine ("Sagrada Família, Barcelona"). Coordinates or a Google Maps link are even better |

**The location genuinely matters.** A pin with no location doesn't fail loudly
— it quietly sits in the ocean off Africa, and no check anywhere catches it. If
you don't know where a post was filmed, say so rather than guessing, and Claude
will look it up and read the answer back to you to confirm.

### What to actually type

Start a new session (repository selected, **Accept edits** mode) and paste
something like this:

> Use the atlas-upload skill. I want to add these link pins. For each one, look
> up the coordinates and read them back to me before you add anything.
>
> https://www.instagram.com/reel/XXXXXXX/ — Sagrada Família, Barcelona
> https://www.tiktok.com/@someone/video/123456 — Borough Market, London
> https://www.youtube.com/watch?v=XXXXXXX — Trevi Fountain, Rome

That's it. The mention of **the atlas-upload skill** is the important part — it
loads a detailed instruction sheet that lives in the project and tells Claude
exactly how this project does things, including a dozen mistakes that have been
made before and shouldn't be made again.

### What happens next

Claude will:

1. Confirm the locations with you.
2. Pull each post's title, creator and thumbnail.
3. Create the catalog entries and crop the thumbnails.
4. Run the checks that catch duplicates and broken images.
5. Open a **pull request** — a proposed change, waiting for approval.
6. Wait for the automated tests to pass, then merge it.

Content changes like this **don't need Edward's approval** — they merge
automatically once the tests are green. You'll see the pins in the app shortly
after.

### What to check before it merges

Ask Claude to show you the pins as a plain list — creator, place, city. Read it
like a human:

- Is the **place** right? A video about the Trevi Fountain shouldn't be pinned
  in Milan.
- Is the **title** sensible? Some creators title every video with the same
  channel boilerplate; if the title is nonsense, tell Claude what the post is
  actually about and it'll use that instead.
- Did anything get flagged? Instagram Reels using licensed music can't play
  inside the app — they open Instagram instead. Claude will tell you which ones.
  That's normal, not a bug. Mention it to Edward if there are a lot.

---

## Part 2b — When you have a pile of links and don't know which are any good

Part 2 assumes you already know where each post was filmed. Often you won't —
you'll have opened a creator's account, copied thirty links, and have no idea
which ones belong in the app. **That is a supported job, and a different one.**
Do not try to filter them yourself first. Dumping the lot is the point.

### What to type

> Use the atlas-upload skill. I've got a pile of links from one creator. I don't
> know which are usable — please triage them first, tell me what you'd pin and
> what you'd skip, and don't add anything until I say so.
>
> https://www.tiktok.com/@someone/video/123
> https://www.instagram.com/reel/XXXX/
> …

Add a place after a link if you happen to know it (`… — Borough Market,
London`). If you don't, say nothing — Claude looks it up and reads it back to
you before anything is added.

### What comes back

A numbered list, sorted:

| | |
|---|---|
| **Already in the app** | somebody pinned it before — skip, no work |
| **Looks good** | one clear place, and where Claude proposes to pin it |
| **Needs a decision** | usually a post covering several places, or a *route* — a ferry line, a whole street. The app pins **points**, so a route often does not fit at all |
| **Probably not for us** | podcast plugs, "10 years of making videos", replies to commenters |
| **Dead** | deleted or private |

Then reply by number: `"3, 5, 8 yes. 4 skip. 9 is Lisbon not Madrid."` Nothing
is added to the app until you do.

### 🔴 The one thing to be sceptical about

**A green "looks good" count is not a verdict.** These labels come from reading
the post's caption, and captions mislead in both directions. Measured on a real
account: **9 of 11 posts came back "looks good" when only 3 were actually
pinnable** — and in the same run a genuinely good post was binned as "not for
us" because its caption mentioned an anniversary.

So Claude is instructed to read every caption and give you a real opinion, not
just hand over the machine's list. **If you ever get back a clean list with no
discussion of the individual posts, that session skipped the work — say so and
ask it to go through them properly.**

### Things that are Edward's call, not yours

Some creators sell things — an estate agent posting property listings, a shop
posting stock. Whether that belongs in the app is a policy question. Claude
should raise it with Edward rather than decide, and so should you. (Standing
decision, 2026-09-11: **property listings are judged case by case.**)

### Why Instagram links are the valuable ones

Given only a creator's *handle*, Claude can fetch roughly the 14 newest posts
from TikTok and ~15 from YouTube by itself — **and nothing at all from
Instagram.** Instagram switched off the ability for anyone outside the company
to list an account's posts, so those links have to be copied by a human. Since
Instagram is the biggest platform in this catalogue, **pasting Instagram links
is the single most useful thing you can do.**

---

## Part 3 — Once you're comfortable

Same motion, bigger jobs. Say "use the atlas-upload skill" and describe what you
want:

| Job | What to say |
|---|---|
| **A city's audio tours** | "I have a Dropbox folder of MP3s, scripts and photos for Lisbon — help me get them into the app." Claude will check every coordinate first; a wrong one is invisible to every other check and has shipped twice before |
| **Photos for a tour** | "The Whitney tour has no photos — find some." Claude finds copyright-free candidates, sends them to you numbered, and you reply with your picks: "3 for the main photo, then 1, 7, 9" |
| **Writing tour scripts** | "Write a tour script for the Palace of Westminster." There's a separate skill for the house writing voice |

Do the first city drop **with Edward on the call**. It's a bigger job with more
moving parts, and it's much easier the second time.

---

## Part 4 — The rules that matter

Five things. They exist because each one has already gone wrong.

1. **Never change anything ending in `.swift`.** That's the app itself. If
   Claude proposes touching one, stop and ask Edward. Content and photos are
   yours; the app is his.
2. **Never let Claude "just fix" a photo by replacing it.** A replacement photo
   must get a **new filename**. Phones that have already downloaded a tour keep
   the old photo forever otherwise. The skill knows this — but if you see the
   word "overwrite", ask.
3. **Trust the checks, but read them.** If a check says it *couldn't* verify
   something, that is not a pass. Ask Claude to run it again and say what
   happened.
4. **Don't ask Claude what's live from memory.** Things like "is the app in
   review", "did that merge" — always "check the live system", never "what does
   the project note say". The note goes stale; the system doesn't.
5. **Ask when unsure.** Nothing you do here is unrecoverable if you ask first.
   Everything goes through a pull request, and Edward can undo anything.

---

## Part 5 — When something goes wrong

| What you see | What to do |
|---|---|
| Claude asks a question you don't understand | Say "explain that like I'm not a developer" — it will |
| The repository doesn't appear in the list | The GitHub invitation isn't accepted yet, or you connected a different GitHub account |
| A check is red / tests failing | Say "the tests are failing, please look at why and fix it". It's usually Claude's own to fix |
| The session seems stuck | Sessions keep running when you close the tab. Reopen it from the sidebar at claude.ai/code |
| Claude wants to do something that feels big | Stop it and ask Edward. "Wait — check with me first" always works |
| You lost track of what you were doing | Ask "what have we done so far and what's left?" |

---

## A tiny glossary

| Word | What it actually means |
|---|---|
| **Repository (repo)** | The project's folder of files, stored on GitHub |
| **Branch** | A private copy of the project where changes are made safely, before anyone else sees them |
| **Pull request (PR)** | A proposed change, waiting to be approved and folded in. Everything you do becomes one |
| **Merge** | Approving a pull request, so the change becomes real |
| **CI** | Automated tests that run on every pull request. "CI green" = tests passed |
| **The catalog** | The master list of every tour and pin in the app |
| **Link pin** | Someone else's post pinned to a map location |
| **Skill** | A written instruction sheet Claude loads on request. Ours is `atlas-upload` |
| **Hero image** | The big photo at the top of a tour |

---

## The one thing to remember

Start every session by saying **"use the atlas-upload skill"** and then
describing what you want in ordinary English. That single sentence loads
everything this project knows about doing the job properly.

Welcome aboard.
