#!/usr/bin/env bash
# Fixture test of scripts/check-visual-page.sh: the built page and its Markdown pass as
# they are, and each copy with one required part removed fails.
# Usage: check-visual-page.test.sh [public dir] [page Markdown]   (run after the build)
# Site code: MIT (see LICENSE).
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
check="$here/check-visual-page.sh"
dir="${1:-public}"
md="${2:-content/visual/deterministic-screenshots.md}"
page="visual/deterministic-screenshots/index.html"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
fails=0
n=0

# run <want: pass|fail> <name> <perl edit of the HTML> <perl edit of the Markdown> [<message part>]
run() {
  local want="$1" name="$2" hedit="$3" medit="$4" msg="${5:-}"
  local d="$tmp/$n" out rc
  n=$((n + 1))
  mkdir -p "$d/public/$(dirname "$page")"
  perl -0777 -pe "$hedit" "$dir/$page" > "$d/public/$page"
  perl -0777 -pe "$medit" "$md" > "$d/page.md"
  set +e
  out="$("$check" "$d/public" "$d/page.md" 2>&1)"
  rc=$?
  set -e
  if [[ "$want" == pass && $rc -ne 0 ]] || [[ "$want" == fail && $rc -eq 0 ]]; then
    echo "FAIL $name: want $want, got exit $rc"; printf '%s\n' "$out" | sed 's/^/    /'
    fails=$((fails + 1)); return
  fi
  if [[ -n "$msg" && "$out" != *"$msg"* ]]; then
    echo "FAIL $name: output lacks '$msg'"; printf '%s\n' "$out" | sed 's/^/    /'
    fails=$((fails + 1)); return
  fi
  echo "ok   $name ($want)"
}

run pass "page as built" '' ''
run fail "clock section without its code block" \
  's{(<h2 id="?freeze-time-with-pageclock"?>.*?)<pre><code[^>]*>.*?</code></pre>}{$1}s' '' \
  "section freeze-time-with-pageclock has no <pre><code> block"
run fail "route section missing" \
  's{<h2 id="?mock-third-party-content-with-pageroute"?>}{<h2 id=other>}' '' \
  "no <h2 id=mock-third-party-content-with-pageroute> section"
run fail "locale code without timezoneId" 's{timezoneId:}{tz:}' '' "does not contain 'timezoneId:'"
run fail "JPEG sentence missing" 's{JPEG screenshots are not tracked}{JPEG is fine}' '' \
  "does not say 'JPEG screenshots are not tracked'"
run fail "other-contexts sentence missing" 's{Pages of other browser contexts are not tracked}{}' '' \
  "Pages of other browser contexts are not tracked"
run fail "option row missing" 's{<tr><td><code>trackAutoScreenshots</code>.*?</tr>}{}s' '' \
  "no row 'trackAutoScreenshots'"
run fail "option default changed" "s{<td><code>'#FF00FF'</code></td>}{<td><code>'red'</code></td>}" '' \
  "no row 'maskColor'"
run fail "link to the private reporter repository" \
  's{</article>}{<a href=https://github.com/cairnreport/playwright>README</a></article>}' '' \
  "links github.com/cairnreport/playwright"
run fail "snippet marker missing" '' 's{<!-- snippet:route -->\n}{}' "marker, found 0"
run fail "snippet marker repeated" '' 's{(<!-- snippet:clock -->\n)}{$1$1}' "marker, found 2"
run fail "snippet marker not before a code block" '' 's{(<!-- snippet:data -->\n)}{$1Some prose.\n}' \
  "snippet:data marker is not directly followed by a code block"

if [[ $fails -ne 0 ]]; then
  echo "check-visual-page.test: $fails of $n cases failed" >&2
  exit 1
fi
echo "check-visual-page.test: all $n cases passed"
