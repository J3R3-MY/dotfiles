#!/usr/bin/env bash
# ----------------------------------------------------------
# Shared install logic for install-sway.sh and install-sway-fluid.sh.
# Not meant to be run directly.
#
# Target: a fresh EndeavourOS install with "No Desktop" selected.
# After it finishes and you reboot you land in SDDM -> sway.
# Every step is idempotent, so re-running it is safe.
# ----------------------------------------------------------

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG="$HOME/dotfiles-install-$(date +%Y%m%d-%H%M%S).log"
FAILED_PKGS=()

# ----------------------------------------------------------
# Packages
# ----------------------------------------------------------

# Base system pieces a no-DE EndeavourOS install doesn't have
PKGS_BASE=(
    base-devel git wget curl unzip unrar 7zip stow jq gum pciutils
    xdg-user-dirs xdg-utils
    polkit polkit-gnome
    networkmanager network-manager-applet
    bluez bluez-utils
    pipewire pipewire-pulse pipewire-alsa wireplumber alsa-utils pavucontrol pamixer playerctl
    brightnessctl upower
    flatpak
)

# Display manager (X11 greeter, so it needs xorg-server) + theme deps
PKGS_LOGIN=(
    sddm xorg-server
    qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg
)
AUR_LOGIN=(sddm-astronaut-theme)

# The sway session and everything .config/sway/config calls
PKGS_SWAY=(
    sway swaybg swayidle swaylock xorg-xwayland
    grim slurp sway-contrib swappy   # sway-contrib provides grimshot
    wl-clipboard cliphist xclip
    waybar wofi rofi dunst libnotify
    xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk
    qt5-wayland qt6-wayland
    imagemagick            # wlogout-launch.sh blurs a screenshot
    keepassxc              # autostarted by the sway config
    nautilus               # $mod+n
    ranger                 # $mod+o / $mod+u
    nwg-look papirus-icon-theme materia-gtk-theme adwaita-icon-theme
)
AUR_SWAY=(
    wezterm-git            # $term (same as setup-arch.sh)
    wlogout                # $mod+Shift+e
    blueberry              # bluetooth GUI
    dropbox                # autostarted by the sway config
)

# Shell + terminal tooling (.zsh_linux, .tmux.conf, starship, lazygit, ...)
PKGS_CLI=(
    zsh zsh-autosuggestions zsh-syntax-highlighting starship
    fzf fd ripgrep zoxide thefuck lsd sd choose broot tokei watchexec trash-cli
    tmux lazygit git-delta htop fastfetch jq lnav fq mediainfo vim
    kitty
)

# Neovim (managed by bob, as in .zsh_linux's PATH) and what the plugins need:
# treesitter (cc, tree-sitter-cli), copilot/mason (node), clangd/clang-format,
# uv, codelldb via mason (unzip)
PKGS_DEV=(
    bob gcc make cmake ninja clang tree-sitter-cli nodejs npm
    python python-pip uv cgdb nasm libgit2 tinyxml2 ffmpeg
    docker
)

# Desktop apps from setup-arch.sh that aren't Hyprland-specific
PKGS_APPS=(
    firefox thunderbird obsidian okular gwenview feh vlc ark gvfs
    thunar thunar-volman thunar-archive-plugin tumbler
    qalculate-gtk bitwarden tailscale
)

# Fonts used across waybar, wofi/rofi, dunst, wezterm, nvim
PKGS_FONTS=(
    otf-font-awesome ttf-jetbrains-mono ttf-jetbrains-mono-nerd
    ttf-fira-sans ttf-fira-code ttf-firacode-nerd ttf-nerd-fonts-symbols
    ttf-roboto ttf-liberation noto-fonts noto-fonts-emoji
)

# Only for the fluid (Quickshell) variant
PKGS_FLUID=(
    quickshell qt6-imageformats matugen
    power-profiles-daemon   # Performance / Balanced / Saver in the power panel
)

# ----------------------------------------------------------
# Output helpers
# ----------------------------------------------------------

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NONE='\033[0m'

step() { echo -e "\n${GREEN}${BOLD}==> $*${NONE}"; }
info() { echo -e "${GREEN}::${NONE} $*"; }
warn() { echo -e "${YELLOW}:: $*${NONE}"; }
die()  { echo -e "${RED}:: $*${NONE}"; exit 1; }

banner() {
    clear
    echo -e "${GREEN}"
    cat <<"EOF"
   ____    __
  / __/__ / /___ _____
 _\ \/ -_) __/ // / _ \
/___/\__/\__/\_,_/ .__/
                /_/
EOF
    echo -e "${NONE}$1"
    echo
}

confirm() {
    local yn
    while true; do
        read -rp "$1 (Yy/Nn): " yn
        case $yn in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            *) echo ":: Please answer yes or no." ;;
        esac
    done
}

# ----------------------------------------------------------
# Preflight
# ----------------------------------------------------------

preflight() {
    [ "$EUID" -eq 0 ] && die "Run this as your normal user, not root (it uses sudo when needed)."
    command -v pacman >/dev/null || die "This script is for Arch / EndeavourOS."
    ping -c1 -W3 archlinux.org >/dev/null 2>&1 || die "No internet connection."

    info "Asking for sudo once up front"
    sudo -v || die "sudo failed."
    # Keep sudo alive until the script exits
    ( while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) 2>/dev/null &

    if ! command -v yay >/dev/null; then
        info "yay not found, installing it"
        sudo pacman -S --needed --noconfirm git base-devel
        local tmp; tmp="$(mktemp -d)"
        git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin" \
            && (cd "$tmp/yay-bin" && makepkg -si --noconfirm) \
            || die "Could not install yay."
        rm -rf "$tmp"
    fi
}

# ----------------------------------------------------------
# Install helpers
# ----------------------------------------------------------

# Installs a list in one go; if that fails (one bad/renamed package aborts the
# whole transaction) it retries one by one so the rest still gets installed.
install_pkgs() {
    local missing=()
    for p; do pacman -Qq "$p" >/dev/null 2>&1 || missing+=("$p"); done
    [ ${#missing[@]} -eq 0 ] && { info "already installed: $*"; return; }

    info "installing: ${missing[*]}"
    if ! yay -S --needed --noconfirm --answerdiff None --answerclean None "${missing[@]}" >>"$LOG" 2>&1; then
        warn "batch install failed, retrying one by one"
        for p in "${missing[@]}"; do
            pacman -Qq "$p" >/dev/null 2>&1 && continue
            if yay -S --needed --noconfirm --answerdiff None --answerclean None "$p" >>"$LOG" 2>&1; then
                info "  ok   $p"
            else
                warn "  FAIL $p"
                FAILED_PKGS+=("$p")
            fi
        done
    fi
}

enable_system() {
    for unit; do
        sudo systemctl enable "$unit" >>"$LOG" 2>&1 && info "enabled $unit" || warn "could not enable $unit"
    done
}

# ----------------------------------------------------------
# Steps
# ----------------------------------------------------------

do_update() {
    step "Updating the system"
    sudo pacman -Syu --noconfirm >>"$LOG" 2>&1 || warn "System update reported errors, see $LOG"
}

do_packages() {
    local fluid="$1"
    step "Installing packages (this takes a while; wezterm-git compiles from source)"
    install_pkgs "${PKGS_BASE[@]}"
    install_pkgs "${PKGS_LOGIN[@]}"
    install_pkgs "${AUR_LOGIN[@]}"
    install_pkgs "${PKGS_SWAY[@]}"
    install_pkgs "${PKGS_CLI[@]}"
    install_pkgs "${PKGS_DEV[@]}"
    install_pkgs "${PKGS_APPS[@]}"
    install_pkgs "${PKGS_FONTS[@]}"
    [ "$fluid" = "yes" ] && install_pkgs "${PKGS_FLUID[@]}"
    # The dropbox AUR package verifies its download against this key
    gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys 1C61A2656FB57B7E4DE0F4C1FC918B335044912E >>"$LOG" 2>&1 \
        || warn "could not import the Dropbox signing key; dropbox may fail to build"
    install_pkgs "${AUR_SWAY[@]}"

    # Hardware-specific extras
    if [ "$(findmnt -no FSTYPE /)" = "btrfs" ]; then
        info "btrfs root detected: adding snapshot tools"
        install_pkgs snapper-support btrfs-assistant
    fi
    if lspci 2>/dev/null | grep -qiE 'vga.*nvidia|3d.*nvidia'; then
        info "NVIDIA GPU detected"
        install_pkgs nvidia-inst
        if ! lsmod | grep -q '^nvidia'; then
            warn "No NVIDIA driver loaded yet, running nvidia-inst"
            nvidia-inst || warn "nvidia-inst failed, run it manually after reboot"
        fi
    fi
}

do_services() {
    step "Enabling services"
    enable_system NetworkManager.service bluetooth.service sddm.service fstrim.timer docker.service tailscaled.service
    pacman -Qq power-profiles-daemon >/dev/null 2>&1 && enable_system power-profiles-daemon.service
    # PipeWire runs per user; the sockets start it on demand
    systemctl --user enable pipewire.socket pipewire-pulse.socket wireplumber.service >>"$LOG" 2>&1 \
        && info "enabled pipewire (user)" || warn "could not enable pipewire user units"
    sudo usermod -aG docker "$USER" && info "added $USER to the docker group"
}

do_login_manager() {
    step "Configuring SDDM"
    sudo mkdir -p /etc/sddm.conf.d
    if [ -d /usr/share/sddm/themes/sddm-astronaut-theme ]; then
        printf '[Theme]\nCurrent=sddm-astronaut-theme\n\n[General]\nInputMethod=qtvirtualkeyboard\n' \
            | sudo tee /etc/sddm.conf.d/10-theme.conf >/dev/null
        info "SDDM theme: sddm-astronaut-theme"
    else
        warn "astronaut theme missing, SDDM will use its default theme"
    fi

    # sway refuses to start on the proprietary NVIDIA driver without this flag
    if lspci 2>/dev/null | grep -qiE 'vga.*nvidia|3d.*nvidia'; then
        sudo tee /usr/share/wayland-sessions/sway-nvidia.desktop >/dev/null <<'EOF'
[Desktop Entry]
Name=Sway (NVIDIA)
Comment=Sway with --unsupported-gpu for the proprietary NVIDIA driver
Exec=sway --unsupported-gpu
Type=Application
DesktopNames=sway
EOF
        info "Added 'Sway (NVIDIA)' session — pick it in SDDM"
    fi
}

do_dotfiles() {
    step "Linking dotfiles"

    # The sway/swaylock configs reference ~/dotfiles/... directly
    if [ "$(realpath "$HOME/dotfiles" 2>/dev/null)" != "$(realpath "$REPO_DIR")" ]; then
        if [ ! -e "$HOME/dotfiles" ]; then
            ln -s "$REPO_DIR" "$HOME/dotfiles"
            info "~/dotfiles -> $REPO_DIR"
        else
            warn "~/dotfiles exists and isn't this repo; paths in the sway config point there"
        fi
    fi

    # Move anything stow would collide with into a backup folder instead of
    # failing. --no-folding below links file by file, so ~/.config etc. stay
    # real directories and apps don't write into the repo.
    local backup="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)" moved=0
    while IFS= read -r f; do
        local target="$HOME/$f"
        case "$f" in .config/quickshell/*) continue ;; esac
        # Never move a file that is really inside the repo (reached via a linked folder)
        case "$(realpath "$target" 2>/dev/null)" in "$REPO_DIR"/*) continue ;; esac
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            mkdir -p "$backup/$(dirname "$f")"
            mv "$target" "$backup/$f"
            moved=$((moved + 1))
        fi
    done < <(cd "$REPO_DIR" && git ls-files | grep -vE '^(\.git|setup-|install|README|\.stow|\.gitmodules|\.gitignore)' | grep -v '^\.zshrc$')
    [ $moved -gt 0 ] && info "backed up $moved existing file(s) to $backup"

    # .zshrc in the repo is the macOS one (Homebrew paths); Linux gets .zsh_linux
    (cd "$REPO_DIR" && stow --no-folding -t "$HOME" --ignore='^\.zshrc$' --ignore='\.config/quickshell' .) >>"$LOG" 2>&1 \
        && info "stowed $REPO_DIR into ~" \
        || warn "stow reported problems, see $LOG"
    # The shell's folder is linked as a whole instead of file by file (stow
    # skips it above), so files added by a later `git pull` show up without
    # re-running this script. Nothing writes into it at runtime; state lives
    # in ~/.local/state/fluid.
    local qs_dir="$HOME/.config/quickshell/fluid"
    mkdir -p "$HOME/.config/quickshell"
    if [ -d "$qs_dir" ] && [ ! -L "$qs_dir" ]; then
        if [ -z "$(find "$qs_dir" ! -type l ! -type d)" ]; then
            rm -rf -- "$qs_dir"          # only old per-file links from an earlier install
        else
            mkdir -p "$backup/.config/quickshell" && mv "$qs_dir" "$backup/.config/quickshell/"
        fi
    fi
    ln -sfn "$REPO_DIR/.config/quickshell/fluid" "$qs_dir"
    info "~/.config/quickshell/fluid -> repo"

    if [ -e "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
        mkdir -p "$backup" && mv "$HOME/.zshrc" "$backup/.zshrc"
    fi
    ln -sfn "$REPO_DIR/.zsh_linux" "$HOME/.zshrc"
    info "~/.zshrc -> .zsh_linux"

    # Git merge tool settings meant to be appended to ~/.gitconfig
    if [ -f "$REPO_DIR/.gitconfig_appendix.txt" ] && ! grep -q 'mergetool "diffview"' "$HOME/.gitconfig" 2>/dev/null; then
        cat "$REPO_DIR/.gitconfig_appendix.txt" >> "$HOME/.gitconfig"
        info "appended .gitconfig_appendix.txt to ~/.gitconfig"
    fi
}

do_user_setup() {
    step "User setup"
    xdg-user-dirs-update

    if [ "$(getent passwd "$USER" | cut -d: -f7)" != "$(command -v zsh)" ]; then
        sudo chsh -s "$(command -v zsh)" "$USER" && info "login shell -> zsh"
    fi

    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        git clone -q https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm" \
            && info "tmux plugin manager installed"
        "$HOME/.tmux/plugins/tpm/bin/install_plugins" >>"$LOG" 2>&1 \
            && info "tmux plugins installed" \
            || warn "tmux plugins not installed yet: open tmux and press prefix + I"
    fi

    if command -v bob >/dev/null && [ ! -x "$HOME/.local/share/bob/nvim-bin/nvim" ]; then
        bob use stable >>"$LOG" 2>&1 && info "neovim stable installed via bob" || warn "bob use stable failed"
    fi

    mkdir -p "$HOME/.local/state/fluid"
}

do_shell_mode() {
    local mode="$1" state="$HOME/.local/state/fluid"
    mkdir -p "$state"
    echo "$mode" > "$state/shell"
    if [ "$mode" = "fluid" ]; then
        # Empty palette = the old waybar colours until a wallpaper is picked;
        # creating it now lets the shell watch the file from the first start.
        [ -f "$state/colors.json" ] || echo '{}' > "$state/colors.json"
        [ -f "$state/mode" ] || echo dark > "$state/mode"
        chmod +x "$REPO_DIR/.config/quickshell/fluid/scripts/"*.sh
        info "bar: fluid shell (Quickshell), waybar as fallback"
    else
        info "bar: waybar + dunst"
    fi
}

summary() {
    step "Done"
    if [ ${#FAILED_PKGS[@]} -gt 0 ]; then
        warn "These packages failed to install: ${FAILED_PKGS[*]}"
        warn "Retry later with: yay -S ${FAILED_PKGS[*]}"
    fi
    echo "Full log: $LOG"
    echo
    echo "Reboot, pick the Sway session in SDDM and log in."
}
