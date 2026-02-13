# dotfiles

Personal macOS dotfiles — batteries included. ✨ Miku cyberpunk themed.

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

### Blockchain Tools (optional)
| Tool | Description |
|------|-------------|
| [Solana](https://solana.com) | Solana CLI + development tools |
| [Anchor](https://www.anchor-lang.com) | Solana framework (via AVM) |
| [suiup](https://sui.io) | Sui version manager |
| [sui-move-analyzer](https://github.com/movebit/sui-move-analyzer) | Sui Move LSP (~10min build) |

### AI Tools (optional)
| Tool | Description |
|------|-------------|
| [Claude Code](https://github.com/anthropics/claude-code) | AI-powered CLI (via Homebrew cask) |
| [Gemini CLI](https://ai.google.dev) | Google Gemini CLI (via Homebrew) |

### Configs
- `nvim` — NvChad-based config with LSP, Treesitter, and plugins
- `tmux` — Catppuccin Frappé theme, TPM plugins (resurrect, continuum, cpu, battery)
- `starship` — Miku cyberpunk prompt theme (cyan/green/magenta palette)
- `ghostty` — Terminal emulator config
- `yabai` + `skhd` — Tiling window manager + hotkeys
- `neofetch` — Custom Miku ASCII art + system info
- `.zshrc` — Miku-themed syntax highlighting, aliases, PATH setup
- `.claude/` — Claude Code statusline integration with Starship colors

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
│   ├── nvim/          # NvChad config + LSP + plugins
│   ├── tmux/          # Catppuccin theme + plugins
│   ├── starship/      # Miku cyberpunk prompt
│   ├── ghostty/       # Terminal config
│   ├── yabai/         # Window manager
│   ├── skhd/          # Hotkey daemon
│   └── neofetch/      # Miku ASCII art + config
├── .claude/
│   └── statusline-command.sh  # Claude Code integration
├── .zshrc             # Miku-themed shell config
├── .hyper.js          # Hyper terminal config
├── install.sh         # Interactive installer (Miku colors)
├── uninstall.sh       # Interactive uninstaller (Miku colors)
├── macos-defaults.sh  # macOS system defaults
└── uninstall-brew.sh  # Complete Homebrew removal
```

All configs are symlinked from `~/.dotfiles` to their respective locations in `$HOME`.

## Theme

**Miku Cyberpunk Color Palette** (used in Starship, Zsh, installer/uninstaller):
- Cyan: `#00D9FF` — Commands, time, headers
- Green: `#50FA7B` — Paths, success messages
- Magenta: `#FF79C6` — Git branches, selected items
- Purple: `#BD93F9` — Builtins
- Teal: `#01CBC6` — Aliases
- Orange: `#FFB86C` — Path alternates
- Peach: `#F0CAA4` — Status, warnings
- Gray: `#6C757D` — Secondary text

Colors are consistent across:
- `.zshrc` syntax highlighting
- `starship.toml` prompt
- `.claude/statusline-command.sh`
- `install.sh` / `uninstall.sh` UI
