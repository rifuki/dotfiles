#!/usr/bin/env bash
# Install the Move treesitter parser for Neovim.
# The parser is from MystenLabs/sui (not in official nvim-treesitter registry).
# Source: https://github.com/MystenLabs/sui/tree/main/external-crates/move/tooling/tree-sitter
#
# Usage: bash ~/.config/nvim/scripts/install-move-parser.sh

set -e

if ! command -v nvim &>/dev/null; then
    echo "Error: nvim not found in PATH. Install nvim first."
    exit 1
fi

# Try headless mode first, fallback to default path
PARSER_DIR=$(nvim --clean --headless -c "lua print(vim.fn.stdpath('data'))" -c "qa" 2>/dev/null | tr -d '\r')

if [ -z "$PARSER_DIR" ]; then
    # Fallback to XDG default
    PARSER_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"
    echo "Warning: headless nvim failed, using default: $PARSER_DIR"
fi

DEST="$PARSER_DIR/site/parser/move.so"
TREE_SITTER_PATH="external-crates/move/tooling/tree-sitter"
WORK_DIR=$(mktemp -d)
mkdir -p "$(dirname "$DEST")"

echo "==> Installing Move treesitter parser..."
echo "    Destination: $DEST"

# Sparse clone only the tree-sitter subdirectory (fast, minimal download)
echo "==> Cloning tree-sitter grammar (sparse)..."
git clone \
    --depth=1 \
    --filter=blob:none \
    --sparse \
    https://github.com/MystenLabs/sui.git \
    "$WORK_DIR/sui" 2>&1

git -C "$WORK_DIR/sui" sparse-checkout set "$TREE_SITTER_PATH/src"

echo "==> Compiling parser..."
SRC="$WORK_DIR/sui/$TREE_SITTER_PATH/src/parser.c"

if [[ "$(uname)" == "Darwin" ]]; then
    gcc -o "$DEST" -shared -fPIC -Os "$SRC"
else
    gcc -o "$DEST" -shared -fPIC -Os -lstdc++ "$SRC"
fi

echo "==> Cleaning up..."
rm -rf "$WORK_DIR"

echo ""
echo "Done! Parser installed at: $DEST"
echo "Restart nvim to apply."
