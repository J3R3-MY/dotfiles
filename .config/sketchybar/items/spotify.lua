local icons = require "icons"
local colors = require("colors").sections.media

local spotify = sbar.add("item", {
  position = "right",
  -- drawing = false,
  icon = {
    max_chars = 40,
    padding_left = 8,
    string = "—",
    color = colors.label
  },
  label = {
    string = icons.separators.left .. " " .. icons.music,
    padding_right = 8,
    color = colors.label,
  },
  popup = {
    horizontal = true,
    align = "center",
    y_offset = 2,
  },
  padding_right = 8,
})

sbar.add("item", {
  position = "popup." .. spotify.name,
  padding_left = 6,
  padding_right = 6,
  icon = { string = icons.media.back },
  label = { drawing = false },
  background = { drawing = false },
})
sbar.add("item", {
  position = "popup." .. spotify.name,
  padding_left = 6,
  padding_right = 6,
  icon = { string = icons.media.play_pause },
  label = { drawing = false },
  background = { drawing = false },
})
sbar.add("item", {
  position = "popup." .. spotify.name,
  padding_left = 6,
  padding_right = 6,
  icon = { string = icons.media.forward },
  label = { drawing = false },
  background = { drawing = false },
})

sbar.add("event", "playback_state_changed", "com.spotify.client.PlaybackStateChanged")

spotify:subscribe("playback_state_changed", function(env)
  local playing = (env.INFO["Player State"] == "Playing")
  -- local playing = true
  spotify:set { icon = env.INFO.Artist .. " - " .. env.INFO.Name }
end)
