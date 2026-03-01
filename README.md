# dotfiles

Personal dotfiles for macOS, Ubuntu, and Gentoo Linux — batteries included.

## Screenshots

| Terminal (Neofetch) | Editor (Neovim) |
|:---:|:---:|
| <img src="https://github.com/user-attachments/assets/b7319a56-27d4-4ed0-80f7-e56fb3148711" width="400"> | <img src="https://github.com/user-attachments/assets/ddff5552-6e67-43fd-8f9e-1aee9148136a" width="400"> |

| Tiling (Yabai) |
|:---:|
| <img src="https://github.com/user-attachments/assets/ce95680d-2226-4ff9-8f41-7dd82b31397c" width="400"> |

**Window Switching Demo:**

<video src="https://github.com/user-attachments/assets/523ac440-8b3c-40b8-b2da-8162a9b72ef7" width="100%" controls></video>

*Theme: Cyan-magenta palette inspired by Miku color with Ghostty, Neovim, Yabai, and SKHD*

## Install

```bash
bash <(curl -fsSL https://dotfiles.rifuki.dev)
```

Auto-detects OS (macOS, Gentoo Linux, or Ubuntu/Debian). Uses `bash <()` instead of `curl | bash` to preserve interactive TTY for password prompts.

> Restart terminal or run `exec zsh` after install.

## Uninstall

**macOS:**
```bash
bash <(curl -fsSL https://dotfiles.rifuki.dev/macos/uninstall.sh)
```

**Ubuntu:**
```bash
bash <(curl -fsSL https://dotfiles.rifuki.dev/ubuntu/uninstall.sh)
```

**Gentoo:**
```bash
bash <(curl -fsSL https://dotfiles.rifuki.dev/gentoo/uninstall.sh)
```

### Remove Homebrew completely (macOS)

```bash
bash ~/.dotfiles/macos/uninstall-brew.sh
```

## What's included

### Tools (macOS)
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

### Blockchain Tools (optional, macOS)
| Tool | Description |
|------|-------------|
| [Solana](https://solana.com) | Solana CLI + development tools |
| [Anchor](https://www.anchor-lang.com) | Solana framework (via AVM) |
| [suiup](https://sui.io) | Sui version manager |
| [sui-move-analyzer](https://github.com/movebit/sui-move-analyzer) | Sui Move LSP (~10min build) |

### AI Tools (optional)
| Tool | Description |
|------|-------------|
| [Kimi CLI](https://github.com/MoonshotAI/kimi-cli) | Kimi AI CLI |
| [OpenCode](https://opencode.ai) | OpenCode AI |

### Tools (Gentoo — Hyprland Desktop)
| Tool | Description |
|------|-------------|
| [Hyprland](https://hyprland.org) | Wayland tiling compositor |
| [Waybar](https://github.com/Alexays/Waybar) | Status bar |
| [Wofi](https://hg.sr.ht/~scoopta/wofi) | App launcher |
| [Ghostty](https://ghostty.org) | Terminal emulator |
| [hyprlock](https://github.com/hyprwm/hyprlock) | Screen locker |
| [hyprpaper](https://github.com/hyprwm/hyprpaper) | Wallpaper daemon |
| [grim](https://sr.ht/~emersion/grim) + [slurp](https://github.com/emersion/slurp) | Screenshots |
| [dunst](https://dunst-project.org) | Notification daemon |

> **Note:** Hyprland-related tools are installed via portage by the user. The dotfiles installer symlinks configs and warns about missing tools.

### Configs
- `nvim` — NvChad-based config with LSP, Treesitter, and plugins
- `tmux` — Catppuccin Frappe theme, TPM plugins (resurrect, continuum, cpu, battery)
- `starship` — Cyan-magenta prompt theme
- `ghostty` — Terminal emulator config (macOS + Gentoo)
- `yabai` + `skhd` — Tiling window manager + hotkeys (macOS)
- `neofetch` — Miku ASCII art + config (unified)
- `yazi` — Terminal file manager with cross-platform opener
- `.zshrc` — Cyan-magenta syntax highlighting, aliases, PATH setup
- `.claude/` — Claude Code statusline integration with Starship colors

## Structure

```
~/.dotfiles/
├── shared/
│   ├── .claude/           # Claude Code statusline (both platforms)
│   └── .config/
│       ├── nvim/          # NvChad config + LSP + plugins
│       ├── neofetch/      # Custom ASCII art + config (unified)
│       ├── starship/      # Cyan-magenta prompt (unified)
│       ├── tmux/          # Catppuccin theme + plugins (unified)
│       └── yazi/          # File manager (unified, cross-platform opener)
│
├── macos/
│   ├── .config/
│   │   ├── ghostty/       # Terminal config
│   │   ├── skhd/          # Hotkey daemon
│   │   └── yabai/         # Window manager
│   ├── .hyper.js          # Hyper terminal config
│   ├── .zshrc             # macOS shell config
│   ├── install.sh         # macOS installer
│   ├── uninstall.sh       # macOS uninstaller
│   ├── uninstall-brew.sh  # Complete Homebrew removal
│   ├── macos-defaults.sh  # macOS system defaults
│   └── macos-defaults-check.sh
│
├── ubuntu/
│   ├── .zshrc             # Ubuntu shell config
│   ├── install.sh         # Ubuntu installer
│   └── uninstall.sh       # Ubuntu uninstaller
│
├── gentoo/
│   ├── .config/
│   │   ├── ghostty/       # Terminal emulator config
│   │   ├── hypr/          # Hyprland + hyprlock + hyprpaper
│   │   ├── waybar/        # Status bar (TokyoNight theme)
│   │   └── wofi/          # App launcher
│   ├── .local/
│   │   └── bin/           # Screenshot scripts (grim + slurp)
│   ├── system/            # System config backup (reference only, not installed)
│   │   ├── boot/grub/     # grub.cfg snapshot
│   │   └── etc/           # /etc/profile + profile.d/tty-bash.sh
│   ├── .zshrc             # Gentoo shell config
│   ├── install.sh         # Gentoo installer
│   └── uninstall.sh       # Gentoo uninstaller
│
├── install.sh             # Entry point (detects OS, delegates)
├── .gitignore
└── README.md
```

Shared configs use cross-platform strategies (uname checks, ssh_only, graceful fallbacks) so the same files work on both macOS and Linux.

## Post-Installation (Yabai & Skhd)

After install, manually set up Yabai and Skhd:

**Yabai:**
1. Configure scripting addition (if SIP disabled):
   ```bash
   echo "$(whoami) ALL=(root) NOPASSWD: sha256:$(shasum -a 256 $(which yabai) | cut -d " " -f 1) $(which yabai) --load-sa" | sudo tee /private/etc/sudoers.d/yabai
   ```
2. Make sure `yabairc` has: `yabai -m signal --add event=dock_did_restart action="sudo yabai --load-sa"`
3. Run: `yabai --start-service`
4. When prompted, allow Yabai in **System Settings > Privacy & Security > Accessibility**

**Skhd:**
1. Run: `skhd --start-service`
2. When prompted, allow Skhd in **System Settings > Privacy & Security > Accessibility**
3. Disable **Secure Keyboard Entry** in Terminal if needed

## Re-run / Update

Re-running `install.sh` is safe:
- Interactive checklist lets you pick which components to install
- Already-installed tools are detected and shown in the menu
- Local config changes are **backed up** to `~/.config/backup-TIMESTAMP/`
- Dotfiles are **restored** to the latest remote state

## Theme

**Color Palette** (used in Starship, Zsh, installer/uninstaller):
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
