-- Pull in the wezterm API
local wezterm = require("wezterm")

local config = wezterm.config_builder()
config.leader = { key = 'e', mods = 'CTRL', timeout_milliseconds = 1000 }

config.window_padding = {
  left = 0,
  right = 0,
  top = 0,
  bottom = 0,
}

config.keys = {
  -- splitting
  {
    mods   = "LEADER",
    key    = "v",
    action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' }
  },
  {
    mods   = "LEADER",
    key    = "h",
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' }
  },
  {
    mods = 'LEADER',
    key = 'm',
    action = wezterm.action.TogglePaneZoomState
  },
  {
    mods = 'LEADER',
    key = 'y',
    action = wezterm.action.ActivateCopyMode
  }
}

local function is_vim(pane)
  -- this is set by the plugin, and unset on ExitPre in Neovim
  return pane:get_user_vars().IS_NVIM == 'true'
end

local direction_keys = {
  Left = 'h',
  Down = 'j',
  Up = 'k',
  Right = 'l',
  -- reverse lookup
  h = 'Left',
  j = 'Down',
  k = 'Up',
  l = 'Right',
}

local function split_nav(resize_or_move, key)
  return {
    key = key,
    mods = resize_or_move == 'resize' and 'META' or 'CTRL',
    action = wezterm.action_callback(function(win, pane)
      if is_vim(pane) then
        -- pass the keys through to vim/nvim
        win:perform_action({
          SendKey = { key = key, mods = resize_or_move == 'resize' and 'META' or 'CTRL' },
        }, pane)
      else
        if resize_or_move == 'resize' then
          win:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
        else
          win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
        end
      end
    end),
  }
end

config.keys = {
  -- move between split panes
  split_nav('move', 'h'),
  split_nav('move', 'j'),
  split_nav('move', 'k'),
  split_nav('move', 'l'),
  -- resize panes
  split_nav('resize', 'h'),
  split_nav('resize', 'j'),
  split_nav('resize', 'k'),
  split_nav('resize', 'l'),
  -- include leader key bindings
  {
    mods = "LEADER",
    key = "v",
    action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' }
  },
  {
    mods = "LEADER",
    key = "h",
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' }
  },
  {
    mods = 'LEADER',
    key = 'm',
    action = wezterm.action.TogglePaneZoomState
  },
  {
    mods = 'LEADER',
    key = 'y',
    action = wezterm.action.ActivateCopyMode
  },
	{
		mods = 'LEADER',
		key = 'z',
		action = wezterm.action.ToggleFullScreen
	}
}

-- Linux: Ctrl+Shift+V pastes files copied in a file manager as their
-- (quoted) paths instead of nothing; everything else pastes normally
if wezterm.target_triple:find('linux') then
  table.insert(config.keys, {
    mods = 'CTRL|SHIFT',
    key = 'v',
    action = wezterm.action_callback(function(win, pane)
      local ok, types = wezterm.run_child_process { 'wl-paste', '--list-types' }
      if ok and types:find('text/uri-list', 1, true) then
        local _, uris = wezterm.run_child_process { 'wl-paste', '--no-newline', '--type', 'text/uri-list' }
        local paths = {}
        for line in (uris or ''):gmatch('[^\r\n]+') do
          local path = line:match('^file://[^/]*(/.*)$')
          if path then
            path = path:gsub('%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
            table.insert(paths, wezterm.shell_quote_arg(path))
          end
        end
        if #paths > 0 then
          pane:send_paste(table.concat(paths, ' '))
          return
        end
      end
      win:perform_action(wezterm.action.PasteFrom 'Clipboard', pane)
    end),
  })
end

config.scrollback_lines = 3500

-- config.color_scheme = 'tokyonight-storm'
-- config.color_scheme = 'duskfox'
config.color_scheme = 'Everforest Dark (Gogh)'
-- Icons come from the Nerd Font symbols font, named explicitly so the system
-- never falls back to Font Awesome (same codepoints, different icons)
config.font = wezterm.font_with_fallback { 'JetBrains Mono', 'Symbols Nerd Font Mono' }
config.font_size = 19

config.enable_tab_bar = false

config.window_background_opacity = 0.75
-- Linux: $mod+Shift+o (fluid-opacity.sh) makes every window solid, this one too
if wezterm.target_triple:find('linux') then
  local mode = wezterm.home_dir .. '/.local/state/fluid/opacity'
  local f = io.open(mode)
  if f then
    if f:read('l') == 'solid' then config.window_background_opacity = 1.0 end
    f:close()
  end
  wezterm.add_to_config_reload_watch_list(mode)
end
-- config.macos_window_background_blur = 10

-- Fluid theme picker: once a wallpaper has been picked, follow its colours.
-- Until then (or if the file is missing) the colour scheme above is used.
local fluid_colors = wezterm.home_dir .. '/.local/state/fluid/wezterm-colors.lua'
local ok, colors = pcall(dofile, fluid_colors)
if ok and type(colors) == 'table' then
	config.color_scheme = nil
	config.colors = colors
end
wezterm.add_to_config_reload_watch_list(fluid_colors)

return config
