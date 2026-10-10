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
