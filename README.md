# Dev Container Features

A collection of community-maintained Dev Container Features.

## Codex Dev Container Feature

An independent, community-maintained [Dev Container Feature](https://containers.dev/implementors/features/)
for installing the Codex CLI and the `openai.chatgpt` VS Code extension with
persistent Codex state.

## Usage

Add the Feature to `.devcontainer/devcontainer.json`:

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/kirilllivanov/devcontainer-features/codex:1": {}
    }
}
```

The default configuration installs the latest Codex CLI and VS Code extension
and stores Codex state in a volume scoped to the dev container.

See the [Codex Feature documentation](src/codex/README.md) for all options,
version pinning, persistent storage behavior, host-mounted authentication and
configuration files, and security considerations.

## Features

- Installs the Codex CLI with the upstream standalone installer.
- Installs the `openai.chatgpt` extension after VS Code attaches.
- Installs common repository tools such as Git, ripgrep, fd, jq, tree, rsync,
  SSH, and archive utilities.
- Persists `~/.codex` in a per-dev-container volume, shared named volume, or
  host-mounted directory.
- Supports a complete host-mounted Codex home with configurable ownership and
  permission handling.

## Repository structure

```text
.
├── src/codex/       Feature metadata, scripts, and documentation
├── test/codex/      Dev Container Feature scenarios
├── test/unit/       Installer and configuration unit tests
└── scripts/         Local validation and dependency setup
```

Each Feature directory follows the Dev Container Feature layout and contains
at least `devcontainer-feature.json` and `install.sh`. Additional documentation
is maintained in `NOTES.md`; the release workflow merges it into the generated
Feature `README.md`.

## Development

The repository dev container includes the required development tools. To
prepare another supported Linux environment, run:

```sh
npm run setup
```

Run metadata validation, JSON checks, ShellCheck, unit tests, and Feature
packaging:

```sh
npm run check
```

Run all unit tests and every Feature against every image declared in the
repository scenarios with a Docker-compatible container runtime:

```sh
npm test
```

Limit the run to a specific Feature, image, or both:

```sh
npm test -- --feature codex
npm test -- --image ubuntu:24.04
npm test -- --feature codex --image alpine:3.23
```

## Release

The manually dispatched release workflow publishes the Feature as an OCI
artifact to GitHub Container Registry and opens a pull request containing the
generated Feature documentation. Releases are accepted only from the `main`
branch.

## Disclaimer

This is an independent community-maintained Dev Container Feature and is not
affiliated with, sponsored by, or endorsed by OpenAI.

Codex is developed by OpenAI. The Codex CLI is licensed separately under the
Apache License 2.0, and the Codex IDE extension is distributed separately by
OpenAI.

OpenAI, ChatGPT, Codex, and related names and marks are the property of OpenAI.

## License

This project is licensed under the [MIT License](LICENSE).
