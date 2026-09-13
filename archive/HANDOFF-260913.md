# HANDOFF 2026-09-13 — Unique usernames, designed and shipped end to end

Session "LOCAL - USERNAMES". Owner requirement (2026-09-12): *"at minimum, we definitely need every user to have a unique username."* Hard constraint throughout: never delete or merge an account.

## What shipped (all merged to `main`)

| PR | What |
|---|---|
| #841 | `docs/usernames-design.md`: nine choices, each with a recommendation |
| #844 | Owner chose **all recommendations**, "so long as they are aligned with industry standards". Each was checked (§ Industry check) |
| #846 | `backend/usernames.sql` (**applied** 2026-09-13 01:07 UTC) + `backend/rename_new_creators_260913.sql` (**applied** 01:26) |
| #847 | `platform` + `handle` on all 389 `Tours.json` makers; `make-link-pin.py`, seed and `check-catalog-keys.py` carry them |
| #849 | App: `@handle` under names, USERNAME field with live availability in Edit Profile, handle search, one-time prompt before first publish. **Owner device-tested on build 153: "seems to work"** |
| #851 | `status/builds/153.md` |
| #854 | `backend/reserve_former_prefix.sql` (**applied**): reserves `former.` for deleted accounts |
| #855 | `merge-link-pins.py` warns when a new pinned creator's handle is held by a Dozent account (warn only) |

## The model, in one paragraph

Every `makers` row has `platform` (`dozent` / `instagram` / `tiktok` / `youtube`) and `handle` (lowercase, no `@`), **unique as a pair**. That is forced by the live data: 19 creators are pinned under the same handle on two platforms. Display names are untouched and may repeat. Dozent handles are 3–24 characters, `a–z 0–9 . _`, and must start and end with a letter or number. Reserved: official words, the `dozent` / `atlas` / `user.` / `former.` prefixes, and every pinned creator's handle. A handle can change once per 30 days (the first change from an automatic one is free), and the old handle is held for 30 days. A guard trigger `makers_handle_guard` enforces all of it for every build ever shipped. The profile upsert **never** sends the handle (`MakerRow.encode`, test-guarded); changing it is its own UPDATE. `handle_available(text)` is signed-in only.

## Verified, not relayed

- After the paste: 417 rows all carry a handle, 0 duplicates; 355 pinned creators match their names, 34 studios are `atlas.*`, 28 accounts (12 named from display name, 16 `user.*`); every display name byte-identical to before; anon refused `handle_available`; `check-catalog-contract.py` PASS.
- One-time rename (explicit owner instruction, **not a precedent**): 0 rows still "New Creator", 16 named `@user.*`, 28 accounts. New nameless signups still arrive as "New Creator", deliberately.
- `test_sim`: 660 passed / 0 failed; `UsernameTests` 12/12. `merge-link-pins.py --selftest` 39/39; live lookup returned exactly the held handles.

## Owner decisions this session

- All nine design recommendations. Studio handles stay `@atlas.<code>` (offered `dozent.<code>`; owner: "ok perfect").
- **Users may delete their own account.** The other session (`claude/account-self-delete`) owns it: "remove unsold, keep sold", maker row anonymised to "Former creator" with handle `former.<12 hex>`, old handle inserted into `released_handles`. Coordinated by message. `former.` was reserved at that session's request.

## Traps hit (lessons recorded in `docs/lessons.md`)

- `check-catalog-contract.py` exits **2 (COULD NOT VERIFY)** on the local Mac without `SSL_CERT_FILE=/etc/ssl/cert.pem`. It printed no output file the first time, which is not a pass.
- **Vercel was rate-limited on every PR** ("retry in 24 hours"). `gh pr checks --watch` exits non-zero on any failing check, so watchers that wait on all checks silently never merged #846/#851/#854. The fix was a watcher that ignores only Vercel and requires every other check to pass. `main` has no branch protection.
- A watcher polling `gh pr checks` immediately after `gh pr create` sees "no checks reported" and exits 1. Wait for checks to register first.
- #845 restructured `STATUS.md` into `status/` fragments mid-session; #846's STATUS edit conflicted and moved into fragments.

## Open

- `docs/usernames-design.md` still says the warning lives in `make-link-pin.py`; it was built in `merge-link-pins.py` (explained in #855).
- The public-account question (every signup has a public creator page; Search lists "0 tours" accounts) was left out of scope by owner choice 9. Not started.
