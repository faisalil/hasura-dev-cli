# hasura-dev-cli

Distribution repo for prebuilt `hasura-dev` CLI binaries.

## Install via Homebrew

```bash
brew tap faisalil/hasura-dev
brew install hasura-dev
```

## Notes

- Binary is built from Hasura CLI fork with Docker-free dev runtime commands:
  - `hasura-dev server start-dev`
  - `hasura-dev server status`
  - `hasura-dev server stop`
- Engine manifest source is hardcoded to:
  - `https://github.com/faisalil/hasura-dev-assets/releases/download/%s/manifest.json`
