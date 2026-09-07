#!/usr/bin/env python3
"""Stamp every checker's output with WHEN it ran and WHICH revision ran.

WHY THIS EXISTS
---------------
On 2026-09-07 a fault-injection suite appeared to pass 22/22 without ever
running. The command was shaped like

    sed ... && grep -n "<anchor>" file.py && python3 suite.py > out.txt 2>&1
    echo "EXIT=$?"; cat out.txt

The `grep` matched nothing, the `&&` chain short-circuited, and `python3` never
ran — but `out.txt` already existed from a DIFFERENT session two days earlier,
so `cat` printed that older run's summary. It read exactly like a pass. It was
caught only because the stale file's fault count (22) did not match the current
suite's (20); had they matched, an unverified change would have shipped with an
apparent clean bill of health.

That is the same class as `check-image-duplicates.py` once printing
"OK — no suspicious duplicates" having fetched nothing, and the `PIPESTATUS`
trap where `echo $?` after a pipe reads the wrong command's status:

    🔴 A CHECK THAT CANNOT RUN MUST NOT BE ABLE TO RETURN A PASS.

WHAT THIS DOES, AND WHAT IT DELIBERATELY DOES NOT
-------------------------------------------------
It does two small things and changes no verdict anywhere:

  1. Every run prints a stamp as its FIRST line — an ISO-8601 UTC timestamp,
     the script's name, and a short hash of the script's own source. A summary
     line with no stamp above it, or with a stamp from another day, is then
     obviously suspect on sight rather than only when a count happens to
     disagree.
  2. `--out <path>` lets the checker write its own report. The file is opened
     in "w" (truncating) and stamped BEFORE any work starts, so a previous
     run's content cannot survive underneath a new one, and shell redirection —
     which happens even when the command short-circuits into never running — is
     no longer the only way to capture a report.

⚠️ There is deliberately no "END" footer. A footer written from `atexit` fires
on a crash too, so it would claim a run finished when it died. The checker's own
verdict line ("OK — …", "N/N self-tests passed") is the completion marker: a
stamped file with no verdict under it is a run that did not finish.

⚠️ The revision hash is of the SCRIPT FILE, not of the repo. Two reports whose
stamps differ in that hash were produced by different revisions of the checker —
which is exactly the disagreement that saved the 2026-09-07 session.
"""
import argparse
import atexit
import hashlib
import os
import sys
import threading
from datetime import datetime, timezone


def script_revision(path) -> str:
    """Short content hash of the checker itself, so a stale report is traceable
    to the revision that wrote it. Unreadable file → "unknown", never a crash:
    a stamping helper must not be able to fail a check."""
    try:
        with open(path, "rb") as fh:
            return hashlib.sha256(fh.read()).hexdigest()[:8]
    except OSError:
        return "unknown"


def utc_now() -> str:
    """ISO-8601, UTC, second precision. `Z` rather than `+00:00` so it is
    unambiguous when someone reads it out of a log."""
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def stamp_line(script_path, argv=None, now=None, revision=None) -> str:
    """The one line that makes a stale report visible."""
    name = os.path.basename(script_path)
    rev = revision if revision is not None else script_revision(script_path)
    args = " ".join(argv if argv is not None else sys.argv[1:])
    line = f"RUN {name} · rev {rev} · {now or utc_now()}"
    return f"{line} · args: {args}" if args else line


class _Tee:
    """Write to several streams at once. Locked because
    `check-image-duplicates.py` prints from a thread pool."""

    def __init__(self, *streams):
        self._streams = streams
        self._lock = threading.Lock()

    def write(self, s):
        with self._lock:
            for st in self._streams:
                st.write(s)
                st.flush()
        return len(s)

    def flush(self):
        with self._lock:
            for st in self._streams:
                st.flush()

    def isatty(self):
        return False


class Run:
    """Handle returned by `begin`. Holds the report file open for the run."""

    def __init__(self, line, fh=None, saved=None):
        self.line = line
        self._fh = fh
        self._saved = saved

    def close(self):
        """Restore the real streams BEFORE closing the file.

        ⚠️ Closing the file while `sys.stdout` still tees into it makes the
        interpreter fail its shutdown flush and exit 120, which would replace
        the checker's own verdict with a meaningless status — the exact class
        of bug this module exists to prevent.
        """
        if self._saved is not None:
            sys.stdout, sys.stderr = self._saved
            self._saved = None
        if self._fh is not None:
            self._fh.close()
            self._fh = None


def begin(script_path, out_path=None, argv=None) -> Run:
    """Print the stamp, and — with `--out` — start a freshly truncated report.

    Order matters: the file is truncated and stamped before any work happens,
    so a crash mid-run leaves a stamped, verdict-less file rather than the
    previous run's verdict.
    """
    line = stamp_line(script_path, argv=argv)
    fh, saved = None, None
    if out_path:
        # Truncate and stamp BEFORE the work starts. A run that dies partway
        # then leaves a stamped, verdict-less file rather than the previous
        # run's verdict sitting underneath fresh-looking output.
        fh = open(out_path, "w", encoding="utf-8")
        saved = (sys.stdout, sys.stderr)
        sys.stdout = _Tee(sys.stdout, fh)
        sys.stderr = _Tee(sys.stderr, fh)
    print(line)
    run = Run(line, fh, saved)
    # Backstop: callers close explicitly, but `close` is idempotent and the
    # streams MUST be restored on every exit path or shutdown fails with 120.
    atexit.register(run.close)
    return run


def add_out_argument(ap: argparse.ArgumentParser) -> None:
    """The shared `--out` flag, worded the same way everywhere."""
    ap.add_argument("--out", metavar="PATH",
                    help="also write this run's report to PATH (truncated and "
                         "stamped before the run starts, so a stale file "
                         "cannot survive underneath it)")


def pop_out_argument(argv=None):
    """`--out` for the two checkers that read `sys.argv` directly rather than
    using argparse. Returns the path and leaves `sys.argv` without it."""
    argv = sys.argv if argv is None else argv
    for i, a in enumerate(list(argv)):
        if a == "--out" and i + 1 < len(argv):
            path = argv[i + 1]
            del argv[i:i + 2]
            return path
        if a.startswith("--out="):
            del argv[i]
            return a.split("=", 1)[1]
    return None


def selftest() -> int:
    import tempfile

    cases, failed = [], 0

    def check(name, ok):
        nonlocal failed
        cases.append(name)
        if not ok:
            failed += 1
        print(f"  {'PASS' if ok else 'FAIL'}  {name}")

    line = stamp_line("/x/y/check-thing.py", argv=["--radius", "400"],
                      now="2026-09-07T22:03:11Z", revision="deadbeef")
    check("stamp names the script, not its path",
          line.startswith("RUN check-thing.py ") and "/x/y/" not in line)
    check("stamp carries the revision", "rev deadbeef" in line)
    check("stamp carries an ISO-8601 UTC timestamp", "2026-09-07T22:03:11Z" in line)
    check("stamp carries the arguments", line.endswith("args: --radius 400"))
    check("no arguments → no trailing 'args:'",
          "args:" not in stamp_line("/x/c.py", argv=[], now="2026-01-01T00:00:00Z",
                                    revision="aaaaaaaa"))
    check("utc_now is ISO-8601 Z", utc_now().endswith("Z") and len(utc_now()) == 20)
    check("an unreadable script hashes to 'unknown', it does not raise",
          script_revision("/nope/does/not/exist.py") == "unknown")
    check("the revision is a real content hash",
          script_revision(__file__) not in ("", "unknown")
          and len(script_revision(__file__)) == 8)

    # --out truncates: a previous run's verdict must not survive underneath.
    with tempfile.TemporaryDirectory() as d:
        p = os.path.join(d, "report.txt")
        with open(p, "w", encoding="utf-8") as fh:
            fh.write("22/22 faults caught\nOK — no suspicious duplicates\n")
        real_out, real_err = sys.stdout, sys.stderr
        try:
            run = begin(__file__, out_path=p, argv=["--demo"])
            print("fresh line")
        finally:
            run.close()          # must restore the streams by itself
        check("close() restores the real streams, so shutdown cannot exit 120",
              sys.stdout is real_out and sys.stderr is real_err)
        run.close()  # idempotent: the atexit backstop must not double-close
        check("close() is idempotent", True)
        body = open(p, encoding="utf-8").read()
        check("--out truncates the stale file", "22/22 faults caught" not in body)
        check("--out stamps the file first", body.splitlines()[0].startswith("RUN "))
        check("--out captures the run's output", "fresh line" in body)

    argv = ["prog", "--radius", "400", "--out", "/tmp/x.txt", "--selftest"]
    check("pop_out_argument returns the path", pop_out_argument(argv) == "/tmp/x.txt")
    check("pop_out_argument leaves the rest of argv alone",
          argv == ["prog", "--radius", "400", "--selftest"])
    argv2 = ["prog", "--out=/tmp/y.txt"]
    check("pop_out_argument handles --out=PATH", pop_out_argument(argv2) == "/tmp/y.txt"
          and argv2 == ["prog"])
    check("no --out → None", pop_out_argument(["prog", "--selftest"]) is None)

    total = len(cases)
    print(f"\n{total - failed}/{total} self-tests passed")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(selftest())
