# dotfiles

Personal macOS dotfiles — batteries included.

## Install

```bash
bash <(curl -fsSL https://dotfiles.rifuki.dev/macos/install.sh)
```

> Uses `bash <()` instead of `curl | bash` to preserve interactive TTY for Homebrew password prompt.

> Restart terminal or run `exec zsh` after install.

## Uninstall

```bash
bash <(curl -fsSL https://dotfiles.rifuki.dev/macos/uninstall.sh)
```

### Remove Homebrew completely

```bash
bash ~/.dotfiles/uninstall-brew.sh
```

## What's included

### Tools
| Tool | Description |
|------|-------------|
| [Neovim](https://neovim.io) | Text editor |
| [Tmux](https://github.com/tmux/tmux) | Terminal multiplexer |
| [Oh My Zsh](https://ohmyz.sh) | Zsh framework |
| [Starship](https://starship.rs) | Cross-shell prompt |
| [NVM](https://github.com/nvm-sh/nvm) | Node version manager (Node 24) |
| [Bun](https://bun.sh) | JavaScript runtime & package manager |
| [Rust](https://rustup.rs) | Rust toolchain (stable) |
| [Yazi](https://github.com/sxyazi/yazi) | Terminal file manager |
| [Yabai](https://github.com/asmvik/yabai) | Tiling window manager |
| [Skhd](https://github.com/asmvik/skhd) | Hotkey daemon |
| [Ghostty](https://ghostty.org) | Terminal emulator |
| [gh](https://cli.github.com) | GitHub CLI |
| [trash](https://github.com/sindresorhus/trash-cli) | Safe `rm` replacement |
| [htop](https://htop.dev) | Process viewer |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | Fast search tool |
| [neofetch](https://github.com/dylanaraps/neofetch) | System info |
| [OrbStack](https://orbstack.dev) | Docker & Linux VM runtime |
| [Cloudflare WARP](https://one.one.one.one) | VPN client |
| [Hot](https://formulae.brew.sh/cask/hot) | Menu bar thermal monitor |
| [Google Chrome](https://www.google.com/chrome) | Browser |
| [JetBrainsMono Nerd Font](https://www.nerdfonts.com) | Patched developer font |

### Configs
- `nvim` — NvChad-based config with LSP, Treesitter, and plugins
- `tmux` — Catppuccin theme, TPM plugins
- `starship` — Custom prompt config
- `ghostty` — Terminal emulator config
- `yabai` + `skhd` — Tiling window manager + hotkeys
- `neofetch` — System info display
- `.zshrc` — Shell config (PATH, aliases, plugins)

## Post-Installation (Yabai & Skhd)

After install, manually set up Yabai and Skhd:

**Yabai:**
1. Configure scripting addition (if SIP disabled):
   ```bash
   echo "$(whoami) ALL=(root) NOPASSWD: sha256:$(shasum -a 256 $(which yabai) | cut -d " " -f 1) $(which yabai) --load-sa" | sudo tee /private/etc/sudoers.d/yabai
   ```
2. Make sure `yabairc` has: `yabai -m signal --add event=dock_did_restart action="sudo yabai --load-sa"`
3. Run: `yabai --start-service`
4. When prompted, allow Yabai in **System Settings → Privacy & Security → Accessibility**

**Skhd:**
1. Run: `skhd --start-service`
2. When prompted, allow Skhd in **System Settings → Privacy & Security → Accessibility**
3. Disable **Secure Keyboard Entry** in Terminal if needed

## Re-run / Update

Re-running `install.sh` is safe:
- Interactive checklist lets you pick which components to install
- Already-installed tools are detected and shown in the menu
- Local config changes are **backed up** to `~/.config/backup-TIMESTAMP/`
- Dotfiles are **restored** to the latest remote state

## Structure

```
~/.dotfiles/
├── .config/
│   ├── nvim/
│   ├── tmux/
│   ├── starship/
│   ├── ghostty/
│   ├── yabai/
│   ├── skhd/
│   └── neofetch/
├── .zshrc
├── .hyper.js
├── install.sh
├── uninstall.sh
└── uninstall-brew.sh
```

All configs are symlinked from `~/.dotfiles` to their respective locations in `$HOME`.
