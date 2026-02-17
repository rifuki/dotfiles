#!/usr/bin/env bash
# Claude Code status line — mirrors Starship prompt style
# Format: [time] with [user] in [dir] on [branch] [git_status] | [model] [ctx%]

input=$(cat)

# ── Extract JSON fields ───────────────────────────────────────────────────────
cwd=$(echo "$input"        | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input"      | jq -r '.model.display_name // empty')
used=$(echo "$input"       | jq -r '.context_window.used_percentage // empty')

# ── ANSI color helpers (256-colour hex via escape sequences) ──────────────────
# Colors are intentionally dimmed by the terminal; we use exact hex values.
cyan='\033[38;2;0;217;255m'      # #00D9FF
gray='\033[38;2;108;117;125m'    # #6C757D
green='\033[38;2;80;250;123m'    # #50FA7B
pink='\033[38;2;255;121;198m'    # #FF79C6
peach='\033[38;2;240;202;164m'   # #f0caa4
yellow='\033[38;2;241;250;140m'  # #F1FA8C
reset='\033[0m'
bold='\033[1m'

# ── Time ──────────────────────────────────────────────────────────────────────
time_str=$(date +%H:%M:%S)

# ── User ──────────────────────────────────────────────────────────────────────
user_str=$(whoami)

# ── SSH indicator ─────────────────────────────────────────────────────────────
ssh_indicator=""
if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
    ssh_indicator="${bold}${yellow}SSH${reset} "
fi

# ── Directory (shorten $HOME to ~) ───────────────────────────────────────────
home_dir="$HOME"
if [ -n "$cwd" ]; then
    dir_str="${cwd/#$home_dir/~}"
else
    dir_str="~"
fi

# ── Git branch & status (skip optional locks) ────────────────────────────────
git_branch=""
git_status_str=""
if git -c core.fsmonitor=false -C "${cwd:-$HOME}" rev-parse --git-dir >/dev/null 2>&1; then
    git_branch=$(git -c core.fsmonitor=false -C "${cwd:-$HOME}" symbolic-ref --short HEAD 2>/dev/null \
                 || git -c core.fsmonitor=false -C "${cwd:-$HOME}" rev-parse --short HEAD 2>/dev/null)

    # Collect status indicators (mirrors Starship git_status defaults)
    status_flags=""
    git_status_output=$(git -c core.fsmonitor=false -C "${cwd:-$HOME}" status --porcelain=v2 --branch 2>/dev/null)

    # Staged
    staged=$(echo "$git_status_output" | grep -c '^[12] [MADRC]')
    [ "$staged" -gt 0 ] && status_flags="${status_flags}+"

    # Modified (unstaged)
    modified=$(echo "$git_status_output" | grep -c '^[12] .[MD]')
    [ "$modified" -gt 0 ] && status_flags="${status_flags}!"

    # Untracked
    untracked=$(echo "$git_status_output" | grep -c '^?')
    [ "$untracked" -gt 0 ] && status_flags="${status_flags}?"

    # Deleted (unstaged)
    deleted=$(echo "$git_status_output" | grep -c '^[12] .D')
    [ "$deleted" -gt 0 ] && status_flags="${status_flags}✘"

    # Ahead / behind
    ahead=$(echo "$git_status_output"  | grep -oP '(?<=ahead )\d+'  | head -1)
    behind=$(echo "$git_status_output" | grep -oP '(?<=behind )\d+' | head -1)
    [ -n "$ahead"  ] && [ "$ahead"  -gt 0 ] && status_flags="${status_flags}⇡${ahead}"
    [ -n "$behind" ] && [ "$behind" -gt 0 ] && status_flags="${status_flags}⇣${behind}"

    [ -n "$status_flags" ] && git_status_str="[${status_flags}]"
fi

# ── Model & context ───────────────────────────────────────────────────────────
meta_str=""
if [ -n "$model" ]; then
    meta_str="$model"
    if [ -n "$used" ]; then
        meta_str="${meta_str} ctx:${used}%"
    fi
fi

# ── Assemble the line ─────────────────────────────────────────────────────────
line=""

# SSH indicator (if connected via SSH)
line="${line}${ssh_indicator}"

# time
line="${line}${bold}${cyan}${time_str}${reset}"

# " with "
line="${line} ${bold}${gray}with${reset} "

# user
line="${line}${bold}${cyan}${user_str}${reset}"

# " in "
line="${line} ${bold}${gray}in${reset} "

# directory
line="${line}${bold}${green}${dir_str}${reset}"

# git branch
if [ -n "$git_branch" ]; then
    line="${line} ${bold}${gray}on${reset} ${bold}${pink}${git_branch}${reset}"
    if [ -n "$git_status_str" ]; then
        line="${line} ${peach}${git_status_str}${reset}"
    fi
fi

# model / context (right-aligned hint, separated by a pipe)
if [ -n "$meta_str" ]; then
    line="${line} ${bold}${gray}|${reset} ${gray}${meta_str}${reset}"
fi

printf "%b\n" "$line"
