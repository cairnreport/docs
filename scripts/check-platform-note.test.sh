#!/usr/bin/env bash
# Fixture test of scripts/check-platform-note.sh (TestR15_7_PlatformNote): the built site
# passes as it is, and each copy with the note broken on one page, or with a Windows binary,
# a .zip link or a native-Windows claim on a page, fails with the expected message.
# Usage: check-platform-note.test.sh [public dir]   (run after the build)
# Site code: MIT (see LICENSE).
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
check="$here/check-platform-note.sh"
dir="${1:-public}"
gs="getting-started/index.html"
cli="cli/index.html"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
fails=0
n=0

for f in "$gs" "$cli"; do
  [[ -f "$dir/$f" ]] || { echo "check-platform-note.test: missing $dir/$f (build first)" >&2; exit 1; }
done

# run <want: pass|fail> <name> <page> <perl edit of that page> [<message part>]
# A page that does not exist is created holding "<article></article>" before the edit;
# the edit "delete" removes the page.
run() {
  local want="$1" name="$2" page="$3" edit="$4" msg="${5:-}"
  local d="$tmp/$n" out rc
  n=$((n + 1))
  mkdir -p "$d"
  cp -R "$dir/." "$d/"
  if [[ ! -f "$d/$page" ]]; then
    mkdir -p "$(dirname "$d/$page")"
    printf '<!doctype html><title>x</title><main><article></article></main>\n' > "$d/$page"
  fi
  if [[ "$edit" == delete ]]; then rm "$d/$page"; else perl -0777 -i -pe "$edit" "$d/$page"; fi
  set +e
  out="$("$check" "$d" 2>&1)"
  rc=$?
  set -e
  if [[ "$want" == pass && $rc -ne 0 ]] || [[ "$want" == fail && $rc -eq 0 ]]; then
    echo "FAIL TestR15_7_PlatformNote/$name: want $want, got exit $rc"; printf '%s\n' "$out" | sed 's/^/    /'
    fails=$((fails + 1)); return
  fi
  if [[ -n "$msg" && "$out" != *"$msg"* ]]; then
    echo "FAIL TestR15_7_PlatformNote/$name: output lacks '$msg'"; printf '%s\n' "$out" | sed 's/^/    /'
    fails=$((fails + 1)); return
  fi
  echo "ok   TestR15_7_PlatformNote/$name ($want)"
}

# The note's paragraph: from "Cairn reporters run" to the end of its <p>.
note='Cairn reporters run on Linux and macOS\..*?</p>'

run pass "site as built" "$gs" ''
run pass "note with another subcommand" "$cli" 's{cairn upload junit --files \x27reports/\*\.xml\x27}{cairn upload playwright --report results.json}'
run pass "note with entity-encoded quotes" "$gs" 's{"\$\{PWD\}:/work"}{&#34;\${PWD}:/work&quot;}'

run fail "getting-started without the note" "$gs" "s{$note}{</p>}s" \
  "$gs: the note does not say \"Cairn reporters run on Linux and macOS.\""
run fail "cli page without the note" "$cli" "s{$note}{</p>}s" \
  "$cli: the note does not say \"Cairn reporters run on Linux and macOS.\""
run fail "cli page missing" "$cli" delete "missing $tmp/$((n))/$cli"
run fail "getting-started without the Platforms heading" "$gs" 's{<h2 id=platforms>Platforms</h2>}{<h2 id=os>Systems</h2>}' \
  "$gs: no <h2> \"Platforms\" heading"
run fail "note outside the Platforms section" "$gs" 's{(<h2 id=platforms>Platforms</h2>)}{$1<p>Soon.</p><h2 id=later>Later</h2>}' \
  "$gs: the note does not say \"Cairn reporters run on Linux and macOS.\""
run fail "first sentence changed" "$cli" 's{run on Linux and macOS\.}{run on Linux.}' \
  "$cli: the note does not say \"Cairn reporters run on Linux and macOS.\""
run fail "WSL 2 missing" "$gs" 's{\s+or a Linux distribution under WSL 2\.}{.}' \
  "$gs: the note does not say \"On Windows, run them in a Linux container"
run fail "planned sentence missing" "$cli" 's{ Native Windows support is planned\.}{}' \
  "$cli: the note does not say \"Native Windows support is planned.\""
run fail "docker command without --rm" "$gs" 's{docker run --rm -v}{docker run -v}' \
  "$gs: no <code> element holds"
run fail "docker command with another image" "$cli" 's{ghcr\.io/cairnreport/cairn }{cairnreport/cairn }' \
  "$cli: no <code> element holds"
run fail "docker command without a subcommand" "$gs" 's{(ghcr\.io/cairnreport/cairn) upload junit [^<]*}{$1}' \
  "$gs: no <code> element holds"
run fail "docker command not in a code element" "$cli" 's{<code>(docker run [^<]*)</code>}{$1}' \
  "$cli: no <code> element holds"

run fail "getting-started holds cairn.exe" "$gs" 's{</article>}{<p>Download <code>cairn.exe</code>.</p></article>}' \
  "holds \"cairn.exe\""
run fail "another page holds cairn.exe" "extra/index.html" 's{</article>}{<p>Run cairn.exe.</p></article>}' \
  "extra/index.html: holds \"cairn.exe\""
run fail "page holds windows_amd64" "$cli" 's{</article>}{<p>cairn_0.2.0_windows_amd64.tar.gz</p></article>}' \
  "holds \"windows_amd64\""
run fail "page holds windows_arm64 in an attribute" "extra/index.html" 's{</article>}{<a href=/dl/windows_arm64/>dl</a></article>}' \
  "holds \"windows_arm64\""
run fail "page links a .zip file" "extra/index.html" 's{</article>}{<a href="https://github.com/cairnreport/cli/releases/download/v0.1.0/cairn.zip">zip</a></article>}' \
  "links the .zip file"
run fail "page links a .zip file with a query" "$cli" 's{</article>}{<a href=/dl/cairn_0.1.0.zip?x=1>zip</a></article>}' \
  "links the .zip file"
run fail "page says cairn runs natively on Windows" "$gs" 's{</article>}{<p>cairn runs natively on <em>Windows</em>.</p></article>}' \
  "says \"runs natively on Windows\""

if [[ $fails -ne 0 ]]; then
  echo "check-platform-note.test: $fails of $n cases failed" >&2
  exit 1
fi
echo "check-platform-note.test: all $n cases passed"
