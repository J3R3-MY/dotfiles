# Fluid shell for sway

A Quickshell layer on top of the existing sway setup: same bar layout and
colours as the old waybar, plus macOS-style motion and panels. Everything that
worked before still works; the new parts only add things.

Inspired by [serpantinum](https://github.com/ilyamiro/serpantinum),
[Monoland](https://github.com/AdiKsOnDev/Monoland) and
[dotfiles-arch](https://github.com/SaratAngajalaoffl/dotfiles-arch). No code was
copied from them (Monoland and dotfiles-arch have no licence; serpantinum is
AGPL), so this stays under the repo's MIT licence.

## What you get

| Feature | Where | Notes |
|---|---|---|
| Fluid bar | top of every output | Waybar layout and colours. Sliding workspace highlight, pills widen on hover to show details |
| Dynamic island | the clock | Morphs into launcher, clipboard, media, dashboard, theme picker or cheat sheet. Live equaliser bars while music plays; hover to see the track |
| Dashboard | click the clock, `$mod+c` | Calendar, big clock with the next 24 h of weather around it, wind/humidity/rain/feels-like rings, 7-day strip. Second tab: screen time |
| Screen time | dashboard → Screen time | Per-app time, last 7 days, month heatmap, by-hour chart. Logged from sway focus events, paused when idle/locked, stored in `~/.local/state/fluid/screentime` |
| Control center | top-right corner, status pills, `$mod+i` | Toggles, sliders, media, notifications, power row. Wi-Fi and Bluetooth pages use the "orbit" view (connected thing in the middle, the rest around it); Displays page sets resolution/refresh/scale with a 15 s revert |
| Power panel | click the battery pill | Battery ring, uptime, brightness/volume, lock/suspend/reboot/off, Performance/Balanced/Saver |
| Theme picker | `$mod+t` | Carousel of slanted wallpaper cards with colour filter; matugen recolours bar, panels, sway borders and WezTerm. Tweaks: dark/light, base colour, hue, style, contrast, brightness, shuffle/reset |
| Media | `$mod+m`, right-click the clock | Spinning-record cover, seek bar, 10-band equalizer with presets (PipeWire filter-chain, no EasyEffects) |
| Lock screen | `$mod+Shift+s`, idle, before sleep | Blurred wallpaper + clock, password pill on any key. Falls back to swaylock without the shell |
| OSD | bottom centre | Appears for any volume/brightness change |
| Notifications | top right | Replace dunst while the shell runs |
| Cheat sheet | `$mod+?`, `$mod+F1` | Generated from the sway config |

Weather comes from Open-Meteo. The location is guessed once from your IP via
ipinfo.io and stored in `~/.local/state/fluid/location` as `lat,lon,City`;
edit that file to set it yourself. Only those coordinates are sent to Open-Meteo.

## Keys

Old binds are untouched. New ones use keys that were unbound:

| Key | Action |
|---|---|
| `$mod+p` | App launcher (wofi stays on `$mod+d`) |
| `$mod+v` | Clipboard history (Enter copies, Shift+Del removes) |
| `$mod+m` | Media |
| `$mod+c` | Dashboard (calendar, weather, screen time) |
| `$mod+t` | Wallpaper / theme picker |
| `$mod+i` | Control center |
| `$mod+Escape` | Close whatever is open |
| `$mod+?` / `$mod+F1` | Keybind cheat sheet (built from the sway config, so new binds appear automatically) |
| `$mod+Alt+w` / `$mod+Alt+q` | Switch to the old waybar setup / back to the fluid shell |

Bar mouse: left-click a status pill opens the control center, right-click
audio opens pavucontrol (the old waybar on-click), middle-click mutes, scroll
on audio/backlight changes the level.

## Install (fresh EndeavourOS, "No Desktop")

```bash
git clone <this repo> ~/dotfiles
cd ~/dotfiles
./install-sway.sh          # sway + waybar + dunst (the plain setup)
./install-sway-fluid.sh    # the same, plus the Quickshell fluid shell
```

Reboot afterwards and pick **Sway** in SDDM (**Sway (NVIDIA)** on NVIDIA cards).

Both scripts share `install/lib.sh` and:

- install everything the sway config, scripts, zsh/tmux/nvim setup and the
  apps from `setup-arch.sh` use (Hyprland-only packages are left out)
- add snapper/btrfs-assistant on btrfs and run `nvidia-inst` on NVIDIA
- enable NetworkManager, bluetooth, SDDM (astronaut theme), fstrim, docker,
  tailscaled and PipeWire
- stow the repo into `~` file by file, moving clashing files to
  `~/.dotfiles-backup-<date>` first
- link `~/.zshrc` to `.zsh_linux` (the repo's `.zshrc` is the macOS one) and
  `~/dotfiles` to the repo (the sway config uses those paths)
- set zsh as login shell, install tpm, install neovim through bob, append
  `.gitconfig_appendix.txt` to `~/.gitconfig`

They're safe to re-run. Packages that fail are listed at the end; the full
log is in `~/dotfiles-install-<date>.log`.

## Downwards compatibility

- `fluid-launch.sh` starts the shell. If Quickshell isn't installed it starts
  waybar + dunst instead. If the shell crashes three times within 10 s of
  starting, it also falls back to waybar + dunst and sends a notification.
- Nothing in the old waybar, rofi, wofi, wlogout or swaylock configs changed.
- Before you pick a wallpaper, the shell uses the old waybar colours and sway
  keeps its `output * bg` line. WezTerm keeps Everforest.
- To remove it completely: comment out `include ~/.config/sway/fluid.conf`
  and un-comment `exec waybar` in `.config/sway/config`.

## Layout

```
.config/quickshell/fluid/
  shell.qml            entry point: wallpaper, bar, overlay per output
  Overlay.qml          island + control center + toasts + OSD (one layer per output)
  common/              Theme (colours), Anim (curves), Fluid (state + IPC), small widgets
  services/            sway, audio, brightness, network, bluetooth, battery, cpu/mem,
                       media, notifications, wallpaper, clipboard, apps
  bar/ island/ panels/ wallpaper/
  scripts/             fluid-launch.sh, fluid-theme.sh
  matugen/             config + templates (output goes to ~/.local/state/fluid)
.config/sway/fluid.conf  autostart + new binds, included from the sway config
```

Generated state (wallpaper, mode, colours, log) lives in `~/.local/state/fluid`,
never in the repo.

## Debugging

```bash
qs -c fluid                                  # run in the foreground to see errors
tail -f ~/.local/state/fluid/fluid.log       # log when started by fluid-launch.sh
qs -c fluid ipc call fluid toggle launcher   # drive it by hand
```

## If the lock screen ever gets stuck

Sway keeps the session locked if the shell crashes while locked, and the shell
re-locks itself when it restarts. If that doesn't happen, switch to a TTY
(Ctrl+Alt+F2), log in and run `WAYLAND_DISPLAY=wayland-1 swaylock`, then go
back (Ctrl+Alt+F1) and unlock with swaylock.

## Not done yet

- Not tested on a real machine yet: written on macOS, where Quickshell can't run.
- No system tray (the old waybar config didn't show one either).
- The scratchpad counter from waybar isn't in the bar yet.
- New secured Wi-Fi networks open `nmtui-connect` for the password; known
  networks connect directly.
