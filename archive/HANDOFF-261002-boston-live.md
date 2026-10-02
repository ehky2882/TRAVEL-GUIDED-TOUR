# HANDOFF 2026-10-02: Boston launches (Atlas Studio BOS, 30 singles + 5 walks)

**What shipped:** a new bureau, **Atlas Studio BOS** 🇺🇸, the 39th studio.
- Maker id `cebccd48-7b4b-5719-bb5b-194734d5db8e` = uuid5 `atlas-maker:bos`.
- **35 tours:** 30 single-stop tours plus 5 walks (29 segments). Tours went 1718 → 1753, and multi-stop 79 → 84.
- **Ids** follow the MIA/ATL scheme: `atlas-tour:bos:<slug>`. Singles use `atlas-stop:bos:<slug>:1` at order 0; walks use `atlas-stop:bos:<walk slug>:<order>`. Re-verified against a live Miami id.
- **City:** Harvard Yard carries `city: "Cambridge"`; everything else is `Boston` (Charlestown included).

**Sources:** scripts came from the owner's OneDrive `260928_BOSTON`, staged in #1112. Audio came from a Dropbox drop with 59 MP3s.
- The audio is all 128k/44.1k stereo, 73–142 s per file, with no byte duplicates.
- **Every file was transcript-matched to its own script** with faster-whisper tiny.en on its first 30 s. The lowest score was 0.93.

**Assembler** (scratchpad, `wire_boston.py`) follows the Miami rules:
- `transcriptText` is the clean script without its header or beats.
- `caption` is the standpoint sentence.
- `shortDescription` is the transcript cut to 145 characters.
- `longDescription` is paragraph 1 plus the paragraph after the standpoint, joined with a space as Miami does.
- **Walk stops that revisit a single use that single's CURRENT hero.** That is the Miami walks lesson, and it matters here, because 06, 07 and 14 have owner `_hero-2` heroes.
- **Every walk intro shares its stop 1 point.** The intros' walking distances come from W1 (1.5 mi) and W5 (a little over a mile); the rest are computed.

**Images:** 96 distinct files, all on gh-pages and hash-verified live; `check-image-duplicates --maker BOS` is OK (96 images).
- 83 picks were made in the Boston Image Picks artifact; all are Unsplash, Pexels or public domain.
- **10 owner photos**, some AI-edited.
- 2 CC BY-SA Haymarket images, credited.
- Walk stops W2-5, W4-3 and W5-2 **reuse** existing tour photos, per the owner. W4-3 uses `uss-constitution_2` so as not to repeat a hero within W4.

**Checks:**
- Validator: 0 errors. Four walks gained a `District` place-type tag.
- Spine: one new finding, Commonwealth Avenue Mall at 586 m. Ruled `extended-feature`, because Wikidata's point is mid-Mall and our stop is the Arlington Street end where the script stands.
- Place candidates: five Boston "groups" are each **a walk sharing its intro/stop-1 point with a single**, which is by design and not a place. **The one real question for the owner is City Hall Plaza (tour) vs the "Boston City Hall" creator pin, 92 m apart**, a part-vs-whole case.

**For the owner and author (not blocking):**
- Missing architect tags: Bulfinch, H. H. Richardson, Peter Banner, Peter Harrison, Arthur Gilman, Cossutta, Saint-Gaudens (sculptor).
- W4's "Charlestown Bridge" is now the Bill Russell Bridge.
- The author's flag 115 (re-verify the Faneuil Hall renaming status).
- 20's hero shows the Abiel Smith School.
- 22's hero looks AI-edited.

**Lesson:** pushing gh-pages a few minutes apart cancels each Pages deploy, so batch the pushes (`docs/lessons.md`).

## Follow-up the same day (#1119)
- **Architect tags added.** Nine names are now in the vocabulary (Bulfinch, H. H. Richardson, Banner, Harrison, Gilman, Cossutta, James McLaughlin, Kallmann McKinnell & Knowles, Parris), tagging 11 BOS tours. Saint-Gaudens was left out because he was a sculptor.
- **W4-4 retitled "Bill Russell Bridge".** 🔴 **Owner decision: leave the audio as recorded.** The narration still says "Charlestown Bridge", and that is accepted, so do not flag it again or ask for a re-record.
- **New place: City Hall Plaza.** It holds the City Hall Plaza single and the *Under the Artery* walk. The @ninosbuildings "Boston City Hall" pin is deliberately **not** a member (owner).
- 🔴 **Trinity Church (pin) and Copley Square (BOS tour) stay SEPARATE.** The owner ruled no place page, so do not offer it again.
- **The image picker is now a repo tool.** `scripts/make-image-picker.py` with `scripts/image-picker/template.html` is the owner's preferred way to choose images; see CLAUDE.md § Image Pipeline step 3. It was rebuilt from this session's Boston picker, and regenerating Boston from its `data.json` gives the same page byte for byte.
