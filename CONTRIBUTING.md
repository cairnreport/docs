# Contributing to Cairn Report documentation

Thanks for your interest in Cairn Report. This repository holds the documentation site at
[cairnreport.dev](https://cairnreport.dev). Fixes to wording, typos, broken links and examples are
welcome.

For larger changes, such as a new page or a restructure, please open an issue first so we can agree
on the scope.

## Branches and pull requests

1. Branch from `main`, e.g. `fix/typo-getting-started` or `docs/new-page`.
2. Keep each pull request to one concern and as small as practical.
3. Run the checks below before you push.
4. Open a pull request against `main` and fill in the template.
5. A maintainer reviews it. It is merged once CI is green and the review is approved; nobody pushes
   directly to `main` or force-pushes it.

Preview the site locally with `hugo server` and check that `hugo --minify` builds without
warnings. CI builds the site with the pinned Hugo version and checks links on every pull request.

## Commits

Write commit messages in the imperative ("Fix broken link on getting started"), with a short subject line. A
DCO sign-off (`Signed-off-by`) is **not** required, and there is no CLA.

## Licence

By contributing, you agree that your contribution is licensed under this repository's licence (see
[README.md](README.md#licence)).

## Conduct and security

This project follows the [Code of Conduct](CODE_OF_CONDUCT.md). Report security issues privately as
described in [SECURITY.md](SECURITY.md), never in a public issue.
