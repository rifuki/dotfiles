#!/bin/bash
# Check if all macOS defaults from macos-defaults.sh are applied
# Usage: bash macos-defaults-check.sh → outputs "applied/total"
# Exit: 0 = all applied, 1 = not all

_ok=0; _total=0

check() {
  local _val
  _val=$(defaults read "$1" "$2" 2>/dev/null)
  ((_total++))
  [ "$_val" = "$3" ] && ((_ok++)) || true
}

# Keyboard
check -g ApplePressAndHoldEnabled 0
check -g KeyRepeat 1
check -g InitialKeyRepeat 10

# Text Input
check NSGlobalDomain NSAutomaticSpellingCorrectionEnabled 0
check NSGlobalDomain NSAutomaticCapitalizationEnabled 0
check NSGlobalDomain NSAutomaticDashSubstitutionEnabled 0
check NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled 0
check NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled 0

# Trackpad
check com.apple.AppleMultitouchTrackpad Clicking 1
check com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag 1
check com.apple.AppleMultitouchTrackpad Dragging 0

# Finder
check com.apple.finder ShowPathbar 1
check com.apple.finder ShowStatusBar 1
check com.apple.finder AppleShowAllFiles 1
check NSGlobalDomain AppleShowAllExtensions 1
check com.apple.finder FXPreferredViewStyle icnv
check com.apple.finder _FXSortFoldersFirst 1
check com.apple.finder FXPreferredGroupBy None
check com.apple.finder FXDefaultSearchScope SCcf
check com.apple.finder NewWindowTarget PfHm

# Desktop
check com.apple.WindowManager EnableStandardClickToShowDesktop 0
check com.apple.WindowManager StandardHideWidgets 1

# Screenshot
check com.apple.screencapture disable-shadow 1

# Clock
check com.apple.menuextra.clock ShowSeconds 1

# Dock
check com.apple.dock magnification 1
check com.apple.dock largesize 80
check com.apple.dock autohide 1
check com.apple.dock mru-spaces 0
check com.apple.dock expose-group-apps 1

echo "${_ok}/${_total}"
[ "$_ok" -eq "$_total" ]
