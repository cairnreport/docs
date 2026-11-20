#!/usr/bin/env bash
# Fixture test of scripts/check-site.sh: each case builds a small site tree with one
# extra page (or stylesheet) and expects the checker to pass or fail.
# Site code: MIT (see LICENSE).
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
check="$here/check-site.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
fails=0
n=0

# tree <dir>: the files check-site.sh requires, with nothing external in them.
tree() {
  mkdir -p "$1/getting-started"
  for f in index.html 404.html getting-started/index.html; do
    printf '<!doctype html><title>t</title><a href=/>home</a>\n' > "$1/$f"
  done
  printf '<svg xmlns="http://www.w3.org/2000/svg"/>\n' > "$1/favicon.svg"
  printf 'cairnreport.dev\n' > "$1/CNAME"
  printf 'User-agent: *\n' > "$1/robots.txt"
  printf '<urlset><url><loc>https://cairnreport.dev/</loc></url></urlset>\n' > "$1/sitemap.xml"
}

# run <want: pass|fail> <name> <file> <content> [<expected message part>]
run() {
  local want="$1" name="$2" file="$3" content="$4" msg="${5:-}"
  local dir="$tmp/$n" out rc
  n=$((n + 1))
  tree "$dir"
  mkdir -p "$(dirname "$dir/$file")"
  printf '%s\n' "$content" > "$dir/$file"
  set +e
  out="$("$check" "$dir" 2>&1)"
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

p='page/index.html'

# The empty tree passes.
run pass "baseline tree" "$p" '<p>nothing external</p>'

# Allowed hosts pass anywhere.
run pass "allowed hosts in links" "$p" \
  '<a href=https://github.com/cairnreport/docs>src</a> <a href="https://cairnreport.dev/x?a=1&amp;b=2">x</a>'

# Reserved example hosts pass in the text of a <code> element.
run pass "reserved host in pre/code" "$p" \
  "<pre><code class=language-ts>await page.route('https://ads.example.test/**', (route) =&gt;
  route.fulfill({ path: 'fixtures/ad.png' }));</code></pre>"
run pass "entity-quoted reserved host in code" "$p" \
  '<pre><code>page.route(&#39;https://ads.example.test/**&#39;)</code></pre>'
run pass "each reserved name in inline code" "$p" \
  '<p><code>https://shop.example/</code> <code>http://a.invalid</code> <code>https://www.example.com/a</code>
<code>https://example.org</code> <code>https://api.example.net:8443/v1</code> <code>http://localhost:8080/</code>
<code>http://app.test</code></p>'

# Reserved hosts fail outside <code>, and in tags or attributes inside <code>.
run fail "reserved host in href" "$p" \
  '<a href=https://ads.example.test/>ad</a>' "reserved example host outside a <code> element"
run fail "reserved host in quoted src" "$p" \
  '<img src="https://example.com/a.png" alt="">' "reserved example host outside a <code> element"
run fail "reserved host in prose text" "$p" \
  '<p>See https://example.com for details.</p>' "reserved example host outside a <code> element"
run fail "reserved host in a link nested in code" "$p" \
  '<code><a href=https://example.com/>x</a></code>' "reserved example host outside a <code> element"
run fail "reserved host in an attribute of the code tag" "$p" \
  '<code data-src=https://example.com/>x</code>' "reserved example host outside a <code> element"
run fail "reserved host in srcset" "$p" \
  '<img srcset="https://cdn.example.test/a.png 2x" alt="">' "reserved example host outside a <code> element"
run fail "reserved host in form action" "$p" \
  '<form action=https://example.org/post></form>' "reserved example host outside a <code> element"
run fail "reserved host in CSS url()" "css/site.css" \
  'body{background:url(https://example.com/bg.png)}' "reserved example host outside a <code> element"
run fail "reserved host in an unclosed code element" "$p" \
  '<code>https://example.com/' "reserved example host outside a <code> element"

# Hosts that only look reserved fail, also inside <code>.
run fail "other host in code" "$p" '<code>https://evil.com/</code>' "external URL not allowed"
run fail "example.com as a subdomain" "$p" '<code>https://example.com.evil.com/</code>' "external URL not allowed"
run fail "lookalike notexample.com" "$p" '<code>https://notexample.com/</code>' "external URL not allowed"
run fail "localhost as a subdomain" "$p" '<code>http://localhost.evil.com/</code>' "external URL not allowed"
run fail "userinfo hides a host" "$p" '<code>https://example.com@evil.com/</code>' "external URL not allowed"
run fail "entity-encoded userinfo in href" "$p" \
  '<a href=https://cairnreport.dev&#64;evil.com/>x</a>' "external URL not allowed"
run fail "other host in href" "$p" '<a href=https://evil.com/>x</a>' "external URL not allowed"

if [[ $fails -ne 0 ]]; then
  echo "check-site.test: $fails of $n cases failed" >&2
  exit 1
fi
echo "check-site.test: all $n cases passed"
