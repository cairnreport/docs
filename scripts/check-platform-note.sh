#!/usr/bin/env bash
# Checks the platform note (Cairn Report requirement R15.7, test TestR15_7_PlatformNote).
# Usage: check-platform-note.sh [public dir]   (run after the build)
# - the built install page (getting-started/index.html), under its "Platforms" heading, and
#   the cairn page (cli/index.html) hold the note's three sentences:
#     "Cairn reporters run on Linux and macOS."
#     "On Windows, run them in a Linux container: Docker (<command>) or a Linux distribution
#      under WSL 2."
#     "Native Windows support is planned."
#   where <command> is a <code> element holding
#   docker run --rm -v "${PWD}:/work" -w /work ghcr.io/cairnreport/cairn followed by a
#   cairn subcommand (the subcommand itself is not pinned);
# - no built page holds cairn.exe, windows_amd64, windows_arm64, a link to a .zip file, or
#   says that something runs natively on Windows.
# Pages are read with tags removed (inside the note), entities decoded and whitespace collapsed.
# Site code: MIT (see LICENSE).
set -euo pipefail

dir="${1:-public}"
fail=0
err() { echo "check-platform-note: $*" >&2; fail=1; }

# note <page> <scope>: prints the problems with the note on <page>, one per line.
# scope "platforms": the <h2> whose text is "Platforms", up to the next <h2> or </article>;
# scope "article": the whole <article>.
note() {
  perl -0777 -ne '
    sub dec { my $t = shift;
      $t =~ s/&#[xX]([0-9a-fA-F]+);?/chr(hex $1)/ge; $t =~ s/&#([0-9]+);?/chr($1)/ge;
      $t =~ s/&quot;/"/g; $t =~ s/&apos;/\x27/g; $t =~ s/&lt;/</g; $t =~ s/&gt;/>/g;
      $t =~ s/&nbsp;/ /g; $t =~ s/&amp;/&/g; return $t; }
    sub norm { my $t = dec(shift); $t =~ s/\s+/ /g; $t =~ s/^ | $//g; return $t; }
    my $scope = "'"$2"'"; my $s;
    if ($scope eq "platforms") {
      if (m{<h2\b[^>]*>\s*Platforms\s*</h2>(.*?)(?=<h2[\s>]|</article>|\z)}s) { $s = $1; }
      else { print "no <h2> \"Platforms\" heading\n"; exit; }
    } else {
      if (m{<article\b[^>]*>(.*?)</article>}s) { $s = $1; }
      else { print "no <article> element\n"; exit; }
    }
    my @code; push @code, norm($1) while $s =~ m{<code\b[^>]*>(.*?)</code\s*>}gs;
    (my $text = $s) =~ s/<[^>]*>//g; $text = norm($text);
    my $cmd = q{docker run --rm -v "${PWD}:/work" -w /work ghcr.io/cairnreport/cairn};
    print "the note does not say \"Cairn reporters run on Linux and macOS.\"\n"
      unless index($text, "Cairn reporters run on Linux and macOS.") >= 0;
    print "the note does not say \"Native Windows support is planned.\"\n"
      unless index($text, "Native Windows support is planned.") >= 0;
    print "the note does not say \"On Windows, run them in a Linux container: Docker (<command>) or a Linux distribution under WSL 2.\"\n"
      unless $text =~ m{On Windows, run them in a Linux container: Docker \(\Q$cmd\E [^()]*\) or a Linux distribution under WSL 2\.};
    print "no <code> element holds \"$cmd\" followed by a cairn subcommand\n"
      unless grep { m{^\Q$cmd\E [a-z][a-z0-9-]*(?: |$)} } @code;
  ' "$1"
}

for p in "getting-started/index.html platforms" "cli/index.html article"; do
  page="${p% *}" scope="${p#* }"
  if [[ ! -f "$dir/$page" ]]; then err "missing $dir/$page"; continue; fi
  while IFS= read -r problem; do
    [[ -n "$problem" ]] && err "$page: $problem"
  done < <(note "$dir/$page" "$scope")
done

# Absence on every built page: whole HTML (tags and attributes too) and its text.
mapfile -t pages < <(find "$dir" -type f -name '*.html' | sort)
[[ ${#pages[@]} -gt 0 ]] || err "no HTML files in $dir"
while IFS= read -r hit; do
  [[ -n "$hit" ]] && err "$hit"
done < <(perl -0777 -ne '
  sub dec { my $t = shift;
    $t =~ s/&#[xX]([0-9a-fA-F]+);?/chr(hex $1)/ge; $t =~ s/&#([0-9]+);?/chr($1)/ge;
    $t =~ s/&quot;/"/g; $t =~ s/&apos;/\x27/g; $t =~ s/&lt;/</g; $t =~ s/&gt;/>/g;
    $t =~ s/&nbsp;/ /g; $t =~ s/&amp;/&/g; return $t; }
  my $html = dec($_);
  for my $w ("cairn.exe", "windows_amd64", "windows_arm64") {
    print "$ARGV: holds \"$w\" (no Windows binary is published, R15.7)\n" if $html =~ /\Q$w\E/i;
  }
  while ($html =~ m{\b(?:href|src)\s*=\s*["\x27]?([^"\x27\s>]*\.zip)(?=[?#"\x27\s>]|$)}gi) {
    print "$ARGV: links the .zip file \"$1\" (no Windows archive is published, R15.7)\n";
  }
  (my $text = $_) =~ s/<[^>]*>/ /g; $text = dec($text); $text =~ s/\s+/ /g;
  print "$ARGV: says \"$1\" (native Windows support is deferred, R15.7)\n"
    if $text =~ /\b(runs? natively on Windows)\b/i;
' "${pages[@]}")

if [[ $fail -ne 0 ]]; then
  echo "check-platform-note: TestR15_7_PlatformNote FAIL" >&2
  exit 1
fi
echo "check-platform-note: TestR15_7_PlatformNote OK (note on getting-started and cli; no Windows binary, .zip link or native-Windows claim on ${#pages[@]} pages)"
