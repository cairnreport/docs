#!/usr/bin/env bash
# Checks the built site in $1 (default: public). Site code: MIT (see LICENSE).
# - required files exist and CNAME is cairnreport.dev;
# - no <script>, no protocol-relative URLs;
# - every absolute URL in HTML and CSS points to github.com/cairnreport or cairnreport.dev;
# - the only mailto: address is the security contact.
set -euo pipefail

dir="${1:-public}"
fail=0
err() { echo "check-site: $*" >&2; fail=1; }

for f in index.html 404.html favicon.svg CNAME robots.txt sitemap.xml getting-started/index.html; do
  [[ -f "$dir/$f" ]] || err "missing $dir/$f"
done
if [[ -f "$dir/CNAME" && "$(tr -d '[:space:]' < "$dir/CNAME")" != "cairnreport.dev" ]]; then
  err "CNAME must contain cairnreport.dev"
fi

mapfile -t files < <(find "$dir" -type f \( -name '*.html' -o -name '*.css' \) | sort)
[[ ${#files[@]} -gt 0 ]] || err "no HTML or CSS files in $dir"

if grep -il '<script' "${files[@]}" >/dev/null; then
  err "script tags found in: $(grep -il '<script' "${files[@]}" | tr '\n' ' ')"
fi
if grep -Eo '(src|href|action|srcset)=["'"'"']?//[^"'"'"' >]*' "${files[@]}" | grep -q .; then
  err "protocol-relative URLs found:"; grep -Eo '(src|href|action|srcset)=["'"'"']?//[^"'"'"' >]*' "${files[@]}" >&2
fi

allowed='^https://(github\.com/cairnreport([/?#].*)?|cairnreport\.dev([/?#].*)?)$'
while IFS= read -r hit; do
  url="${hit#*:}"
  [[ "$url" =~ $allowed ]] || err "external URL not allowed: $hit"
done < <(grep -Eo 'https?://[^"'"'"' <>)]+' "${files[@]}" | sort -u)

while IFS= read -r hit; do
  addr="${hit#*mailto:}"
  [[ "$addr" == "security@cairnreport.dev" ]] || err "unexpected mailto address: $hit"
done < <(grep -Eo 'mailto:[^"'"'"' <>?]+' "${files[@]}" | sort -u)

if [[ $fail -ne 0 ]]; then exit 1; fi
echo "check-site: ${#files[@]} HTML/CSS files OK (no scripts, only allowed external URLs)"
