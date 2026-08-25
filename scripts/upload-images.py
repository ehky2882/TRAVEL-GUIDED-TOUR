#!/usr/bin/env python3
"""Upload a directory of images to gh-pages in ONE commit.

🔴 WHY THIS EXISTS
------------------
Every commit to gh-pages triggers a full GitHub Pages rebuild, and that site
is ~4 GB, so a rebuild takes ~10 minutes. Pages allows roughly ten builds an
hour and rejects the rest INSTANTLY — `Page build failed`, duration 0, with
no useful error.

On 2026-08-25 four hero images were uploaded as four separate commits via the
Contents API. Six consecutive builds were rejected, the new images 404'd for
about half an hour, and the owner saw blank thumbnails on a place page. The
files were in the branch the whole time; only the deploy was stuck.

A twenty-link batch means twenty heroes, plus up to twenty avatars — forty
commits, four times over the hourly limit, from ONE batch.

So: build a tree, commit it once, move the branch once. One rebuild whatever
the file count.

  python3 scripts/upload-images.py --dir out/ --message "Barcelona heroes"

⚠️ It refuses to overwrite an existing path unless --replace is given. A hero
silently overwritten at a live URL is the Thyssen bug, and PR #567 means a
phone that already downloaded a tour would never see the correction anyway.

⚠️ Verify AFTER Pages deploys, not after the push: the API returning success
means the blob is in the branch, not that the CDN serves it. --verify polls
the live URLs and compares hashes.
"""
import argparse, base64, hashlib, json, os, subprocess, sys, time

REPO = "ehky2882/TRAVEL-GUIDED-TOUR"
BRANCH = "gh-pages"
BASE = "https://ehky2882.github.io/TRAVEL-GUIDED-TOUR"


def gh(args, body=None):
    cmd = ["gh", "api"] + args
    if body is not None:
        cmd += ["--input", "-"]
    r = subprocess.run(cmd, input=json.dumps(body).encode() if body else None,
                       capture_output=True)
    if r.returncode != 0:
        raise SystemExit(f"gh api failed: {r.stderr.decode(errors='replace')[:400]}")
    return json.loads(r.stdout or b"null")


def head_sha():
    return gh([f"repos/{REPO}/git/ref/heads/{BRANCH}"])["object"]["sha"]


def path_exists(path):
    r = subprocess.run(["gh", "api", f"repos/{REPO}/contents/{path}?ref={BRANCH}",
                        "--jq", ".sha"], capture_output=True)
    return r.returncode == 0 and r.stdout.strip() != b""


def upload(files, message, replace):
    clashes = [p for p, _ in files if path_exists(p)]
    if clashes and not replace:
        sys.stderr.write(
            "REFUSING — these paths already exist on gh-pages:\n  "
            + "\n  ".join(clashes)
            + "\n\nOverwriting bytes at a live URL does not reach a phone that has\n"
              "already downloaded the tour (PR #567). Publish under a new name, or\n"
              "pass --replace if you genuinely mean to overwrite.\n")
        raise SystemExit(1)

    parent = head_sha()
    base_tree = gh([f"repos/{REPO}/git/commits/{parent}"])["tree"]["sha"]

    # One blob per file, then ONE tree, then ONE commit.
    tree = []
    for path, local in files:
        with open(local, "rb") as fh:
            raw = fh.read()
        blob = gh(["-X", "POST", f"repos/{REPO}/git/blobs"],
                  {"content": base64.b64encode(raw).decode(), "encoding": "base64"})
        tree.append({"path": path, "mode": "100644", "type": "blob",
                     "sha": blob["sha"]})
        print(f"  blob {blob['sha'][:10]}  {path}", file=sys.stderr)

    new_tree = gh(["-X", "POST", f"repos/{REPO}/git/trees"],
                  {"base_tree": base_tree, "tree": tree})
    commit = gh(["-X", "POST", f"repos/{REPO}/git/commits"],
                {"message": message, "tree": new_tree["sha"], "parents": [parent]})
    gh(["-X", "PATCH", f"repos/{REPO}/git/refs/heads/{BRANCH}"],
       {"sha": commit["sha"]})
    print(f"\n# one commit {commit['sha'][:10]} — {len(files)} file(s), one Pages build",
          file=sys.stderr)
    return commit["sha"]


def verify(files, timeout_s):
    """A push is not a deploy. Poll the live URLs and compare hashes."""
    want = {}
    for path, local in files:
        with open(local, "rb") as fh:
            want[path] = hashlib.sha256(fh.read()).hexdigest()
    deadline = time.time() + timeout_s
    pending = dict(want)
    while pending and time.time() < deadline:
        for path in list(pending):
            r = subprocess.run(["curl", "-sS", "--max-time", "30", f"{BASE}/{path}"],
                               capture_output=True)
            if r.returncode == 0 and hashlib.sha256(r.stdout).hexdigest() == pending[path]:
                print(f"  live  {path}", file=sys.stderr)
                del pending[path]
        if pending:
            time.sleep(20)
    if pending:
        sys.stderr.write(
            f"\nCOULD NOT VERIFY — {len(pending)} file(s) not serving after "
            f"{timeout_s}s. This is NOT a pass.\n  "
            + "\n  ".join(pending) + "\n")
        return 1
    print(f"\n# all {len(want)} file(s) live and byte-identical", file=sys.stderr)
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--dir", required=True, help="Directory of images to upload")
    ap.add_argument("--message", required=True, help="Commit message")
    ap.add_argument("--prefix", default="images", help="Path prefix on gh-pages")
    ap.add_argument("--replace", action="store_true",
                    help="Allow overwriting existing paths (rarely correct)")
    ap.add_argument("--verify", action="store_true",
                    help="Poll the live URLs afterwards and compare hashes")
    ap.add_argument("--verify-timeout", type=int, default=900)
    a = ap.parse_args()

    names = sorted(f for f in os.listdir(a.dir)
                   if f.lower().endswith((".webp", ".jpg", ".jpeg", ".png")))
    if not names:
        raise SystemExit(f"no images in {a.dir}")
    files = [(f"{a.prefix}/{n}", os.path.join(a.dir, n)) for n in names]

    print(f"# {len(files)} file(s) -> {BRANCH}:{a.prefix}/ in one commit\n", file=sys.stderr)
    upload(files, a.message, a.replace)
    return verify(files, a.verify_timeout) if a.verify else 0


if __name__ == "__main__":
    sys.exit(main())
