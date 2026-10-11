# Platform CLI

Public distribution of the Platform developer CLI. Packages contain no organization
connection configuration. Obtain your connection command from your organization's
authenticated Platform Portal. Deployments require Entra sign-in and app developer
membership; installing this CLI does not grant access.

## Install

macOS (Apple Silicon or Intel) and Linux x64 with glibc:

```sh
curl -fsSL https://raw.githubusercontent.com/pqs-ch/platform-cli/main/install.sh | sh
```

Windows x64, in PowerShell:

```powershell
irm https://raw.githubusercontent.com/pqs-ch/platform-cli/main/install.ps1 | iex
```

The scripts download the latest stable release and verify its SHA-256 checksum.
They install for the current user without administrator privileges. On macOS and
Linux, reopen your terminal if the installer adds the CLI directory to your shell
profile. Rerun the same command to upgrade; your connections are preserved.

Install a specific version (also supports rollback):

```sh
curl -fsSL https://raw.githubusercontent.com/pqs-ch/platform-cli/main/install.sh | sh -s -- --version v1.2.3
```

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/pqs-ch/platform-cli/main/install.ps1))) -Version v1.2.3
```

There must be a published release before installation works. Docker with buildx
is a separate prerequisite for building app images. The CLI includes its .NET
runtime; developers do not need the .NET SDK, Azure CLI or registry credentials.

## Configure and deploy

Release v0.1.5 improves terminal output with aligned summaries, labeled details,
readable UTC timestamps and memory units, and layouts for narrow terminals.
Shared images are printed once with references; full IDs remain copyable.
Deployment progress shows state changes followed by one complete result.
JSON response output is unchanged. Rerun the installer to upgrade.

Release v0.1.4 adds application status, deployment history and resource metrics:

```sh
platform status
platform status --history
platform status <operation-id> --json
platform metrics --since 1h
platform metrics --component worker:background --environment production
platform metrics --component web --replica <id> --since 24h --json
```

Status combines current hosting observations with the recorded deployment result.
Metrics report CPU and memory percentages using each revision's allocation,
per-replica peaks, restart observations and web request/5xx data. Missing data is
reported explicitly. JSON stdout contains one response document; sign-in messages
go to stderr. These commands require app developer membership. See the
[status and metrics contract](https://github.com/pqs-ch/platform/blob/main/docs/status-metrics.md)
for aggregation, coverage and limitations.

CLI builds with interactive-console support also provide:

```sh
platform replicas --component web
platform exec --component web --replica <id>
platform replicas --component worker:background --environment production
platform exec --component worker:background --replica <id> --environment production \
  --executable /app/console
```

Component is required. Release v0.1.4 selects the only running replica when
`--replica` is omitted, list IDs and exit when multiple replicas are running, and
report none available when there are zero. Use `--replica <id>` from discovery
to select explicitly; v0.1.3 requires this option even for one replica. Exec always
opens an interactive terminal, defaults to `/bin/sh`, and accepts a single
installed shell/console executable override. Ctrl+C interrupts that process;
Ctrl+] disconnects. Once selected, the session stays pinned to that replica and
never reconnects or falls back to another.
Developer-group membership and the environment's enabled-write gate authorize
console access through the Platform API. The operator must apply the app's
updated console permissions. See the Platform repository's
[interactive console contract](https://github.com/pqs-ch/platform/blob/main/docs/development.md#interactive-consoles)
for requirements and behavior. Release v0.1.3 includes these commands. Rerun the
installer to upgrade older binaries; existing saved connections are preserved.

Sign in to your organization's Portal and open **CLI setup**. Copy and run its
`platform connect` command once for each environment you need. Use only connection
values provided by your trusted operator or Portal.

Run from your app repository, containing `platform.app.yaml` and `Dockerfile`:

```sh
platform --version
platform validate
platform deploy
platform deploy --environment production
```

Test is the default. Deployment permissions are checked independently for each
environment. Connections live in the user configuration directory, separately
from the executable and app repository. `--connection <file>` can select an explicit
operator-provided connection for automation.

## Remove

Windows: remove `%LOCALAPPDATA%\PlatformCli` and its `bin` entry from your user PATH.
macOS/Linux: remove `~/.local/bin/platform`, `~/.local/share/platform-cli` and the
installer's `# Platform CLI PATH` block from your shell profile if it added one.
These actions leave connection configuration intact. To also remove connections,
delete `%LOCALAPPDATA%\Platform` on Windows, `~/Library/Application Support/Platform`
on macOS or `${XDG_CONFIG_HOME:-~/.config}/platform` on Linux.

This repository contains installers and release packages; it does not contain the
Platform service source or deployment configuration.
