#!/usr/bin/env bash
# ----------------------------------------------------------
# Fluid shell setup — run AFTER setup-arch.sh.
#
# Installs sway + the Quickshell "fluid" shell and everything it talks to,
# enables the services it needs, stows the dotfiles and prepares
# ~/.local/state/fluid. Safe to run again: installed packages are skipped,
# and stow conflicts are reported instead of overwritten.
# ----------------------------------------------------------

set -u

REPO_DIR="$(cd "$(dirname "$(realpath "$0")")" && pwd)"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/fluid"

packages=(
    # Compositor + the tools the sway config already uses
    "sway"
    "swaybg"
    "swayidle"
    "swaylock"
    "grimshot"
    "xdg-desktop-portal-wlr"
    "stow"

    # The shell
    "quickshell"
    "qt6-wayland"
    "qt6-svg"            # SVG app/tray icons
    "qt6-imageformats"   # webp wallpapers
    "matugen"            # wallpaper -> colour theme
    "cliphist"           # clipboard history ($mod+v)
    "wl-clipboard"

    # Services the bar and control center read from
    "pipewire"
    "pipewire-pulse"
    "wireplumber"
    "pavucontrol"
    "networkmanager"
    "bluez"
    "bluez-utils"
    "blueberry"
    "upower"             # battery
    "brightnessctl"
    "libnotify"          # notify-send (crash fallback notice)
    "htop"               # opened by the cpu/memory pills

    # Fonts
    "ttf-roboto"
    "ttf-nerd-fonts-symbols"
)

# ----------------------------------------------------------
# Colors / helpers (same style as setup-arch.sh)
# ----------------------------------------------------------

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NONE='\033[0m'

info() { echo -e "${GREEN}::${NONE} $*"; }
warn() { echo -e "${YELLOW}:: $*${NONE}"; }
fail() { echo -e "${RED}:: $*${NONE}"; }

_isInstalled() {
    pacman -Qq "$1" >/dev/null 2>&1
}

_installPackages() {
    local missing=()
    for pkg; do
        if _isInstalled "$pkg"; then
            echo ":: ${pkg} is already installed."
        else
            missing+=("$pkg")
        fi
    done
    if [ ${#missing[@]} -gt 0 ]; then
        info "Installing: ${missing[*]}"
        yay --needed --noconfirm -S "${missing[@]}" || warn "Some packages failed to install, see above."
    fi
}

# ----------------------------------------------------------
# Header
# ----------------------------------------------------------

clear
echo -e "${GREEN}"
cat <<"EOF"
   ________     _    __
  / __/ / /_ __(_)__/ /
 / _// / // / / / _  /
/_/ /_/\_,_/_/_/\_,_/

EOF
echo -e "${NONE}"
echo "Sway + Quickshell fluid shell. Run this after setup-arch.sh."
echo

if ! command -v pacman >/dev/null; then
    fail "This script is for Arch Linux."
    exit 1
fi
if ! command -v yay >/dev/null; then
    fail "yay not found. Run setup-arch.sh first (it uses yay too)."
    exit 1
fi

while true; do
    read -p "DO YOU WANT TO START THE FLUID SETUP NOW? (Yy/Nn): " yn
    case $yn in
        [Yy]*) echo; break ;;
        [Nn]*) echo ":: Setup canceled"; exit 0 ;;
        *) echo ":: Please answer yes or no." ;;
    esac
done

# ----------------------------------------------------------
# 1. Packages
# ----------------------------------------------------------

info "Installing packages"
_installPackages "${packages[@]}"
echo

# ----------------------------------------------------------
# 2. Services
# ----------------------------------------------------------

info "Enabling services"
sudo systemctl enable --now NetworkManager.service
sudo systemctl enable --now bluetooth.service
# upower is D-Bus activated, starting it now just makes the battery show immediately
sudo systemctl start upower.service 2>/dev/null || true
systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service
echo

# ----------------------------------------------------------
# 3. Stow the dotfiles
# ----------------------------------------------------------

info "Linking dotfiles from ${REPO_DIR}"
cd "$REPO_DIR" || exit 1
if stow -n -t "$HOME" . 2>/tmp/fluid-stow.log; then
    stow -t "$HOME" .
    info "Dotfiles stowed."
else
    warn "stow found existing files it won't overwrite:"
    grep -E 'existing target|cannot stow' /tmp/fluid-stow.log | sed 's/^/     /'
    warn "Move or delete those, then run: cd ${REPO_DIR} && stow -t ~ ."
fi
echo

# ----------------------------------------------------------
# 4. Shell state
# ----------------------------------------------------------

info "Preparing ${STATE_DIR}"
mkdir -p "$STATE_DIR"
# An empty palette means "use the old waybar colours". Creating the file now
# lets the shell watch it from the first start.
[ -f "$STATE_DIR/colors.json" ] || echo '{}' > "$STATE_DIR/colors.json"
[ -f "$STATE_DIR/mode" ] || echo dark > "$STATE_DIR/mode"
[ -f "$STATE_DIR/shell" ] || echo fluid > "$STATE_DIR/shell"
chmod +x "$REPO_DIR/.config/quickshell/fluid/scripts/"*.sh
echo

# ----------------------------------------------------------
# 5. Checks
# ----------------------------------------------------------

info "Checking"
ok=true
for cmd in sway qs matugen cliphist wl-copy nmcli brightnessctl swaybg; do
    if command -v "$cmd" >/dev/null; then
        echo "   ok       $cmd"
    else
        echo -e "   ${RED}missing${NONE}  $cmd"
        ok=false
    fi
done
if [ -e "$HOME/.config/quickshell/fluid/shell.qml" ]; then
    echo "   ok       ~/.config/quickshell/fluid is linked"
else
    echo -e "   ${RED}missing${NONE}  ~/.config/quickshell/fluid (stow didn't link it)"
    ok=false
fi
echo

# ----------------------------------------------------------
# 6. Start it if we're inside sway
# ----------------------------------------------------------

if [ -n "${SWAYSOCK:-}" ]; then
    info "Sway is running: reloading config and starting the shell"
    swaymsg reload >/dev/null
    "$HOME/.config/quickshell/fluid/scripts/fluid-launch.sh" fluid
    if ! pgrep -f 'wl-paste --type text --watch cliphist' >/dev/null; then
        (wl-paste --type text --watch cliphist store >/dev/null 2>&1 &)
        (wl-paste --type image --watch cliphist store >/dev/null 2>&1 &)
    fi
else
    info "Log in to a sway session and the shell starts on its own."
fi

echo
if $ok; then
    info "Fluid setup complete."
else
    warn "Fluid setup finished with problems, see the checks above."
fi
echo "   Keys:  \$mod+p launcher · \$mod+t theme · \$mod+i control center · \$mod+v clipboard"
echo "   Back to waybar any time: \$mod+Alt+w   (and \$mod+Alt+q to return)"
echo "   Log:   ${STATE_DIR}/fluid.log"
