#!/bin/bash
# Single-pass embed grab, caching raw HTML to disk.
# ⚠️ Dozent/1.0 UA deliberately — a BROWSER UA trips Instagram's challenge page
# from a datacenter IP and returns ~625KB of nothing (session-135 lesson).
UA="Dozent/1.0 (link-pin tool; +https://dozent.world)"
OUT=embeds
n=0
while read -r code; do
  n=$((n+1))
  f="$OUT/$code.html"
  [ -s "$f" ] && { echo "$n SKIP $code"; continue; }
  curl -sSL --max-time 45 -A "$UA" "https://www.instagram.com/reel/$code/embed" -o "$f"
  sz=$(wc -c < "$f")
  echo "$n $code $sz"
  sleep 1
done < "$1"
