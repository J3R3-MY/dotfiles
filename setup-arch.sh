#!/usr/bin/env bash

# ----------------------------------------------------------
# Packages
# ----------------------------------------------------------

packages=(
    "wget"
    "unzip"
    "git"
    "gum"    
    "hyprland"
    "hypridle" 
    "docker"
    "okular" 
    "feh" 
    "gwenview" 
    "vlc" 
    "bitwarden" 
    "qalculate-gtk" 
    "obsidian" 
    "firefox" 
    "thunderbird"
    "htop" 
    "lazygit" 
    "cgdb" 
    "bob" 
    "fd" 
    "lsd" 
    "sd" 
    "sddm"
    "choose" 
    "broot" 
    "git-delta" 
    "zsh-syntax-highlighting"
    "wofi" 
    "zsh-autocomplete" 
    "thefuck" 
    "ripgrep" 
    "uv" 
    "mediainfo" 
    "stow"
    "snapper-support" 
    "btrfs-assistant" 
    "nvidia-inst"
    "python-pip"
    "hyprpicker" 
    "hyprshot" 
    "waybar"
    "starship"
    "zsh"
    "vim"
    "wezterm"
    "rofi-wayland"
    "thunar-volman" 
    "tumbler" 
    "thunar-archive-plugin" 
    "network-manager-applet" 
    "blueberry"
    "slurp" 
    "grim" 
    "xclip" 
    "swappy"
    "wl-clipboard" 
    "ninja" 
    "ffmpeg" 
    "tailscale" 
    "nasm" 
    "libgit2" 
    "lnav" 
    "fq" 
    "tinyxml2"
    "ark"
    "gvfs"
    "dunst"
    "thunar"
    "xdg-desktop-portal-hyprland"
    "qt5-wayland"
    "qt6-wayland"
    "hyprpaper"
    "hyprlock"
    "firefox"
    "ttf-font-awesome"
    "vim"
    "fastfetch"
    "ttf-fira-sans" 
    "ttf-fira-code" 
    "ttf-firacode-nerd"
    "jq"
    "brightnessctl"
    "networkmanager"
    "wireplumber"
    "wlogout"
    "flatpak"
)

# ----------------------------------------------------------
# Colors
# ----------------------------------------------------------

GREEN='\033[0;32m'
NONE='\033[0m'

# ----------------------------------------------------------
# Check if command exists
# ----------------------------------------------------------

_checkCommandExists() {
    cmd="$1"
    if ! command -v "$cmd" >/dev/null; then
        echo 1
        return
    fi
    echo 0
    return
}

# ----------------------------------------------------------
# Check if package is already installed
# ----------------------------------------------------------

_isInstalled() {
    package="$1"
    check="$(sudo pacman -Qs --color always "${package}" | grep "local" | grep "${package} ")"
    if [ -n "${check}" ]; then
        echo 0
        return #true
    fi
    echo 1
    return #false
}

# ----------------------------------------------------------
# Install packages
# ----------------------------------------------------------

_installPackages() {
    toInstall=()
    for pkg; do
        if [[ $(_isInstalled "${pkg}") == 0 ]]; then
            echo ":: ${pkg} is already installed."
            continue
        fi
        echo "Package not installed: ${pkg}"
        yay --noconfirm -S "${pkg}"
    done
}

# ----------------------------------------------------------
# Header
# ----------------------------------------------------------

clear
echo -e "${GREEN}"
cat <<"EOF"
   ____    __          
  / __/__ / /___ _____ 
 _\ \/ -_) __/ // / _ \
/___/\__/\__/\_,_/ .__/
                /_/    

EOF
echo -e "${NONE}"

# ----------------------------------------------------------
# Content
# ----------------------------------------------------------

while true; do
    read -p "DO YOU WANT TO START THE PACKAGE INSTALLATION NOW? (Yy/Nn): " yn
    case $yn in
        [Yy]*)
            echo ":: Installation started."
            echo
            break
            ;;
        [Nn]*)
            echo ":: Installation canceled"
            exit
            break
            ;;
        *)
            echo ":: Please answer yes or no."
            ;;
    esac
done

# Packages
_installPackages "${packages[@]}"

# default shell
chsh -s $(which zsh)

sudo systemctl enable sddm
sudo systemctl enable bluetooth
sudo systemctl enable fstrim.timer

echo "Please go to ~/dotfiles and execute:"
echo "stow ."

# ----------------------------------------------------------
# Completed
# ----------------------------------------------------------

echo ":: Installation complete."
echo "Please reboot after stowing the dotfiles"
