# Platform CLI

Public distribution of the Platform Developer CLI. Packages contain no organization
connection configuration. Obtain your connection command from your organization's
authenticated Platform Portal. Deployments require Entra sign-in and app Developer
membership; installing this CLI does not grant access.

## Install

macOS (Apple Silicon or Intel) and Linux x64:

```sh
curl -fsSL https://raw.githubusercontent.com/pqs-ch/platform-cli/main/install.sh | sh
```

Windows x64 or ARM64, in PowerShell:

```powershell
irm https://raw.githubusercontent.com/pqs-ch/platform-cli/main/install.ps1 | iex
```

The scripts download the latest stable release and verify its SHA-256 checksum.
They install for the current user without administrator privileges. On macOS and
Linux, reopen your terminal if the installer adds the CLI directory to your shell
profile. Rerun the same command to upgrade; your connections are preserved.
On Windows, the installer selects the native OS architecture, including when
PowerShell runs under emulation on ARM64.

Install a specific version (also supports rollback):

```sh
curl -fsSL https://raw.githubusercontent.com/pqs-ch/platform-cli/main/install.sh | sh -s -- --version v1.2.3
```

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/pqs-ch/platform-cli/main/install.ps1))) -Version v1.2.3
```

There must be a published release before installation works. Docker with buildx
is a separate prerequisite for building app images. The Go CLI is a native
executable; Developers do not need a language SDK, Azure CLI or registry credentials.

### Linux and WSL prerequisites

Linux sign-in requires a running D-Bus user session and an unlocked Secret Service
keyring, such as GNOME Keyring. The CLI uses D-Bus directly; no libsecret C library
is needed. On Ubuntu/Debian, install the keyring and D-Bus session packages if your
environment does not already provide them:

```sh
sudo apt update
sudo apt install gnome-keyring dbus-user-session
```

Other distributions use their equivalent packages. Package installation alone
does not establish a running, unlocked keyring. Configure and unlock the keyring
through your distribution's user-session setup before running API commands.

WSL uses Linux token storage; it does not use the Windows credential store.
Minimal WSL installations may have no D-Bus user session or keyring even after
the keyring packages are installed. Ensure the CLI runs in the same user session as the
keyring, with the keyring unlocked. If you cannot provide these services in WSL,
install and run the Windows CLI from PowerShell instead; Docker must be available
there when building application images.

WSL also needs a browser launcher for interactive sign-in. On Ubuntu WSL, install
`wslu` to provide `wslview`, which opens links in the Windows browser:

```sh
sudo apt install wslu
xdg-open https://login.microsoftonline.com
```

If the package is unavailable, follow the
[wslu distribution installation instructions](https://wslutiliti.es/wslu/install.html).
Check that the command opens the browser from the same terminal where you run
the CLI. If `wslview https://login.microsoftonline.com` works but `xdg-open` does
not, configure the user browser association with
`xdg-settings set default-web-browser wslview.desktop` (`xdg-utils` supplies these
XDG commands). Keep the CLI running while completing browser sign-in so it can
receive the localhost callback. After connecting, run
`platform status --reauthenticate` from your app repository to verify sign-in.

If sign-in reports that secure token storage is unavailable, restore these
prerequisites and retry. Unencrypted token storage is disabled, and the CLI does
not fall back to plaintext tokens. `--reauthenticate` cannot fix unavailable
secure storage. After connecting, run `platform status` from your app repository
to check sign-in before deploying.

## Configure and deploy

The CLI saves sign-in in an OS-protected token cache. After the first sign-in,
commands reuse or silently refresh the session; Entra policy or consent may still
require authentication. Developer and Operator sessions are separate, and each
environment/connection has its own cache. Add `--reauthenticate` to an API command
to sign in again or switch accounts, for example `platform status --reauthenticate`.
Unencrypted token storage is disabled; an available OS-protected storage backend
is required. Rerun the installer to upgrade; saved connections are preserved.

Terminal output uses aligned summaries, labeled details,
readable UTC timestamps and memory units, and layouts for narrow terminals.
Shared images are printed once with references; full IDs remain copyable.
Deployment progress shows state changes followed by one complete result.
Use `--json` for machine-readable response output.

Inspect application status, deployment history and resource metrics:

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
go to stderr. These commands require app Developer membership. Recorded deployment
success and current app health are separate observations. Missing or delayed
metrics do not establish zero activity or a stopped app.

Discover running replicas and open interactive consoles:

```sh
platform replicas --component web
platform exec --component web --replica <id>
platform replicas --component worker:background --environment production
platform exec --component worker:background --replica <id> --environment production \
  --executable /app/console
```

Component is required. Exec selects the only running replica when `--replica`
is omitted, lists IDs and exits when multiple replicas are running, and reports
none available when there are zero. Use `--replica <id>` from discovery to select
explicitly. Exec always
opens an interactive terminal, defaults to `/bin/sh`, and accepts a single
installed shell/console executable override. Ctrl+C interrupts that process;
Ctrl+] disconnects. Once selected, the session stays pinned to that replica and
never reconnects or falls back to another.
Developer-group membership and the environment's enabled-write gate authorize
console access through the Platform API. The Operator must apply the app's
updated console permissions. Exec requires interactive terminal input and output;
Terminal modes are handled natively; Windows requires VT support. The console runs with
the app's runtime permissions and can change its data. Rerun the installer to
upgrade; saved connections are preserved.

Sign in to your organization's Portal and open **CLI setup**. Copy and run its
`platform connect` command once for each environment you need. Use only connection
values provided by your trusted Operator or Portal.

Lock commands use the app's Developer session by default:

```sh
platform lock status
platform lock release --operation <operation-id> --reason "Reviewed deployment and data; safe to retry"
```

Developers can release only a completed, settled deployment after the API verifies
that provisioning and migration work is no longer running. Missing records,
partial activation and uncertain outcomes require Operator review. Add `--operator`
to either lock command to select the separate Operator sign-in session. The API
checks app Developer or environment Operator membership on every request. Release
does not repair data or undo a migration, and never removes a teardown lock.

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
