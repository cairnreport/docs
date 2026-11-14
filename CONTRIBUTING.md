# Contributing to Cairn Report documentation

Thanks for your interest in Cairn Report. This repository is private for now, so contributions
come from the maintainers and invited collaborators.

## Specs first

Requirements, designs and task lists live in the private specs repository (`cairnreport/specs`),
managed with [OpenSpec](https://github.com/Fission-AI/OpenSpec). A change that adds or alters
behaviour starts there as an approved change; the pull request here implements it.

- Reference the change and the requirement IDs (`R#.#`) in the pull request.
- Name tests after the requirement and scenario, e.g. `TestR1_2_...`.
- Typos, small fixes and dependency updates do not need a spec change.

## Branches and pull requests

1. Branch from `main`, e.g. `fix/healthz-timeout` or `feat/r6-2-search`.
2. Keep each pull request to one concern and as small as practical.
3. Run the checks below before you push.
4. Open a pull request against `main` and fill in the template.
5. A maintainer reviews it. It is merged once CI is green and the review is approved; nobody pushes
   directly to `main` or force-pushes it.

Preview the site locally with `hugo server` and check that `hugo --minify` builds without
warnings. CI builds the site with the pinned Hugo version and checks links on every pull request.

## Commits

Write commit messages in the imperative ("Add retention job"), with a short subject line. A
DCO sign-off (`Signed-off-by`) is **not** required, and there is no CLA.

## Licence

By contributing, you agree that your contribution is licensed under this repository's licence (see
[README.md](README.md#licence)).

## Conduct and security

This project follows the [Code of Conduct](CODE_OF_CONDUCT.md). Report security issues privately as
described in [SECURITY.md](SECURITY.md), never in a public issue.
