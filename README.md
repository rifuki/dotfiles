# dotfiles

Personal macOS dotfiles — batteries included.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/rifuki/.dotfiles/refs/heads/macos/install.sh | bash
```

> Restart terminal or run `exec zsh` after install.

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/rifuki/.dotfiles/refs/heads/macos/uninstall.sh | bash
```

## What's included

### Tools
| Tool | Description |
|------|-------------|
| [Neovim](https://neovim.io) | Text editor |
| [Tmux](https://github.com/tmux/tmux) | Terminal multiplexer |
| [Oh My Zsh](https://ohmyz.sh) | Zsh framework |
| [Spaceship](https://spaceship-prompt.sh) | Zsh prompt |
| [NVM](https://github.com/nvm-sh/nvm) | Node version manager (Node 22) |
| [Bun](https://bun.sh) | JavaScript runtime & package manager |
| [Rust](https://rustup.rs) | Rust toolchain (stable) |
| [Yazi](https://github.com/sxyazi/yazi) | Terminal file manager |
| [gh](https://cli.github.com) | GitHub CLI |
| [trash](https://github.com/sindresorhus/trash-cli) | Safe `rm` replacement |
| [htop](https://htop.dev) | Process viewer |
| [neofetch](https://github.com/dylanaraps/neofetch) | System info |

### Configs
- `nvim` — NvChad-based config with LSP, Treesitter, and plugins
- `tmux` — Catppuccin theme, TPM plugins
- `spaceship` — Custom prompt config
- `ghostty` — Terminal emulator config
- `yabai` + `skhd` — Tiling window manager + hotkeys
- `neofetch` — System info display
- `.zshrc` — Shell config (PATH, aliases, plugins)

## Re-run / Update

Re-running `install.sh` is safe:
- Local config changes are **backed up** to `~/.config/backup-TIMESTAMP/`
- Dotfiles are **restored** to the latest remote state
- All tools are skipped if already installed

## Structure

```
~/.dotfiles/
├── .config/
│   ├── nvim/
│   ├── tmux/
│   ├── spaceship/
│   ├── ghostty/
│   ├── yabai/
│   ├── skhd/
│   └── neofetch/
├── .zshrc
├── .hyper.js
├── install.sh
└── uninstall.sh
```

All configs are symlinked from `~/.dotfiles` to their respective locations in `$HOME`.
