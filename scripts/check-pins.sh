#!/usr/bin/env bash
# Fails when the tool versions in the Makefile and the Pages workflow differ.
# Renovate updates both (same depName); this catches a half-applied manual bump.
# Site code: MIT (see LICENSE).
set -euo pipefail

wf=.github/workflows/pages.yml
fail=0
for var in HUGO_VERSION LYCHEE_VERSION; do
  mk=$(sed -nE "s/^${var}[[:space:]]*:=[[:space:]]*([^[:space:]]+).*/\1/p" Makefile)
  yml=$(sed -nE "s/^[[:space:]]*${var}:[[:space:]]*[\"']?([^[:space:]\"']+).*/\1/p" "$wf")
  if [[ -z "$mk" || -z "$yml" || "$mk" != "$yml" ]]; then
    echo "check-pins: $var differs: Makefile='$mk' $wf='$yml'" >&2
    fail=1
  fi
done
[[ $fail -eq 0 ]] && echo "check-pins: Makefile and $wf pin the same Hugo and lychee versions"
exit $fail
