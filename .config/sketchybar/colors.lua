local M = {}

local with_alpha = function(color, alpha)
  if alpha > 1.0 or alpha < 0.0 then
    return color
  end
  return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
end

M.with_alpha = with_alpha

-- Convert a "#rrggbb" string to a sketchybar 0xffrrggbb integer
local function hex(str)
  return tonumber("0xff" .. str:gsub("^#", ""))
end

-- Parse a wal/pywal/hellwal colors.json and return the 16-color palette.
-- Returns nil if the file doesn't exist or is malformed.
local function load_colors_json(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local content = f:read("*a")
  f:close()

  local palette = {}
  for key, val in content:gmatch('"(color%d+)"%s*:%s*"(#%x+)"') do
    palette[key] = hex(val)
  end
  local bg = content:match('"background"%s*:%s*"(#%x+)"')
  if bg then palette.background = hex(bg) end
  local fg = content:match('"foreground"%s*:%s*"(#%x+)"')
  if fg then palette.foreground = hex(fg) end

  if not palette.color0 then return nil end
  return palette
end

-- Map a standard 16-color wal palette to sketchybar semantic roles.
-- Follows the conventional terminal color assignments:
--   0  = background   1  = red     2  = green  3  = yellow
--   4  = blue         5  = magenta 6  = cyan   7  = white
--   8  = bright black (dark grey)  …  15 = bright white
local function palette_to_theme(p)
  return {
    base          = p.background or p.color0,
    surface       = p.color0,
    overlay       = p.color8,
    muted         = p.color8,
    subtle        = p.color7,
    text          = p.color15 or p.foreground or p.color7,
    love          = p.color1,
    gold          = p.color3,
    rose          = p.color5,
    iris          = p.color4,
    pine          = p.color2,
    foam          = p.color6,
    highlight_low  = p.color0,
    highlight_med  = p.color8,
    highlight_high = p.color8,
  }
end

-- Evergreen — deep forest palette used when no colors.json is present
local evergreen = {
  base          = 0xff0d1a0d,
  surface       = 0xff0d1a0d,
  overlay       = 0xff1e2e1e,
  muted         = 0xff4a6741,
  subtle        = 0xff8aa888,
  text          = 0xffd4e8c2,
  love          = 0xffcf6679,
  gold          = 0xffd4a849,
  rose          = 0xffe8a598,
  iris          = 0xff8fb5a0,
  pine          = 0xff4d9e6d,
  foam          = 0xff6ab0a3,
  highlight_low  = 0xff0d1a0d,
  highlight_med  = 0xff1e2e1e,
  highlight_high = 0xff2a3e2a,
}

-- Load colors — try ~/.cache/wal/colors.json (pywal / hellwal compatible),
-- fall back to the evergreen theme.
local palette = load_colors_json(os.getenv("HOME") .. "/.cache/wal/colors.json")
local theme = palette and palette_to_theme(palette) or evergreen

M.sections = {
  bar = {
    bg = with_alpha(theme.overlay, 0.6),
    border = theme.highlight_low,
  },
  item = {
    bg = theme.overlay,
    border = theme.base,
    text = theme.text,
  },
  apple = theme.text,
  spaces = {
    icon = {
      color = theme.subtle,
      highlight = theme.gold,
    },
    label = {
      color = theme.subtle,
      highlight = theme.gold,
    },
    indicator = theme.love,
  },
  media = {
    label = theme.pine,
  },
  widgets = {
    battery = {
      low = theme.love,
      mid = theme.gold,
      high = theme.pine,
    },
    wifi = { icon = theme.foam },
    volume = {
      icon = theme.foam,
      popup = {
        item = theme.subtle,
        highlight = theme.text,
      },
      slider = {
        highlight = theme.foam,
        bg = theme.highlight_med,
        border = theme.highlight_low,
      },
    },
    messages = { icon = theme.love },
  },
  calendar = {
    label = theme.subtle,
  },
}

return M
