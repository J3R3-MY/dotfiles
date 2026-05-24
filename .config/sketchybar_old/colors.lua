local colors = {}

-- Safe function to add alpha to a color
local with_alpha = function(color, alpha)
  if type(color) ~= "number" then
    error("with_alpha: expected a number for 'color', got " .. tostring(color))
  end
  if alpha > 1.0 or alpha < 0.0 then
    return color
  end
  return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
end
colors.with_alpha = with_alpha

-- Base theme (hex colors)
local theme = {
  -- Base16 Default Dark Theme
  dark = 0xff181818,
  dark_grey = 0xff282828,
  grey = 0xff383838,
  light_grey = 0xff585858,
  dark_silver = 0xffb8b8b8,
  silver = 0xffd8d8d8,
  light_silver = 0xffe8e8e8,
  light = 0xfff8f8f8,
  red = 0xffab4642,
  orange = 0xffdc9656,
  yellow = 0xfff7ca88,
  green = 0xffa1b56c,
  cyan = 0xff86c1b9,
  blue = 0xff7cafc2,
  magenta = 0xffba8baf,
  brown = 0xffa16946,

  -- Special colors
  transparent = 0x00000000,
  black = 0xff000000,
  white = 0xffffffff,
  github_blue = 0xff4170ae,
}

-- Copy theme into colors table
for k, v in pairs(theme) do
  colors[k] = v
end

-- Standard SketchyBar color aliases
colors.bg = colors.dark           -- background
colors.fg = colors.light          -- foreground
colors.fg_highlight = colors.yellow -- highlighted text or icons
colors.border = colors.light_silver -- borders
colors.separator = colors.grey      -- separator lines
colors.background = colors.bg       -- alternative alias for bg
colors.text = colors.fg             -- alias for fg
colors.highlight = colors.fg_highlight
colors.accent = colors.cyan         -- general accent color
colors.warning = colors.orange
colors.error = colors.red
colors.success = colors.green

return colors
