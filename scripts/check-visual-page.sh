#!/usr/bin/env bash
# Checks the deterministic-screenshots page (Cairn Report requirement R16.10).
# Usage: check-visual-page.sh [public dir] [page Markdown]
# - the Markdown marks each topic's snippet with <!-- snippet:<topic> --> directly before a
#   fenced code block, once per topic (the server's visual sample check reads these blocks);
# - the built page has one <h2> per topic, each section with a <pre><code> block that
#   contains the topic's API;
# - it says that JPEG screenshots and pages of other browser contexts are not tracked, and
#   that @playwright/test 1.65 or later is required;
# - it carries the visual option table (option, default) itself and does not link the
#   reporter's repository, which is private until the repositories are public.
# Site code: MIT (see LICENSE).
set -euo pipefail

dir="${1:-public}"
md="${2:-content/visual/deterministic-screenshots.md}"
html="$dir/visual/deterministic-screenshots/index.html"
fail=0
err() { echo "check-visual-page: $*" >&2; fail=1; }

[[ -f "$md" ]] || { err "missing $md"; exit 1; }
[[ -f "$html" ]] || { err "missing $html"; exit 1; }

# Markdown snippet markers: exactly one per topic, followed by a code fence.
for topic in clock locale data route mask style; do
  count=$(grep -c "^<!-- snippet:$topic -->\$" "$md" || true)
  if [[ "$count" -ne 1 ]]; then
    err "$md: want one '<!-- snippet:$topic -->' marker, found $count"
    continue
  fi
  next=$(awk -v m="<!-- snippet:$topic -->" 'found && NF { print; exit } $0 == m { found = 1 }' "$md")
  [[ "$next" == '```'* ]] || err "$md: the snippet:$topic marker is not directly followed by a code block"
done

# Built page: topic sections (h2 id, then the texts its code must contain, ';'-separated).
topics=(
  'freeze-time-with-pageclock|page.clock.setFixedTime('
  'fix-the-locale-and-time-zone|locale:;timezoneId:'
  'seed-the-test-data|seed'
  'mock-third-party-content-with-pageroute|page.route('
  'mask-what-you-cannot-control|mask:;[data-visual-mask]'
  'hide-moving-parts-with-a-shared-stylesheet|stylePath:'
)
for t in "${topics[@]}"; do
  id="${t%%|*}" want="${t#*|}"
  # The section runs from its <h2> to the next <h2>; print the text of its <pre><code> blocks.
  code=$(perl -0777 -ne '
    if (m{<h2 id="?\Q'"$id"'\E"?>(.*?)(?=<h2[\s>]|</article>|\z)}s) {
      my $s = $1; my $n = 0;
      while ($s =~ m{<pre><code[^>]*>(.*?)</code></pre>}gs) { $n++; print $1, "\n"; }
      print "<none>" if !$n;
    } else { print "<nosection>"; }' "$html")
  case "$code" in
    '<nosection>') err "no <h2 id=$id> section" ;;
    '<none>') err "section $id has no <pre><code> block" ;;
    *) IFS=';' read -ra wants <<< "$want"
       for w in "${wants[@]}"; do
         [[ "$code" == *"$w"* ]] || err "the code of section $id does not contain '$w'"
       done ;;
  esac
done

# Sentences, on the text without tags and with whitespace collapsed.
text=$(perl -0777 -pe 's/<[^>]*>//g; s/\s+/ /g' "$html")
for s in 'JPEG screenshots are not tracked' 'Pages of other browser contexts are not tracked' \
         '@playwright/test 1.65 or later'; do
  [[ "$text" == *"$s"* ]] || err "the page does not say '$s'"
done

# Option table: one row per option, with its default in the second cell.
rows=(
  "mask|<code>[]</code>"
  "maskColor|<code>'#FF00FF'</code>"
  "animations|<code>'disabled'</code>"
  "caret|<code>'hide'</code>"
  "scale|<code>'css'</code>"
  "stylePath|none"
  "trackAutoScreenshots|<code>false</code>"
  "trackToHaveScreenshot|<code>true</code>"
  "disabled|<code>false</code>"
)
for r in "${rows[@]}"; do
  opt="${r%%|*}" def="${r#*|}"
  grep -qF "<tr><td><code>$opt</code></td><td>$def</td>" "$html" \
    || err "the option table has no row '$opt' with default $def"
done

# No link to the reporter's repository (private until the repositories are public).
if grep -Eq 'github\.com/cairnreport/playwright' "$html"; then
  err "the page links github.com/cairnreport/playwright; the option table must be on the page itself"
fi

if [[ $fail -ne 0 ]]; then exit 1; fi
echo "check-visual-page: $html OK (6 topics with snippets, JPEG and context notes, option table)"
