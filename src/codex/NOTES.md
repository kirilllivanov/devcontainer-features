## Version selection

The CLI and extension options support the same sentinel values:

- `latest` installs the latest available upstream release.
- An exact version pins the component to that release.
- `none` skips installation of that component.

The CLI is installed with OpenAI's standalone installer, not npm.

## Configuration example

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/kirilllivanov/devcontainer-features/codex:1": {
            "cliVersion": "latest",
            "extensionVersion": "latest",
            "volumePath": "/run/codex/per-container",
            "fixPermissions": true,
            "permissionsOwner": "auto",
            "directoryMode": "auto",
            "fileMode": "auto"
        }
    }
}
```

`CODEX_HOME` always points to `/run/codex/active`. At container start that
stable path is linked to the configured `volumePath`. The remote user's
`~/.codex` is also linked to the stable path.

## Codex storage path

`volumePath` is the single storage selector and must be an absolute container
path. The Feature declares two named volumes at fixed locations:

- `/run/codex/per-container` is backed by
  `vscode-devcontainer-codex-${devcontainerId}` and is selected by default.
- `/run/codex/shared` is backed by the collection-wide
  `vscode-devcontainer-codex-shared` volume.
- `/workspaces/.codex` stores state in the persistent `/workspaces` mount
  provided by GitHub Codespaces. The Feature creates the `.codex` directory on
  first container start, and its contents survive container rebuilds within
  that codespace.

Both named volumes are attached because Feature options cannot conditionally
change declarative mounts. Only the path selected by `volumePath` is exposed
through `CODEX_HOME`; the other volume remains dormant.

Apart from the GitHub Codespaces path above, any other absolute path is treated
as user-managed storage. The user must make that directory available with a
dev-container mount before the post-start hook runs. The directory is used as
the complete Codex home, including credentials, configuration, history,
sessions, skills, and caches.

`/workspaces/.codex` is scoped to one codespace. It survives both regular and
full container rebuilds, but it is deleted when the codespace itself is
deleted. Outside GitHub Codespaces, use this option only when `/workspaces` is
provided as a persistent mount.

## Security

The selected storage contains the complete Codex home, including credentials,
configuration, command history, sessions, skills, and caches. Use the default
per-container volume unless the containers and users sharing the storage are
within the same trust boundary.

The shared volume is mounted into every container that uses this Feature, even
when it is not selected by `volumePath`. With the automatic permission profile,
its directories and files are readable and writable by every user in those
containers. Do not store credentials in the shared volume when any of the
containers or users are untrusted.

For host-mounted storage, permission correction can change ownership and modes
on the host source. Review the settings in
[Ownership and permissions](#ownership-and-permissions) before mounting an
existing Codex home.

## External directory example

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/kirilllivanov/devcontainer-features/codex:1": {
            "volumePath": "/run/codex/external"
        }
    },
    "mounts": [
        "source=${localEnv:HOME}/.codex,target=/run/codex/external,type=bind"
    ]
}
```

Dev Container Features cannot derive the host source dynamically. The bind
mount must therefore be declared by the user in `devcontainer.json`.

On Windows hosts, use `${localEnv:USERPROFILE}` and forward slashes:

```jsonc
"source=${localEnv:USERPROFILE}/.codex,target=/run/codex/external,type=bind"
```

## Ownership and permissions

At every container start, `fixPermissions` controls whether the selected
storage is updated recursively. Its default is `true`.

With automatic settings, the selected path determines the profile:

- `/run/codex/shared` preserves existing ownership and applies `a+rwX` to
  directories and regular files. Directories become accessible to all users,
  normal files become `0666`, and existing executable files remain executable.
- Every other path, including per-container and external storage, is assigned
  to the remote user's numeric UID and GID. `u+rwX,go-rwx` makes the content
  private while preserving existing executable bits.

The recursive operation processes directories and regular files only. It does
not follow symbolic links and does not cross into nested filesystems.

For explicit control, set a chown-compatible owner and octal modes:

```jsonc
{
    "volumePath": "/run/codex/external",
    "fixPermissions": true,
    "permissionsOwner": "1000:1000",
    "directoryMode": "0750",
    "fileMode": "0640"
}
```

`permissionsOwner` also accepts `none` to preserve ownership. Be aware that an
explicit numeric `fileMode` replaces executable bits on every regular file.
Use `auto` when executable scripts must remain executable.

To prevent all ownership and mode changes:

```jsonc
{
    "volumePath": "/run/codex/external",
    "fixPermissions": false
}
```

The Feature still verifies that the selected directory exists and is readable,
writable, and searchable by the remote user.

On Linux, `chown` and `chmod` on a bind mount change the source directory on
the host. Docker Desktop filesystems may emulate this behavior. Use explicit
settings or disable permission correction when host ownership and modes must
remain unchanged.

## VS Code extension installation

Feature options cannot dynamically change
`customizations.vscode.extensions`. The requested extension version is
therefore installed by `postAttachCommand`. The hook uses the remote `code` CLI
when it is available in the lifecycle environment, then falls back to the
installed VS Code Server CLI. Clients that provide neither CLI skip this step.
If an older VS Code client does not activate a newly installed extension
immediately, reattach to the container once.

## References

- [Codex CLI](https://learn.chatgpt.com/docs/codex/cli)
- [Codex IDE extension](https://learn.chatgpt.com/docs/codex/ide)
- [Dev Container Features specification](https://github.com/devcontainers/spec/blob/main/docs/specs/devcontainer-features.md)
- [Authoring a Dev Container Feature](https://containers.dev/guide/author-a-feature)
- [Feature authoring best practices](https://containers.dev/guide/feature-authoring-best-practices)

## Disclaimer

This is an independent community-maintained Dev Container Feature and is not
affiliated with, sponsored by, or endorsed by OpenAI.

Codex is developed by OpenAI. The Codex CLI is licensed separately under the
Apache License 2.0, and the Codex IDE extension is distributed separately by
OpenAI.

OpenAI, ChatGPT, Codex, and related names and marks are the property of OpenAI.
