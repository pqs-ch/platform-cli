#!/bin/sh
set -eu

repository="https://github.com/pqs-ch/platform-cli"
version="latest"
if [ "$#" -gt 0 ]; then
    [ "$#" -eq 2 ] && [ "$1" = "--version" ] || { echo "Usage: install.sh [--version v1.2.3]" >&2; exit 1; }
    version="$2"
fi
command -v curl >/dev/null || { echo "curl is required." >&2; exit 1; }
case "$(uname -s)/$(uname -m)" in
    Darwin/arm64) rid=osx-arm64 ;;
    Darwin/x86_64) rid=osx-x64 ;;
    Linux/x86_64) rid=linux-x64 ;;
    *) echo "Unsupported system. Supported: macOS ARM64/Intel and Linux x64 (glibc)." >&2; exit 1 ;;
esac
if [ "$version" = latest ]; then
    resolved=$(curl --proto '=https' --tlsv1.2 -fsSL -o /dev/null -w '%{url_effective}' "$repository/releases/latest")
    version=${resolved##*/}
fi
printf '%s\n' "$version" | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+$' || { echo "Version must be vMAJOR.MINOR.PATCH." >&2; exit 1; }
root="$HOME/.local/share/platform-cli"
bin="$HOME/.local/bin"
mkdir -p "$root/versions" "$bin"
stage=$(mktemp -d "$root/.install.XXXXXX")
trap 'rm -rf "$stage"' EXIT HUP INT TERM
asset="platform-$rid.tar.gz"
url="$repository/releases/download/$version"
curl --proto '=https' --tlsv1.2 -fsSL "$url/$asset" -o "$stage/$asset"
curl --proto '=https' --tlsv1.2 -fsSL "$url/SHA256SUMS" -o "$stage/SHA256SUMS"
expected=$(awk -v file="$asset" '$2 == file {print $1}' "$stage/SHA256SUMS")
printf '%s\n' "$expected" | grep -Eq '^[0-9a-fA-F]{64}$' || { echo "Missing or ambiguous checksum." >&2; exit 1; }
if command -v sha256sum >/dev/null; then
    actual=$(sha256sum "$stage/$asset" | awk '{print $1}')
else
    actual=$(shasum -a 256 "$stage/$asset" | awk '{print $1}')
fi
[ "$actual" = "$expected" ] || { echo "Checksum verification failed." >&2; exit 1; }
mkdir "$stage/package"
tar -xzf "$stage/$asset" -C "$stage/package"
[ -f "$stage/package/platform" ] || { echo "Release does not contain platform." >&2; exit 1; }
chmod +x "$stage/package/platform"
"$stage/package/platform" --version
target="$root/versions/$version-$rid"
# Existing version directories are immutable; repeat installs reuse the verified version.
if [ ! -d "$target" ]; then mv "$stage/package" "$target"; fi
if [ -e "$bin/platform" ] && [ ! -L "$bin/platform" ]; then
    echo "$bin/platform already exists and is not a symlink. Move it before installing." >&2; exit 1
fi
ln -s "$target/platform" "$stage/platform"
mv -f "$stage/platform" "$bin/platform"
case ":$PATH:" in
    *":$bin:"*) ;;
    *)
        case "${SHELL:-}" in
            */zsh) profile="$HOME/.zshrc" ;;
            */bash) profile="$HOME/.bashrc" ;;
            */fish) profile="$HOME/.config/fish/conf.d/platform-cli.fish" ;;
            *) profile="$HOME/.profile" ;;
        esac
        mkdir -p "$(dirname "$profile")"
        if ! grep -q '# Platform CLI PATH' "$profile" 2>/dev/null; then
            case "$profile" in
                *.fish) printf '\n# Platform CLI PATH\nfish_add_path "$HOME/.local/bin"\n' >> "$profile" ;;
                *) printf '\n# Platform CLI PATH\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$profile" ;;
            esac
        fi
        echo "Added $bin to $profile. Open a new terminal to use platform."
        ;;
esac
echo "Installed Platform CLI $version. Obtain your connection command from your authenticated Platform Portal's CLI setup page."
