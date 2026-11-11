#!/bin/bash
set -euo pipefail
unset ZDOTDIR
rho_repo="$(cd "$(dirname "$0")/.." && pwd)"
rho_scratch="$(mktemp -d "${TMPDIR:-/tmp}/rho-installer-tests.XXXXXX")"
trap 'rm -rf -- "$rho_scratch"' EXIT
rho_fixture="$rho_scratch/source tree"
rho_test_home="$rho_scratch/home with 'quotes'"
mkdir -p "$rho_fixture/scripts" "$rho_scratch/bin" "$rho_test_home"

cat > "$rho_fixture/scripts/build-cli.sh" <<'BUILD'
#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p dist
printf '#!/bin/bash\nprintf "fixture rho command\\n"\n' > dist/rho
chmod +x dist/rho
BUILD
cat > "$rho_fixture/scripts/build.sh" <<'BUILD'
#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p dist/rho.app/Contents/MacOS
printf 'new app\n' > dist/rho.app/Contents/MacOS/PrivateKeymapper
./scripts/build-cli.sh
if [[ -n "${RHO_TEST_STARTED_FILE:-}" ]]; then touch "$RHO_TEST_STARTED_FILE"; fi
BUILD
cat > "$rho_scratch/bin/pgrep" <<'COMMAND'
#!/bin/bash
if [[ -n "${RHO_TEST_STARTED_FILE:-}" && -f "$RHO_TEST_STARTED_FILE" ]]; then exit 0; fi
exit "${RHO_TEST_PGREP_EXIT:-1}"
COMMAND
cat > "$rho_scratch/bin/open" <<'COMMAND'
#!/bin/bash
printf '%s\n' "$1" >> "$RHO_TEST_OPEN_LOG"
COMMAND
chmod +x "$rho_fixture/scripts/"*.sh "$rho_scratch/bin/"*
export RHO_TEST_OPEN_LOG="$rho_scratch/open.log"

rho_test_install() {
    PATH="$rho_scratch/bin:$PATH" bash -c 'source "$1/scripts/install.sh"; rho_install "$2" "$3" "$4" "$5"' \
        _ "$rho_repo" "$rho_fixture" "$rho_test_home" "$1" "${2:-/bin/zsh}"
}

printf 'export RHO_USER_SETTING=preserved\n' > "$rho_test_home/.zshrc"
mkdir -p "$rho_test_home/Library/Application Support/PrivateKeymapper"
printf 'existing user settings\n' > "$rho_scratch/settings.expected"
cp "$rho_scratch/settings.expected" "$rho_test_home/Library/Application Support/PrivateKeymapper/config.json"
rho_test_install install >/dev/null
[[ "$(cat "$rho_test_home/Applications/rho.app/Contents/MacOS/PrivateKeymapper")" == 'new app' ]]
[[ "$("$rho_test_home/.local/bin/rho" --help)" == 'fixture rho command' ]]
[[ "$(stat -f '%Lp' "$rho_test_home/.local/bin/rho")" == 755 ]]
[[ "$(/bin/zsh -f -c 'source "$1"; print -r -- "$RHO_USER_SETTING"; command -v rho' _ "$rho_test_home/.zshrc")" == $'preserved\n'"$rho_test_home/.local/bin/rho" ]]
cmp "$rho_scratch/settings.expected" "$rho_test_home/Library/Application Support/PrivateKeymapper/config.json"
echo 'PASS installer: fresh app, executable CLI, shell PATH, and existing settings'

printf 'approved app\n' > "$rho_test_home/Applications/rho.app/Contents/MacOS/PrivateKeymapper"
cp "$rho_test_home/.zshrc" "$rho_scratch/profile.expected"
RHO_TEST_PGREP_EXIT=0 rho_test_install install >/dev/null
[[ "$(cat "$rho_test_home/Applications/rho.app/Contents/MacOS/PrivateKeymapper")" == 'approved app' ]]
cmp "$rho_scratch/profile.expected" "$rho_test_home/.zshrc"
cmp "$rho_scratch/settings.expected" "$rho_test_home/Library/Application Support/PrivateKeymapper/config.json"
echo 'PASS installer: repeated install preserves approved app, profile, and config'

cp "$RHO_TEST_OPEN_LOG" "$rho_scratch/open.expected"
RHO_TEST_PGREP_EXIT=0 rho_test_install cli >/dev/null
cmp "$rho_scratch/open.expected" "$RHO_TEST_OPEN_LOG"
[[ "$(cat "$rho_test_home/Applications/rho.app/Contents/MacOS/PrivateKeymapper")" == 'approved app' ]]
echo 'PASS installer: CLI-only install does not replace or open the app'

if RHO_TEST_PGREP_EXIT=0 rho_test_install update >/dev/null 2>&1; then
    echo 'FAIL installer: update must refuse a running app' >&2; exit 1
fi
[[ "$(cat "$rho_test_home/Applications/rho.app/Contents/MacOS/PrivateKeymapper")" == 'approved app' ]]
rho_test_install update >/dev/null
[[ "$(cat "$rho_test_home/Applications/rho.app/Contents/MacOS/PrivateKeymapper")" == 'new app' ]]
cmp "$rho_scratch/settings.expected" "$rho_test_home/Library/Application Support/PrivateKeymapper/config.json"
echo 'PASS installer: explicit update requires a stopped app and preserves settings'

printf 'approved app\n' > "$rho_test_home/Applications/rho.app/Contents/MacOS/PrivateKeymapper"
if RHO_TEST_STARTED_FILE="$rho_scratch/started" rho_test_install update >/dev/null 2>&1; then
    echo 'FAIL installer: update must recheck running state after the build' >&2; exit 1
fi
[[ "$(cat "$rho_test_home/Applications/rho.app/Contents/MacOS/PrivateKeymapper")" == 'approved app' ]]
echo 'PASS installer: app starting during build prevents replacement'

rho_test_home="$rho_scratch/bash home"
mkdir -p "$rho_test_home"
rho_test_install cli /bin/bash >/dev/null
[[ ! -e "$rho_test_home/Applications/rho.app" ]]
[[ "$(bash --noprofile --norc -c 'source "$1"; command -v rho' _ "$rho_test_home/.bash_profile")" == "$rho_test_home/.local/bin/rho" ]]
echo 'PASS installer: CLI-only first install and Bash PATH'

rho_test_home="$rho_scratch/profile home"
mkdir -p "$rho_test_home"
printf 'export RHO_USER_SETTING=preserved\n' > "$rho_test_home/.profile"
rho_test_install cli /bin/bash >/dev/null
[[ ! -e "$rho_test_home/.bash_profile" ]]
[[ "$(bash --noprofile --norc -c 'source "$1"; printf "%s\\n" "$RHO_USER_SETTING"; command -v rho' _ "$rho_test_home/.profile")" == $'preserved\n'"$rho_test_home/.local/bin/rho" ]]
echo 'PASS installer: existing Bash login profile remains in use'

mkdir -p "$rho_scratch/zsh config"
ZDOTDIR="$rho_scratch/zsh config" rho_test_install cli >/dev/null
[[ -f "$rho_scratch/zsh config/.zshrc" && ! -e "$rho_test_home/.zshrc" ]]
[[ "$(/bin/zsh -f -c 'source "$1"; command -v rho' _ "$rho_scratch/zsh config/.zshrc")" == "$rho_test_home/.local/bin/rho" ]]
echo 'PASS installer: exported ZDOTDIR receives the zsh PATH entry'

bash "$rho_repo/install.sh" --help >/dev/null
if bash "$rho_repo/install.sh" --update --cli-only >/dev/null 2>&1; then
    echo 'FAIL bootstrap: conflicting modes must fail' >&2; exit 1
fi
if bash "$rho_repo/install.sh" --ref >/dev/null 2>&1; then
    echo 'FAIL bootstrap: missing ref must fail' >&2; exit 1
fi
echo 'PASS bootstrap: help and invalid arguments'

cat > "$rho_scratch/bin/uname" <<'COMMAND'
#!/bin/bash
printf '%s\n' "${RHO_TEST_OS:-Linux}"
COMMAND
cat > "$rho_scratch/bin/sw_vers" <<'COMMAND'
#!/bin/bash
printf '%s\n' "${RHO_TEST_MACOS:-12.7}"
COMMAND
cat > "$rho_scratch/bin/xcode-select" <<'COMMAND'
#!/bin/bash
exit 1
COMMAND
chmod +x "$rho_scratch/bin/uname" "$rho_scratch/bin/sw_vers" "$rho_scratch/bin/xcode-select"
if PATH="$rho_scratch/bin:$PATH" bash "$rho_repo/install.sh" > "$rho_scratch/preflight.log" 2>&1; then
    echo 'FAIL bootstrap: non-macOS must fail' >&2; exit 1
fi
grep -q 'rho requires macOS 13' "$rho_scratch/preflight.log"
if PATH="$rho_scratch/bin:$PATH" RHO_TEST_OS=Darwin bash "$rho_repo/install.sh" > "$rho_scratch/preflight.log" 2>&1; then
    echo 'FAIL bootstrap: macOS before 13 must fail' >&2; exit 1
fi
grep -q 'rho requires macOS 13' "$rho_scratch/preflight.log"
if PATH="$rho_scratch/bin:$PATH" RHO_TEST_OS=Darwin RHO_TEST_MACOS=13.0 bash "$rho_repo/install.sh" > "$rho_scratch/preflight.log" 2>&1; then
    echo 'FAIL bootstrap: missing developer tools must fail' >&2; exit 1
fi
grep -q 'xcode-select --install' "$rho_scratch/preflight.log"
echo 'PASS bootstrap: unsupported systems and missing developer tools fail with instructions'

cat > "$rho_scratch/bin/xcode-select" <<'COMMAND'
#!/bin/bash
exit 0
COMMAND
cp "$rho_scratch/bin/xcode-select" "$rho_scratch/bin/xcrun"
cat > "$rho_scratch/bin/curl" <<'COMMAND'
#!/bin/bash
if [[ "${RHO_TEST_CURL_FAIL:-0}" == 1 ]]; then exit 22; fi
while [[ $# -gt 0 ]]; do
    if [[ "$1" == -o ]]; then cp "$RHO_TEST_ARCHIVE" "$2"; exit 0; fi
    shift
done
exit 1
COMMAND
chmod +x "$rho_scratch/bin/xcrun" "$rho_scratch/bin/curl"
rho_archive_tree="$rho_scratch/archive/rho-main"
mkdir -p "$rho_archive_tree/scripts" "$rho_scratch/downloads"
cp "$rho_repo/install.sh" "$rho_archive_tree/install.sh"
cp "$rho_repo/Package.swift" "$rho_archive_tree/Package.swift"
cp "$rho_fixture/scripts/"*.sh "$rho_archive_tree/scripts/"
cat > "$rho_archive_tree/scripts/install.sh" <<'INSTALL'
#!/bin/bash
set -euo pipefail
source "$RHO_TEST_REPO/scripts/install.sh"
[[ "${1:-}" == --cli-only ]]
rho_install "$(cd "$(dirname "$0")/.." && pwd)" "$RHO_TEST_DESTINATION" cli /bin/zsh
INSTALL
chmod +x "$rho_archive_tree/install.sh" "$rho_archive_tree/scripts/install.sh"
tar -czf "$rho_scratch/source.tar.gz" -C "$rho_scratch/archive" rho-main
export RHO_TEST_ARCHIVE="$rho_scratch/source.tar.gz" RHO_TEST_REPO="$rho_repo"
export RHO_TEST_OS=Darwin RHO_TEST_MACOS=13.0
export RHO_TEST_DESTINATION="$rho_scratch/piped destination"
PATH="$rho_scratch/bin:$PATH" TMPDIR="$rho_scratch/downloads" bash -s -- --cli-only < "$rho_repo/install.sh" >/dev/null
[[ "$("$RHO_TEST_DESTINATION/.local/bin/rho")" == 'fixture rho command' ]]
[[ -z "$(ls -A "$rho_scratch/downloads")" ]]
echo 'PASS bootstrap: piped source download, archive modes, handoff, and cleanup'

export RHO_TEST_DESTINATION="$rho_scratch/checkout destination"
PATH="$rho_scratch/bin:$PATH" RHO_TEST_CURL_FAIL=1 bash "$rho_archive_tree/install.sh" --cli-only >/dev/null
[[ "$("$RHO_TEST_DESTINATION/.local/bin/rho")" == 'fixture rho command' ]]
echo 'PASS bootstrap: local checkout installs without a download'

if PATH="$rho_scratch/bin:$PATH" TMPDIR="$rho_scratch/downloads" RHO_TEST_CURL_FAIL=1 bash -s -- --cli-only < "$rho_repo/install.sh" >/dev/null 2>&1; then
    echo 'FAIL bootstrap: download failure must fail installation' >&2; exit 1
fi
[[ -z "$(ls -A "$rho_scratch/downloads")" ]]
echo 'PASS bootstrap: failed downloads also clean only owned temporary files'
