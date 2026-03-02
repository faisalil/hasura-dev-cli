# hasura-dev-cli

Single public distribution repository for `hasura-dev`.

This repo is the canonical home for:

- CLI release binaries (`hasura-dev-*` tarballs)
- Engine runtime assets (`manifest.json`, `graphql-engine-*`, `checksums.txt`)
- Homebrew formula (`Formula/hasura-dev.rb`)
- Release workflows and scripts

Source code for the CLI runtime changes is tracked separately in:

- https://github.com/faisalil/hasura-dev-graphql-engine-private

## Install

Homebrew install from this repo (single-repo tap):

```bash
brew tap faisalil/hasura-dev-cli https://github.com/faisalil/hasura-dev-cli
brew install faisalil/hasura-dev-cli/hasura-dev
```

Upgrade:

```bash
brew update
brew upgrade hasura-dev
```

## Deprecation notice

Legacy distribution repositories have been retired:

- `faisalil/hasura-dev-assets`
- `faisalil/homebrew-hasura-dev`

Use this repository as the single public distribution source.

Minimum recommended CLI version: `v0.1.3`.

## Runtime commands

`hasura-dev` supports Docker-free local Hasura runtime commands:

- `hasura-dev server start-dev`
- `hasura-dev server status`
- `hasura-dev server stop`

## Version metadata

From `v0.1.3`, `hasura-dev version` includes build metadata fields:

- `build_date_local`
- `build_age`

## Engine manifest source

Distributed binaries are built with:

- `https://github.com/faisalil/hasura-dev-cli/releases/download/%s/manifest.json`

That means `start-dev` can auto-download `graphql-engine` assets from this repo without requiring `--engine-path`.

## Releases

Two release tag families are used in this single repo:

- CLI tags: `v0.1.x` (contain `hasura-dev-*` tarballs)
- Engine tags: `v2.xx.xx` (contain `manifest.json` + `graphql-engine-*` assets)

## Development notes

- Engine asset publishing workflows are under `.github/workflows/`.
- Manifest/checksum helpers are under `scripts/`.
- Homebrew formula is under `Formula/`.
