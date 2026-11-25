# Cairn Report documentation

The source of <https://cairnreport.dev>, the documentation site for Cairn Report. It is a Hugo
site with its own minimal layouts: no theme, no Node build chain, no JavaScript, and no analytics,
web fonts or other third-party resources.

> Status: Cairn Report is in early development. The site has a landing page; the user docs grow
> with the first release.

## Build locally

```sh
make build   # production build into public/
make serve   # preview at http://localhost:1313 with live reload
make check   # build, check internal links, check that the output loads nothing external,
             # check the visual-tracking page, and run the checkers' own tests
```

On Linux (amd64/arm64) the Makefile downloads the pinned Hugo and lychee versions into `.tools/`
and verifies their checksums. Elsewhere, install the same versions and run
`make HUGO=hugo LYCHEE=lychee <target>`. The checks also need Bash and Perl. Pushes to `main`
deploy to GitHub Pages through `.github/workflows/pages.yml`.

See [CONTRIBUTING.md](CONTRIBUTING.md). Report security issues as described in
[SECURITY.md](SECURITY.md).

## Licence

Copyright 2026 The Cairn Report Authors. This repository uses two licences:

| What | Licence | File |
|---|---|---|
| Documentation content: the prose, images and other material under `content/`, and site images and logos under `static/` | Creative Commons Attribution 4.0 International (SPDX: `CC-BY-4.0`) | [LICENSE-docs](LICENSE-docs) |
| Site code: Hugo configuration, layouts and templates, scripts, workflows, and code samples embedded in the documentation | MIT License (SPDX: `MIT`) | [LICENSE](LICENSE) |

When you reuse documentation content, credit "The Cairn Report Authors" and link to
<https://cairnreport.dev>. Code samples can be copied into your own projects under the MIT License.
