# `drafts/` — staged tour pick-maps

**What this folder is.** One README per staged batch or walk, recording the wire-in spec: slug ↔ script file ↔ category ↔ coordinate ↔ hero/gallery image ↔ tags ↔ credit, plus the centroid and walking distance for multi-stop walks. A wire-in session should need nothing beyond the README and the delivered MP3s.

**Why they're on `main`.** They weren't until 2026-07-28 — they lived only on their staging branches, while `AUDIO-PENDING-SURVEY.md` on `main` referenced them by path. A session working from `main` followed those references to files that weren't there and could reasonably conclude the staging didn't exist. Promoting the READMEs (and only the READMEs) removes that failure mode: `main` now answers *what is staged and how does it wire in* on its own.

**What is deliberately NOT here.** The narration `.txt` / `_TTS.txt` scripts stay on their staging branches — they're bulky, they change during writing, and nothing on `main` needs them until wire-in. Read them off the branch named in `AUDIO-PENDING-SURVEY.md`:

```bash
git show origin/<branch>:drafts/<folder>/01_example.txt
git ls-tree -r --name-only origin/<branch> -- drafts/<folder>/
```

**Keeping this current.** When you stage a city, land its READMEs here in the same docs-only PR that updates `AUDIO-PENDING-SURVEY.md` — both files are on `main` precisely so no session has to guess which branch to look at.

---

## Index (45 pick-maps)

### 🇺🇸 Chicago — **PENDING — awaiting narration audio**

- [`chicago-batch1/`](./chicago-batch1/README.md)
- [`chicago-loopskyscraper-walk/`](./chicago-loopskyscraper-walk/README.md)
- [`chicago-lakefront-walk/`](./chicago-lakefront-walk/README.md)
- [`chicago-riverwalk-walk/`](./chicago-riverwalk-walk/README.md)
- [`chicago-magmile-walk/`](./chicago-magmile-walk/README.md)
- [`chicago-pilsen-walk/`](./chicago-pilsen-walk/README.md)

### 🇩🇪 Berlin — **PENDING — awaiting narration audio**

- [`berlin-batch1/`](./berlin-batch1/README.md)
- [`berlin-coldwarcentre-walk/`](./berlin-coldwarcentre-walk/README.md)
- [`berlin-ghostline-walk/`](./berlin-ghostline-walk/README.md)
- [`berlin-imperialspine-walk/`](./berlin-imperialspine-walk/README.md)
- [`berlin-riverborder-walk/`](./berlin-riverborder-walk/README.md)
- [`berlin-scheunenviertel-walk/`](./berlin-scheunenviertel-walk/README.md)

### 🇦🇪 Dubai — **PENDING — awaiting narration audio**

- [`dubai-batch1/`](./dubai-batch1/README.md)
- [`dubai-creekcrossing-walk/`](./dubai-creekcrossing-walk/README.md)
- [`dubai-downtown-walk/`](./dubai-downtown-walk/README.md)
- [`dubai-marinajbr-walk/`](./dubai-marinajbr-walk/README.md)
- [`dubai-oldquarter-walk/`](./dubai-oldquarter-walk/README.md)

### 🇳🇱 Amsterdam — LIVE

- [`amsterdam-batch1/`](./amsterdam-batch1/README.md)
- [`amsterdam-canalring-walk/`](./amsterdam-canalring-walk/README.md)
- [`amsterdam-jewishquarter-walk/`](./amsterdam-jewishquarter-walk/README.md)
- [`amsterdam-jordaan-walk/`](./amsterdam-jordaan-walk/README.md)
- [`amsterdam-museumquarter-walk/`](./amsterdam-museumquarter-walk/README.md)
- [`amsterdam-oldside-walk/`](./amsterdam-oldside-walk/README.md)

### 🇬🇧 London — LIVE

- [`after-the-fire-wrens-city/`](./after-the-fire-wrens-city/README.md)
- [`albertopolis/`](./albertopolis/README.md)
- [`london-batch3-scripts/`](./london-batch3-scripts/README.md)
- [`london-batch4-scripts/`](./london-batch4-scripts/README.md)
- [`the-measure-of-the-world/`](./the-measure-of-the-world/README.md)
- [`the-south-bank-mile/`](./the-south-bank-mile/README.md)
- [`the-spine-of-power/`](./the-spine-of-power/README.md)

### 🇨🇦 Montreal — LIVE

- [`montreal-batch1/`](./montreal-batch1/README.md)
- [`montreal-batch3/`](./montreal-batch3/README.md)
- [`montreal-downtown-walk/`](./montreal-downtown-walk/README.md)
- [`montreal-mountroyal-walk/`](./montreal-mountroyal-walk/README.md)
- [`montreal-oldmontreal-walk/`](./montreal-oldmontreal-walk/README.md)
- [`montreal-plateaumileend-walk/`](./montreal-plateaumileend-walk/README.md)

### 🇫🇷 Paris — LIVE

- [`paris-batch1/`](./paris-batch1/README.md)
- [`paris-batch2/`](./paris-batch2/README.md)
- [`paris-batch3/`](./paris-batch3/README.md)
- [`paris-batch4/`](./paris-batch4/README.md)

### 🇮🇹 Rome — LIVE

- [`rome-ancientrome-walk/`](./rome-ancientrome-walk/README.md)
- [`rome-aventinetestaccio-walk/`](./rome-aventinetestaccio-walk/README.md)
- [`rome-baroqueheart-walk/`](./rome-baroqueheart-walk/README.md)
- [`rome-batch1/`](./rome-batch1/README.md)
- [`rome-ghettotrastevere-walk/`](./rome-ghettotrastevere-walk/README.md)
- [`rome-vaticanborgo-walk/`](./rome-vaticanborgo-walk/README.md)

Attribution obligations for every image referenced above: [`CREDITS.md`](./CREDITS.md). What is staged vs live: [`AUDIO-PENDING-SURVEY.md`](./AUDIO-PENDING-SURVEY.md).
