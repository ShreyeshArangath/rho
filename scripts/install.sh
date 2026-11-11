#!/bin/bash
set -euo pipefail

rho_install() {
    local rho_source="$1" rho_install_home="$2" rho_mode="$3" rho_shell="$4"
    local rho_app="$rho_install_home/Applications/rho.app"
    local rho_bin="$rho_install_home/.local/bin"
    local rho_replace=false rho_profile='' rho_path_line rho_existing_profile

    if [[ "$rho_mode" != cli && ( ! -d "$rho_app" || "$rho_mode" == update ) ]]; then
        if pgrep -x PrivateKeymapper >/dev/null; then
            echo 'Quit rho before installing or replacing the app. Use rho stop or Quit rho in the menu.' >&2
            return 1
        fi
        "$rho_source/scripts/build.sh"
        rho_replace=true
    else
        "$rho_source/scripts/build-cli.sh"
    fi

    if [[ "$rho_replace" == true ]]; then
        if pgrep -x PrivateKeymapper >/dev/null; then
            echo 'rho started during the build. Quit it before replacing the app.' >&2
            return 1
        fi
        mkdir -p "$rho_install_home/Applications"
        ditto "$rho_source/dist/rho.app" "$rho_app"
    elif [[ "$rho_mode" != cli ]]; then
        printf 'Kept existing app: %s (use --update to replace it).\n' "$rho_app"
    fi
    mkdir -p "$rho_bin"
    install -m 755 "$rho_source/dist/rho" "$rho_bin/rho"

    case ":$PATH:" in
        *":$rho_bin:"*) ;;
        *)
            case "${rho_shell##*/}" in
                zsh) rho_profile="${ZDOTDIR:-$rho_install_home}/.zshrc" ;;
                bash)
                    rho_profile="$rho_install_home/.bash_profile"
                    for rho_existing_profile in .bash_profile .bash_login .profile; do
                        if [[ -f "$rho_install_home/$rho_existing_profile" ]]; then
                            rho_profile="$rho_install_home/$rho_existing_profile"
                            break
                        fi
                    done
                    ;;
            esac
            printf -v rho_path_line 'export PATH=%q:"$PATH"' "$rho_bin"
            if [[ -n "$rho_profile" ]]; then
                if [[ ! -f "$rho_profile" ]] || ! grep -Fqx -- "$rho_path_line" "$rho_profile"; then
                    printf '\n# rho terminal command\n%s\n' "$rho_path_line" >> "$rho_profile"
                fi
                printf 'Open a new terminal to use rho. PATH is configured in %s.\n' "$rho_profile"
            else
                printf "Add %s to your shell's PATH.\n" "$rho_bin"
            fi
            ;;
    esac
    printf 'Installed command: %s/rho\n' "$rho_bin"
    if [[ "$rho_mode" != cli ]]; then
        open "$rho_app"
        if [[ "$rho_replace" == true ]]; then
            echo 'Allow rho in System Settings → Privacy & Security → Accessibility, then check rho status.'
        fi
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    rho_source_root="$(cd "$(dirname "$0")/.." && pwd)"
    case "${1:-}" in
        '') rho_mode=install ;;
        --cli-only) rho_mode=cli ;;
        --update) rho_mode=update ;;
        *) echo 'Usage: scripts/install.sh [--cli-only | --update]' >&2; exit 1 ;;
    esac
    if [[ $# -gt 1 ]]; then
        echo 'Usage: scripts/install.sh [--cli-only | --update]' >&2
        exit 1
    fi
    rho_install "$rho_source_root" "$HOME" "$rho_mode" "${SHELL:-/bin/zsh}"
fi
