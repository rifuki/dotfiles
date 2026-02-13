#!/bin/bash

input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir')

# Colors from starship.toml
cyan_bold=$'\033[1;38;2;0;217;255m'
green_bold=$'\033[1;38;2;80;250;123m'
magenta_bold=$'\033[1;38;2;255;121;198m'
gray_bold=$'\033[1;38;2;108;117;125m'
white_bold=$'\033[1;38;2;239;241;244m'
peach=$'\033[38;2;240;202;164m'
reset=$'\033[0m'

time_str=$(date +%H:%M:%S)
user_str=$(whoami)
dir_str="$cwd"

# Git info
git_output=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ -n "$branch" ]; then
        git_output=$(printf " ${gray_bold}on${reset} ${white_bold}${reset}${magenta_bold}%s${reset}" "$branch")
        if ! git -C "$cwd" --no-optional-locks diff --quiet 2>/dev/null || \
           ! git -C "$cwd" --no-optional-locks diff --cached --quiet 2>/dev/null || \
           [ -n "$(git -C "$cwd" --no-optional-locks ls-files --others --exclude-standard 2>/dev/null)" ]; then
            git_output="${git_output} ${peach}*${reset}"
        fi
    fi
fi

printf "${cyan_bold}%s${reset} ${gray_bold}with${reset} ${cyan_bold}%s${reset} ${gray_bold}in${reset} ${green_bold}%s${reset}%s" \
    "$time_str" "$user_str" "$dir_str" "$git_output"
