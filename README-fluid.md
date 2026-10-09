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
| Fluid bar | top of every output | Waybar layout and colours. Sliding workspace highlight, pills widen on hover to show details (IP, sink name, RAM GiB, battery time) |
| Dynamic island | the clock | Morphs into launcher, clipboard, media, calendar or theme picker. Shows a "live" equaliser while music plays; hover to see the track |
| Control center | hover the top-right corner, click a status pill, or `$mod+i` | Wi-Fi/Bluetooth/DND/mic tiles with detail pages, volume + brightness sliders, media, notification history, power menu |
| Theme selector | `$mod+t` | Pick a wallpaper; matugen recolours bar, panels, sway borders and WezTerm. Dark/light switch |
| OSD | bottom centre | Appears for any volume/brightness change, including the old pamixer/brightnessctl keys |
| Notifications | top right | Replaces dunst while the shell runs |

## Keys

Old binds are untouched. New ones use keys that were unbound:

| Key | Action |
|---|---|
| `$mod+p` | App launcher (wofi stays on `$mod+d`) |
| `$mod+v` | Clipboard history (Enter copies, Shift+Del removes) |
| `$mod+m` | Media |
| `$mod+c` | Calendar |
| `$mod+t` | Wallpaper / theme picker |
| `$mod+i` | Control center |
| `$mod+Escape` | Close whatever is open |
| `$mod+Alt+w` / `$mod+Alt+q` | Switch to the old waybar setup / back to the fluid shell |

Bar mouse: left-click a status pill opens the control center, right-click
audio opens pavucontrol (the old waybar on-click), middle-click mutes, scroll
on audio/backlight changes the level.

## Install (Arch)

Run the main script first, then the fluid one:

```bash
./setup-arch.sh
./setup-fluid.sh
```

`setup-fluid.sh` installs sway and the shell's dependencies, enables
NetworkManager, bluetooth and PipeWire, stows the repo into `~` (it reports
conflicts instead of overwriting), prepares `~/.local/state/fluid`, and starts
the shell right away if you run it inside sway.

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

## Not done yet

- Not tested on a real machine yet: written on macOS, where Quickshell can't run.
- No system tray (the old waybar config didn't show one either).
- The scratchpad counter from waybar isn't in the bar yet.
- New secured Wi-Fi networks open `nmtui-connect` for the password; known
  networks connect directly.
