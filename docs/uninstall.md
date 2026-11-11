[rho](../README.md) · [Wiki](README.md) · Uninstall

# Uninstall rho

If you used a legacy Caps Lock version, complete [legacy recovery](troubleshooting.md#recover-a-legacy-caps-lock-mapping) before removing saved settings.

1. Turn off **Launch at Login** in the **ρ** menu.
2. Choose **Quit rho**, or run `rho stop`.
3. Remove rho from **System Settings → Privacy & Security → Accessibility**.
4. Move `~/Applications/rho.app` to the Trash.
5. Remove `~/.local/bin/rho`.

Pause and Quit release synthetic keys and stop keyboard interception.
Current rho installs no privileged helper, launch daemon, or system key mapping.

## Keep or remove settings

Keep `~/Library/Application Support/PrivateKeymapper` if you want to retain your shortcuts for a later installation.
After any legacy recovery succeeds, you can remove the folder to delete the saved configuration and recovery data.

The installer may have added `~/.local/bin` to your [shell startup file](installation.md#path-and-source-selection).
Keep that PATH entry if you use the directory for other commands.
If you remove it, preserve the rest of your shell configuration.

See [installation](installation.md) to reinstall rho.
