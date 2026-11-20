#!/usr/bin/env bash
# Checks the built site in $1 (default: public). Site code: MIT (see LICENSE).
# - required files exist and CNAME is cairnreport.dev;
# - no <script>, no protocol-relative URLs;
# - every absolute URL in HTML and CSS points to github.com/cairnreport or cairnreport.dev,
#   except that the text of a <code> element (not its tags or attributes) may also name the
#   reserved example hosts *.test, *.example, *.invalid, example.com/.org/.net (and their
#   subdomains) and localhost (RFC 2606, RFC 6761), for snippets such as page.route(...);
#   links, sources, form actions, srcset and CSS url() keep the strict list;
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

# urls prints "<where> <file>:<url>" for every absolute URL, where is "code" for the text
# inside <code>...</code> (nested tags removed) and "strict" for everything else (all
# tags and attributes, text outside <code>, CSS). Entities are decoded first, as a
# browser would, so &#64; or &#58; cannot hide a different host.
urls() {
  perl -0777 -ne '
    sub dec { my $t = shift;
      $t =~ s/&#[xX]([0-9a-fA-F]+);?/chr(hex $1)/ge; $t =~ s/&#([0-9]+);?/chr($1)/ge;
      $t =~ s/&quot;/"/g; $t =~ s/&apos;/\x27/g; $t =~ s/&lt;/</g; $t =~ s/&gt;/>/g; $t =~ s/&amp;/&/g;
      return $t; }
    sub out { my ($where, $t) = @_;
      print "$where $ARGV:$1\n" while $t =~ m{(https?://[^"\x27\s<>)]+)}gi; }
    my $strict = $_; my $code = "";
    if ($ARGV =~ /\.html?$/i) {
      $strict =~ s{(<code\b[^>]*>)(.*?)(</code\s*>)}{
        my ($open, $in, $close) = ($1, $2, $3); my $tags = "";
        $in =~ s{(<[^>]*>)}{$tags .= "$1 "; " "}ge;
        $code .= dec($in) . "\n"; "$open $tags $close" }gise;
    }
    out("strict", dec($strict)); out("code", $code);
  ' "$@"
}

allowed='^https://(github\.com/cairnreport([/?#].*)?|cairnreport\.dev([/?#].*)?)$'
reserved='^https?://(([a-z0-9-]+\.)*(test|example|invalid|example\.com|example\.org|example\.net)|localhost)(:[0-9]+)?([/?#].*)?$'
while read -r where hit; do
  url="${hit#*:}"
  [[ "$url" =~ $allowed ]] && continue
  if [[ "$where" == code && "$url" =~ $reserved ]]; then continue; fi
  if [[ "$url" =~ $reserved ]]; then
    err "reserved example host outside a <code> element: $hit"
  else
    err "external URL not allowed: $hit"
  fi
done < <(urls "${files[@]}" | sort -u)

while IFS= read -r hit; do
  addr="${hit#*mailto:}"
  [[ "$addr" == "security@cairnreport.dev" ]] || err "unexpected mailto address: $hit"
done < <(grep -Eo 'mailto:[^"'"'"' <>?]+' "${files[@]}" | sort -u)

if [[ $fail -ne 0 ]]; then exit 1; fi
echo "check-site: ${#files[@]} HTML/CSS files OK (no scripts, only allowed external URLs; example hosts only in <code>)"
