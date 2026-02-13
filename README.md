# dotfiles — VPS Edition 🌐

Interactive Ubuntu/Debian dotfiles installer with Miku cyberpunk theme and comprehensive component selection.

## 🎨 Miku Cyberpunk Theme

RGB color palette used throughout the VPS setup:

| Color | Hex | Usage |
|-------|-----|-------|
| **Cyan** | `#00D9FF` | Labels, selected items, info messages |
| **Magenta** | `#FF79C6` | Headers, boxes, section titles |
| **Green** | `#50FA7B` | Success indicators (✔) |
| **Peach** | `#F0CAA4` | Warnings (▸) |
| **Red** | `#FF5555` | Errors (✖) |
| **Purple** | `#BD93F9` | Secondary accents |
| **Teal** | `#01CBC6` | Tertiary accents |
| **Gray** | `#6C757D` | Unselected/dimmed text |

Applied to:
- `install.sh` — Interactive installer with checkbox menu
- `uninstall.sh` — Interactive uninstaller
- `.zshrc` — Zsh syntax highlighting & prompt
- `starship.toml` — Shell prompt theme

## 📦 Installation

```bash
bash <(curl -s https://raw.githubusercontent.com/rifuki/.dotfiles/vps/install.sh)
```

### Features
- **Interactive menu** — Select components to install
- **Backup system** — Existing configs backed up before changes
- **Symlink management** — Auto-setup config files
- **Dependency tracking** — AI CLI Tools requires NVM for npm
- **Shell setup** — Automatic Zsh as default shell

## 🔧 Components

| # | Component | Description |
|---|-----------|-------------|
| **0** | APT Packages + Nerd Font | neovim, tmux, zsh, htop, ripgrep, neofetch, yazi, gh, JetBrainsMono |
| **1** | Starship | Cross-shell prompt theme |
| **2** | Oh My Zsh | Zsh framework + plugins (autosuggestions, syntax-highlighting) |
| **3** | Rust | Rust toolchain via rustup |
| **4** | Bun | JavaScript runtime |
| **5** | NVM | Node version manager + Node 24 |
| **6** | Docker | Container engine + docker group setup |
| **7** | AI CLI Tools | Claude Code + Gemini CLI (via npm, requires NVM) |
| **8** | Swap | 2GB swap file (/swapfile) |
| **9** | fail2ban | Intrusion prevention system |
| **10** | UFW | Firewall (ufw) |
| **11** | Deep Clean | Remove residue files (.cache, .local, .npm, etc.) |

**Always installed (cannot be deselected):**
- System update (`apt update && apt upgrade`)
- Dotfiles repository clone/pull
- Config backup & symlink setup
- TPM (Tmux Plugin Manager)
- Git config (optional prompt)
- Zsh as default shell

## 🗑️ Uninstallation

```bash
~/.dotfiles/uninstall.sh
```

- Interactive menu to select components
- Detect already-installed items
- Create backup before removing
- Revert shell to bash
- "Deep Clean" option to remove residue files

## 📂 File Structure

```
.dotfiles/
├── install.sh              # Interactive installer
├── uninstall.sh            # Interactive uninstaller
├── .zshrc                  # Zsh config (Miku theme)
├── .gitignore              # Git ignore rules
└── .config/
    ├── nvim/               # Neovim config
    ├── tmux/
    │   └── tmux.conf       # Tmux config (Catppuccin theme)
    ├── starship/
    │   └── starship.toml   # Starship prompt config
    └── neofetch/
        ├── config.conf     # Neofetch config
        └── miku.txt        # ASCII art
```

## ⌨️ Aliases

| Alias | Command | Purpose |
|-------|---------|---------|
| `n` | `nvim` | Quick Neovim access |
| `fucking` | `sudo` | Humorous sudo wrapper |
| `rm()` | `trash-put` or `rm -i` | Safe delete using trash or interactive prompt |

## 🛠️ Manual Setup

If you prefer to setup components individually:

```bash
# Clone and update manually
git clone --branch vps https://github.com/rifuki/.dotfiles ~/.dotfiles
cd ~/.dotfiles

# Run installer
bash install.sh
```

## 🐛 Troubleshooting

### Shell not changed to Zsh
- Verify Zsh installed: `command -v zsh`
- Check shell manually: `chsh -s $(which zsh)`

### NPM/Gemini CLI not found after install
- Load NVM: `source ~/.nvm/nvm.sh`
- Or restart terminal

### Tmux plugins not loading
- Verify TPM installed: `ls -la ~/.tmux/plugins/tpm`
- Manual install: `git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`

### Docker permission issues
- Restart terminal to load new group membership
- Manual: `newgrp docker` or logout/login

## 📖 Details

### Zsh Configuration
- **Prompt:** Starship (Miku cyberpunk theme)
- **Plugins:** autosuggestions, syntax-highlighting
- **Syntax colors:** Cyan (#00D9FF) for commands, Magenta (#FF79C6) for builtins

### Tmux Configuration
- **Theme:** Catppuccin Mocha
- **Keybindings:** Vim mode
- **Plugins:** tmux-resurrect, tmux-continuum

### Neovim Configuration
- Lazy plugin manager
- LSP support
- Telescope fuzzy finder
- Treesitter syntax highlighting

## 🔗 Links

- [GitHub Repository](https://github.com/rifuki/.dotfiles)
- [macOS Edition](https://github.com/rifuki/.dotfiles/tree/macos)
- [WSL Edition](https://github.com/rifuki/.dotfiles/tree/wsl) (coming soon)

---

**Theme inspired by:** Miku Hatsune's cyberpunk aesthetic 🎵
