#!/bin/bash

input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir')

# Colors matching starship.toml theme
cyan_bold=$'\033[1;38;2;0;217;255m'
green_bold=$'\033[1;38;2;80;250;123m'
magenta_bold=$'\033[1;38;2;255;121;198m'
gray_bold=$'\033[1;38;2;108;117;125m'
white_bold=$'\033[1;38;2;239;241;244m'
peach=$'\033[38;2;240;202;164m'
reset=$'\033[0m'

# Starship: $time $username $directory $git_branch $git_status
# format = '$time$username$directory$git_branch$git_status$line_break$character'

time_str=$(date +%H:%M:%S)
user_str=$(whoami)
dir_str="$cwd"

# Git info (mirrors $git_branch and $git_status modules)
git_output=""
if git -C "$cwd" --no-optional-locks rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ -n "$branch" ]; then
        # $git_branch: [on](gray) [ ](white)[$branch](magenta)
        git_output=$(printf " ${gray_bold}on${reset} ${white_bold} ${reset}${magenta_bold}%s${reset}" "$branch")

        # $git_status: show dirty marker in peach if working tree is not clean
        status_str=""
        if ! git -C "$cwd" --no-optional-locks diff --quiet 2>/dev/null; then
            status_str="!"
        fi
        if ! git -C "$cwd" --no-optional-locks diff --cached --quiet 2>/dev/null; then
            status_str="${status_str}+"
        fi
        if [ -n "$(git -C "$cwd" --no-optional-locks ls-files --others --exclude-standard 2>/dev/null)" ]; then
            status_str="${status_str}?"
        fi
        if [ -n "$status_str" ]; then
            git_output="${git_output} ${peach}[${status_str}]${reset}"
        fi
    fi
fi

# Output: [$time](cyan) [with](gray) [$user](cyan) [in](gray) [$path](green) [git...](various)
printf "${cyan_bold}%s${reset} ${gray_bold}with${reset} ${cyan_bold}%s${reset} ${gray_bold}in${reset} ${green_bold}%s${reset}%s" \
    "$time_str" "$user_str" "$dir_str" "$git_output"
