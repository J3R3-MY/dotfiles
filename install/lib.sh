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
    firewalld fwupd         # firewall, firmware updates (see do_hardening)
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
    sddm xorg-server qt6-svg qt6-declarative
)

# The sway session and everything .config/sway/config calls
PKGS_SWAY=(
    swaybg swayidle swaylock xorg-xwayland
    grim slurp sway-contrib swappy   # sway-contrib provides grimshot
    wl-clipboard cliphist xclip
    waybar wofi rofi dunst libnotify
    xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk
    qt5-wayland qt6-wayland
    imagemagick            # SDDM wallpaper copy, wallpaper colour filter
    wezterm                # $term
    nautilus               # $mod+n
    ranger                 # $mod+o / $mod+u
    nwg-look papirus-icon-theme materia-gtk-theme adwaita-icon-theme
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
    ttf-fira-sans ttf-fira-code ttf-firacode-nerd ttf-nerd-fonts-symbols ttf-nerd-fonts-symbols-mono
    ttf-roboto ttf-liberation noto-fonts noto-fonts-emoji
)

# Only for the fluid (Quickshell) variant
PKGS_FLUID=(
    quickshell qt6-imageformats matugen
    power-profiles-daemon   # Performance / Balanced / Saver in the power panel
    spotify-player          # Spotify view ($mod+Shift+m), needs Premium
    bitwarden-cli           # Bitwarden view ($mod+Shift+p)
    kanshi                  # monitor profiles applied on hotplug
    iw                      # Wi-Fi link details in the network panel
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
        info "yay not found, building it from the pinned AUR commit"
        sudo pacman -S --needed --noconfirm git base-devel
        aur_pinned yay-bin || die "Could not install yay."
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
    step "Installing packages (this takes a while; swayfx is built from source)"
    install_pkgs "${PKGS_BASE[@]}"
    install_pkgs "${PKGS_LOGIN[@]}"
    install_swayfx
    # stable wezterm replaces the wezterm-git build earlier installs used
    pacman -Qq wezterm-git >/dev/null 2>&1 && sudo pacman -Rdd --noconfirm wezterm-git >>"$LOG" 2>&1
    install_pkgs "${PKGS_SWAY[@]}"
    install_pkgs "${PKGS_CLI[@]}"
    install_pkgs "${PKGS_DEV[@]}"
    install_pkgs "${PKGS_APPS[@]}"
    install_pkgs "${PKGS_FONTS[@]}"
    [ "$fluid" = "yes" ] && install_pkgs "${PKGS_FLUID[@]}"

    # Hardware-specific extras
    if [ "$(findmnt -no FSTYPE /)" = "btrfs" ]; then
        info "btrfs root detected: adding snapshot tools"
        install_pkgs btrfs-progs snapper-support btrfs-assistant   # btrfs-progs: hibernation swap file
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

# SwayFX (sway + rounded corners, blur, shadows) from the AUR replaces sway.
# It conflicts with the sway package, so sway is removed first and put back
# if the SwayFX build fails, leaving you with a working compositor either way.
install_swayfx() {
    pacman -Qq swayfx >/dev/null 2>&1 && { info "already installed: swayfx"; return; }
    pacman -Qq sway >/dev/null 2>&1 && sudo pacman -Rdd --noconfirm sway >>"$LOG" 2>&1
    info "building swayfx (pinned AUR commits)"
    if ! { aur_pinned scenefx0.5 && aur_pinned swayfx; }; then
        warn "swayfx failed to build, using plain sway"
        FAILED_PKGS+=(swayfx)
        install_pkgs sway
    fi
}

# Build an AUR package from the commit pinned in install/aur-pins, checking
# any extra source hash listed there before building.
aur_pinned() {
    local pkg="$1" line commit extra tmp
    line=$(grep -E "^$pkg[[:space:]]" "$REPO_DIR/install/aur-pins") || { warn "$pkg is not pinned"; return 1; }
    read -r _ commit extra <<<"$line"
    tmp=$(mktemp -d)
    (
        set -e
        cd "$tmp"
        git clone -q "https://aur.archlinux.org/$pkg.git" "$pkg"
        cd "$pkg"
        git checkout -q --detach "$commit"
        makepkg -o --noconfirm >>"$LOG" 2>&1              # download + extract
        if [ -n "$extra" ]; then
            echo "${extra#*=}  ${extra%%=*}" | sha256sum -c --quiet || { echo "hash mismatch for ${extra%%=*}" >&2; exit 1; }
        fi
        makepkg -si --noconfirm --needed >>"$LOG" 2>&1
    ) || { warn "pinned build of $pkg failed, see $LOG"; rm -rf "$tmp"; return 1; }
    rm -rf "$tmp"
}

do_services() {
    step "Enabling services"
    enable_system NetworkManager.service bluetooth.service sddm.service fstrim.timer docker.socket tailscaled.service
    pacman -Qq power-profiles-daemon >/dev/null 2>&1 && enable_system power-profiles-daemon.service
    # Let the VPN panel switch Tailscale without sudo
    if command -v tailscale >/dev/null; then
        sudo systemctl start tailscaled.service >>"$LOG" 2>&1
        sudo tailscale set --operator="$USER" >>"$LOG" 2>&1 && info "tailscale: $USER can switch it without sudo"
    fi
    # PipeWire runs per user; the sockets start it on demand
    systemctl --user enable pipewire.socket pipewire-pulse.socket wireplumber.service >>"$LOG" 2>&1 \
        && info "enabled pipewire (user)" || warn "could not enable pipewire user units"
    # Docker starts on first use (socket). No docker group: membership is
    # passwordless root, so use `sudo docker` (or set up rootless Docker).
}

do_login_manager() {
    step "Configuring SDDM"
    do_sddm_theme ""

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

# ----------------------------------------------------------
# SDDM login theme (sddm/fluid in the repo, copied out so it doesn't depend
# on the repo). Standalone: install/sddm.sh [image]
# ----------------------------------------------------------

do_sddm_theme() {
    local img="$1" dest=/usr/share/sddm/themes/fluid
    local state="$HOME/.local/state/fluid"

    if [ -z "$img" ]; then
        local walls=() current
        current="$(cat "$state/wallpaper" 2>/dev/null)"
        mapfile -t walls < <(find -L "$REPO_DIR/.config/wallpapers" -maxdepth 1 -type f \
            \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) ! -name '._*' | sort)
        if [ -t 0 ] && command -v gum >/dev/null && [ ${#walls[@]} -gt 0 ]; then
            echo "Pick the login screen wallpaper:"
            img="$(printf '%s\n' "${current:+[current] $current}" "${walls[@]}" | sed '/^$/d' \
                | gum choose --height 15 | sed 's/^\[current\] //')"
        fi
        [ -z "$img" ] && img="${current:-$REPO_DIR/.config/wallpapers/knight.JPG}"
    fi
    if [ ! -f "$img" ]; then warn "wallpaper $img not found, SDDM theme not installed"; return; fi

    sudo rm -rf "$dest"
    sudo mkdir -p "$dest"
    sudo cp "$REPO_DIR/sddm/fluid/Main.qml" "$REPO_DIR/sddm/fluid/metadata.desktop" "$dest/"
    # Scaled-down JPEG copy: loads fast, works for PNG/WebP sources too
    if command -v magick >/dev/null; then
        magick "$img[0]" -resize '2560x2560>' -quality 90 /tmp/fluid-sddm-bg.jpg && sudo mv /tmp/fluid-sddm-bg.jpg "$dest/background.jpg"
    else
        sudo cp "$img" "$dest/background.jpg"
    fi

    # Colours from the current fluid theme (matugen), else the waybar defaults
    local c="$state/colors.json" accent="#c4bca4" on="#0e0c0c" panel="#0e0c0c" fg="#ffffff" dim="#a7a097"
    if [ -s "$c" ] && command -v jq >/dev/null; then
        accent=$(jq -r '.clock // "#c4bca4"' "$c"); on=$(jq -r '.onPill // "#0e0c0c"' "$c")
        panel=$(jq -r '.bg // "#0e0c0c"' "$c"); fg=$(jq -r '.fg // "#ffffff"' "$c"); dim=$(jq -r '.fgDim // "#a7a097"' "$c")
    fi
    printf '[General]\nbackground=background.jpg\naccent=%s\nonAccent=%s\npanel=%s\nfg=%s\nfgDim=%s\nfont=Roboto\nclockFont=JetBrains Mono\n' \
        "$accent" "$on" "$panel" "$fg" "$dim" | sudo tee "$dest/theme.conf" >/dev/null

    sudo mkdir -p /etc/sddm.conf.d
    printf '[Theme]\nCurrent=fluid\n' | sudo tee /etc/sddm.conf.d/10-theme.conf >/dev/null
    # Old astronaut theme: AUR package (earlier installer) or copied files (setup-arch.sh)
    if pacman -Qq sddm-astronaut-theme >/dev/null 2>&1; then
        sudo pacman -Rns --noconfirm sddm-astronaut-theme >>"$LOG" 2>&1 && info "removed sddm-astronaut-theme"
    elif [ -d /usr/share/sddm/themes/sddm-astronaut-theme ]; then
        sudo rm -rf /usr/share/sddm/themes/sddm-astronaut-theme && info "removed the old astronaut theme files"
    fi
    # its setup script set it in /etc/sddm.conf, which would override the drop-in
    [ -f /etc/sddm.conf ] && sudo sed -i 's/^Current=sddm-astronaut-theme$/Current=fluid/' /etc/sddm.conf
    info "SDDM theme: fluid, wallpaper $(basename "$img") (preview: sddm-greeter-qt6 --test-mode --theme $dest)"
}

# ----------------------------------------------------------
# Hardening: MAC randomization, firewall, encrypted DNS, kernel settings,
# firmware updates. Each part is a small drop-in file you can delete.
# ----------------------------------------------------------

do_hardening() {
    step "Security and privacy"

    # MAC: random per Wi-Fi network but stable on it until reboot (captive
    # portals and router reservations keep working), random while scanning,
    # no hostname in DHCP, temporary IPv6 addresses.
    sudo mkdir -p /etc/NetworkManager/conf.d
    sudo tee /etc/NetworkManager/conf.d/10-fluid-privacy.conf >/dev/null <<'CONF'
[device]
wifi.scan-rand-mac-address=yes

[connection]
wifi.cloned-mac-address=stable
ethernet.cloned-mac-address=stable
connection.stable-id=${CONNECTION}/${BOOT}
ipv4.dhcp-send-hostname=false
ipv6.dhcp-send-hostname=false
ipv6.ip6-privacy=2
CONF
    info "MAC randomization + no hostname over DHCP (applies on the next connect)"

    # Firewall: EndeavourOS' firewalld already drops unsolicited incoming
    # traffic; just make sure it runs, and close ssh (no ssh server here).
    enable_system firewalld.service
    sudo systemctl start firewalld.service >>"$LOG" 2>&1
    sudo firewall-cmd -q --permanent --remove-service=ssh 2>/dev/null && sudo firewall-cmd -q --reload

    # DNS over TLS to Quad9 with DNSSEC. On a hotel/airport login page that
    # blocks it: `resolvectl dnsovertls <interface> no` until you're through.
    sudo mkdir -p /etc/systemd/resolved.conf.d
    sudo tee /etc/systemd/resolved.conf.d/10-fluid-dot.conf >/dev/null <<'CONF'
[Resolve]
DNS=9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net 2620:fe::fe#dns.quad9.net 2620:fe::9#dns.quad9.net
Domains=~.
DNSOverTLS=yes
DNSSEC=allow-downgrade
FallbackDNS=
CONF
    enable_system systemd-resolved.service
    sudo systemctl restart systemd-resolved.service >>"$LOG" 2>&1
    sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
    info "DNS: Quad9 over TLS"

    # Kernel: only settings Arch doesn't already default to
    sudo tee /etc/sysctl.d/90-fluid-hardening.conf >/dev/null <<'CONF'
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.kexec_load_disabled = 1
net.core.bpf_jit_harden = 2
dev.tty.ldisc_autoload = 0
fs.protected_fifos = 2
fs.protected_regular = 2
fs.suid_dumpable = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
CONF
    sudo sysctl --system >>"$LOG" 2>&1
    info "kernel hardening settings applied"

    # Firmware: refresh LVFS metadata daily; install updates with `fwupdmgr update`
    enable_system fwupd-refresh.timer
}

# ----------------------------------------------------------
# Sleep like a Mac: suspend instantly, hibernate after 2 h asleep
# (suspend-then-hibernate). Needs swap >= RAM and resume in the initramfs;
# falls back to plain suspend (and says why) when hibernation can't work.
# Standalone: install/hibernate.sh
# ----------------------------------------------------------

do_hibernate() {
    step "Hibernation"
    local lid=suspend-then-hibernate reason=""

    if [ ! -d /sys/firmware/efi ]; then
        lid=suspend; reason="not booted with UEFI (resume location would need manual kernel parameters)"
    elif grep -qE '\[(integrity|confidentiality)\]' /sys/kernel/security/lockdown 2>/dev/null; then
        lid=suspend; reason="kernel lockdown is on (Secure Boot), the kernel refuses to hibernate"
    fi

    if [ "$lid" = suspend-then-hibernate ]; then
        # 1. Disk swap at least RAM + 2 GiB (zram doesn't count, it lives in RAM)
        local ram_kb need_kb have_kb size_g file fs
        ram_kb=$(awk '/MemTotal/{print $2}' /proc/meminfo)
        need_kb=$(( ram_kb + 2 * 1024 * 1024 ))
        have_kb=$(swapon --show=NAME,SIZE --bytes --noheadings 2>/dev/null | grep -v zram | awk '{s += $2} END {print int(s / 1024)}')
        if [ "${have_kb:-0}" -lt "$need_kb" ]; then
            size_g=$(( (need_kb + 1048575) / 1048576 ))
            fs=$(findmnt -no FSTYPE /)
            if [ "$(df --output=avail -k / | tail -n1)" -lt $(( need_kb + 5 * 1048576 )) ]; then
                lid=suspend; reason="not enough free disk space for a ${size_g} GiB swap file"
            else
                info "creating a ${size_g} GiB swap file for hibernation"
                sudo cp -n /etc/fstab /etc/fstab.before-fluid
                if [ "$fs" = btrfs ]; then
                    # own subvolume so snapshots skip it; btrfs needs its own mkswapfile
                    [ -e /swap ] || sudo btrfs subvolume create /swap >>"$LOG" 2>&1
                    file=/swap/swapfile
                    [ -e "$file" ] || sudo btrfs filesystem mkswapfile --size "${size_g}g" "$file" >>"$LOG" 2>&1
                else
                    file=/swapfile
                    [ -e "$file" ] || sudo mkswap -U clear --size "${size_g}G" --file "$file" >>"$LOG" 2>&1
                fi
                sudo chmod 600 "$file"
                sudo swapon "$file" >>"$LOG" 2>&1 || warn "swapon $file failed, see $LOG"
                grep -q "^$file " /etc/fstab || echo "$file none swap defaults 0 0" | sudo tee -a /etc/fstab >/dev/null
            fi
        else
            info "existing swap is big enough"
        fi
    fi

    if [ "$lid" = suspend-then-hibernate ]; then
        # 2. Resume support in the initramfs. With systemd in the initramfs
        #    (dracut, EndeavourOS' default) the resume location comes from an
        #    EFI variable systemd writes when hibernating, so no kernel
        #    parameters are needed, even for a swap file on btrfs.
        if command -v dracut >/dev/null; then
            echo 'add_dracutmodules+=" resume "' | sudo tee /etc/dracut.conf.d/fluid-resume.conf >/dev/null
            info "rebuilding the initramfs (dracut)"
            if command -v dracut-rebuild >/dev/null; then sudo dracut-rebuild >>"$LOG" 2>&1
            elif command -v reinstall-kernels >/dev/null; then sudo reinstall-kernels >>"$LOG" 2>&1
            else sudo dracut --regenerate-all --force >>"$LOG" 2>&1; fi \
                || warn "initramfs rebuild reported errors, see $LOG"
        elif [ -f /etc/mkinitcpio.conf ] && grep -qE '^HOOKS=.*\bsystemd\b' /etc/mkinitcpio.conf; then
            info "mkinitcpio uses the systemd hook, resume is built in"
        else
            lid=suspend; reason="initramfs without systemd: hibernating from a swap file needs resume= kernel parameters"
        fi
    fi

    # 3. Ask logind whether it agrees (checks swap size etc.)
    if [ "$lid" = suspend-then-hibernate ] && ! busctl call org.freedesktop.login1 /org/freedesktop/login1 \
            org.freedesktop.login1.Manager CanHibernate 2>/dev/null | grep -q '"yes"'; then
        lid=suspend; reason="logind says hibernation isn't possible yet (try again after a reboot)"
    fi

    # 4. How long to stay suspended before hibernating
    sudo mkdir -p /etc/systemd/sleep.conf.d
    printf '[Sleep]\nHibernateDelaySec=2h\n' | sudo tee /etc/systemd/sleep.conf.d/10-fluid.conf >/dev/null

    # 5. Lid: sleep (docked with the lid closed keeps working)
    sudo mkdir -p /etc/systemd/logind.conf.d
    printf '[Login]\nHandleLidSwitch=%s\nHandleLidSwitchExternalPower=%s\nHandleLidSwitchDocked=ignore\n' "$lid" "$lid" \
        | sudo tee /etc/systemd/logind.conf.d/10-fluid-lid.conf >/dev/null
    sudo systemctl kill -s HUP systemd-logind >>"$LOG" 2>&1

    # 6. Automatic log of every sleep/wake/boot in ~/.local/state/fluid/sleep.log
    #    (the lid lines come from the sway config). systemd only runs sleep
    #    hooks from /usr/lib/systemd/system-sleep.
    local slog="$HOME/.local/state/fluid/sleep.log"
    mkdir -p "$(dirname "$slog")" && touch "$slog"
    sudo rm -f /etc/systemd/system-sleep/fluid-log
    sudo mkdir -p /usr/lib/systemd/system-sleep
    sed "s|@LOG@|$slog|" <<'HOOK' | sudo tee /usr/lib/systemd/system-sleep/fluid-log >/dev/null
#!/bin/sh
# Logs each sleep and wake for the fluid setup (installed by install/lib.sh).
# $1 = pre|post, $2 = suspend|hibernate|suspend-then-hibernate|...,
# SYSTEMD_SLEEP_ACTION = the phase within suspend-then-hibernate.
log=@LOG@
state() { echo "battery=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1)% ac=$(cat /sys/class/power_supply/A*/online 2>/dev/null | head -n1) lid=$(awk '{print $2}' /proc/acpi/button/lid/*/state 2>/dev/null)"; }
what="$2${SYSTEMD_SLEEP_ACTION:+/$SYSTEMD_SLEEP_ACTION}"
case "$1" in
    pre)  # let the kernel log how long each step and each device takes
          echo 1 > /sys/power/pm_print_times 2>/dev/null; echo 1 > /sys/power/pm_debug_messages 2>/dev/null
          echo "$(date '+%F %T')  sleep  $what  $(state)" >> "$log" ;;
    post)
        { echo "$(date '+%F %T')  wake   $what  $(state)"
          # PM steps with their durations, plus any device slower than 0.2 s
          journalctl -b -k --since -3min --no-pager -o short-precise 2>/dev/null \
            | awk '/ after [0-9]+ usecs/ { for (i = 1; i < NF; i++) if ($(i+1) == "usecs" && $i > 200000) { print; break } next }
                   /PM: (suspend|resume|hibernation|image)|complete after|took [0-9]|nvidia/' \
            | tail -n 20 | sed 's/^/        /'
        } >> "$log"
        # did the shell survive? Checked 15 s later by a timer (a background
        # job would be killed together with systemd-sleep)
        systemd-run --quiet --no-block --collect --on-active=15 "$0" check
        ;;
    check)
        pgrep -f '(qs|quickshell) -c fluid' >/dev/null && r=running || r="NOT running"
        echo "$(date '+%F %T')  shell  $r" >> "$log" ;;
esac
exit 0
HOOK
    sudo chmod 755 /usr/lib/systemd/system-sleep/fluid-log
    sed "s|@LOG@|$slog|" <<'UNIT' | sudo tee /etc/systemd/system/fluid-sleep-boot.service >/dev/null
[Unit]
Description=Note boots in the fluid sleep log (flags a sleep that never woke up)

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'l=@LOG@; [ -f $l ] || exit 0; grep -E "^[0-9-]+ [0-9:]+  (sleep|wake|boot) " $l | tail -n1 | grep -q "  sleep " && echo "$(date "+%%F %%T")  BOOT without a wake: the last sleep did not resume, the machine booted fresh" >> $l; echo "$(date "+%%F %%T")  boot" >> $l; [ "$(wc -l < $l)" -gt 2000 ] && tail -n 1000 $l > $l.tmp && cat $l.tmp > $l && rm $l.tmp; exit 0'

[Install]
WantedBy=multi-user.target
UNIT
    sudo systemctl daemon-reload
    enable_system fluid-sleep-boot.service
    echo "$(date '+%F %T')  setup  sleep logging installed" >> "$slog"

    if [ "$lid" = suspend-then-hibernate ]; then
        info "lid / 5 min idle: sleep, hibernate after 2 h asleep (hibernation works after the next reboot)"
    else
        warn "hibernation not set up: $reason"
        warn "closing the lid / 5 min idle will just suspend"
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
