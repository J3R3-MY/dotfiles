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

config.scrollback_lines = 3500

-- config.color_scheme = 'tokyonight-storm'
config.color_scheme = 'duskfox'
config.font = wezterm.font 'JetBrains Mono'
config.font_size = 19

config.enable_tab_bar = false

config.window_background_opacity = 0.75
-- config.macos_window_background_blur = 10

return config
