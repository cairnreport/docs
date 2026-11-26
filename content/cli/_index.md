---
title: The cairn command-line tool
linkTitle: cairn
description: The cairn command-line tool uploads test results from your CI to Cairn Report (coming soon).
---

**Coming soon.** `cairn` is the command-line tool that converts the result files your CI
produces and uploads them to a Cairn Report server. It has no public release yet.

## Platforms

Cairn reporters run on Linux and macOS. On Windows, run them in a Linux container: Docker
(`docker run --rm -v "${PWD}:/work" -w /work ghcr.io/cairnreport/cairn upload junit --files 'reports/*.xml'`)
or a Linux distribution under WSL 2. Native Windows support is planned.

Reference pages for each command follow with the cli releases.
