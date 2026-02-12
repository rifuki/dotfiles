#!/bin/bash

# ========== Colors ==========
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

done_msg() { echo -e "  ${GREEN}✔${NC} $1"; }
info_msg() { echo -e "  ${BLUE}▸${NC} $1"; }
warn_msg() { echo -e "  ${YELLOW}▸${NC} $1"; }
section()  { echo -e "\n  ${BOLD}$1${NC}"; }

# ========== Keyboard ==========
section "Keyboard"

info_msg "Disable press-and-hold accent picker (enable key repeat)..."
defaults write -g ApplePressAndHoldEnabled -bool false
done_msg "ApplePressAndHoldEnabled → false"

info_msg "Set key repeat rate..."
defaults write -g KeyRepeat -int 1
done_msg "KeyRepeat → 1  (fastest)"

info_msg "Set initial key repeat delay..."
defaults write -g InitialKeyRepeat -int 10
done_msg "InitialKeyRepeat → 10  (shortest delay)"

# ========== Text Input ==========
section "Text Input"

info_msg "Disable auto-correct..."
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
done_msg "Auto-correct → disabled"

info_msg "Disable auto-capitalization..."
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
done_msg "Auto-capitalization → disabled"

info_msg "Disable smart dashes (-- stays --)..."
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
done_msg "Smart dashes → disabled"

info_msg "Disable smart quotes (\" stays \")..."
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
done_msg "Smart quotes → disabled"

info_msg "Disable period substitution (double space stays double space)..."
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
done_msg "Period substitution → disabled"

# ========== Trackpad ==========
section "Trackpad"

info_msg "Enable tap to click..."
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
done_msg "Tap to click → enabled"

info_msg "Enable three finger drag..."
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true
done_msg "Three finger drag → enabled"

info_msg "Disable tap-to-drag (no more delay on release)..."
defaults write com.apple.AppleMultitouchTrackpad Dragging -bool false
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Dragging -bool false
done_msg "Tap-to-drag → disabled"

# ========== Finder ==========
section "Finder"

info_msg "Show path bar..."
defaults write com.apple.finder ShowPathbar -bool true
done_msg "Path bar → enabled"

info_msg "Show status bar..."
defaults write com.apple.finder ShowStatusBar -bool true
done_msg "Status bar → enabled"

info_msg "Show hidden files..."
defaults write com.apple.finder AppleShowAllFiles -bool true
done_msg "Hidden files → visible"

info_msg "Show all file extensions..."
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
done_msg "File extensions → always visible"

info_msg "Set default view to Icon View..."
defaults write com.apple.finder FXPreferredViewStyle -string "icnv"
done_msg "Default view → Icon View (icnv)"

info_msg "Keep folders on top when sorting..."
defaults write com.apple.finder _FXSortFoldersFirst -bool true
done_msg "Folders first → enabled"

info_msg "Disable group by (use sort only, no dynamic reflow)..."
defaults write com.apple.finder FXPreferredGroupBy -string "None"
done_msg "Group by → None"

info_msg "Search current folder by default (Cmd+F)..."
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
done_msg "Default search scope → current folder"

info_msg "Open new Finder window to Home folder..."
defaults write com.apple.finder NewWindowTarget -string "PfHm"
defaults write com.apple.finder NewWindowTargetPath -string "file://$HOME/"
done_msg "New Finder window → Home folder"

# NOTE: .DS_Store intentionally kept — required for macOS Tags (color labels) on external drives

# ========== Desktop ==========
section "Desktop"

info_msg "Disable click wallpaper to show desktop..."
defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false
done_msg "Click wallpaper to show desktop → disabled"

info_msg "Disable widgets on desktop..."
defaults write com.apple.WindowManager StandardHideWidgets -bool true
done_msg "Desktop widgets → hidden"

# ========== Screenshot ==========
section "Screenshot"

info_msg "Disable drop shadow on window screenshots..."
defaults write com.apple.screencapture disable-shadow -bool true
done_msg "Screenshot shadow → disabled"

# ========== Clock ==========
section "Clock"

info_msg "Show seconds in menu bar clock..."
defaults write com.apple.menuextra.clock ShowSeconds -bool true
done_msg "Clock seconds → visible"

# ========== Dock ==========
section "Dock"

info_msg "Enable magnification on hover..."
defaults write com.apple.dock magnification -bool true
done_msg "Magnification → enabled"

info_msg "Set magnification size..."
defaults write com.apple.dock largesize -int 80
done_msg "Magnification size → 80"

info_msg "Enable auto-hide dock..."
defaults write com.apple.dock autohide -bool true
done_msg "Dock autohide → enabled"

info_msg "Disable spaces auto-rearrange (Mission Control)..."
defaults write com.apple.dock mru-spaces -bool false
done_msg "Spaces auto-rearrange → disabled"

info_msg "Group windows by application in Mission Control..."
defaults write com.apple.dock expose-group-apps -bool true
done_msg "Mission Control group by app → enabled"

# ========== Restart affected services ==========
echo ""
killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true
killall WindowManager 2>/dev/null || true
warn_msg "Finder, Dock, SystemUIServer & WindowManager restarted — some changes require logout/restart to take full effect"
