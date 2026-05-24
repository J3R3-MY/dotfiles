local colors = require("colors").sections.spaces
local icons = require "icons"
local icon_map = require "helpers.icon_map"

local focused_space = nil

sbar.exec("aerospace list-workspaces --all", function(spaces)
  for space_name in spaces:gmatch "[^\r\n]+" do
    local space = sbar.add("item", "space." .. space_name, {
      icon = {
        string = space_name .. " " .. icons.separators.right,
        color = colors.icon.color,
        highlight_color = colors.icon.highlight,
        padding_left = 8,
        padding_right = 4,
      },
      label = {
        font = "sketchybar-app-font:Regular:16.0",
        string = "—",
        color = colors.label.color,
        highlight_color = colors.label.highlight,
        y_offset = -1,
        padding_right = 12,
      },
      click_script = "aerospace workspace " .. space_name,
      padding_left = space_name == "A" and 0 or 4,
    })

    local function update_windows()
      sbar.exec("aerospace list-windows --format %{app-name} --workspace " .. space_name, function(windows)
        local no_app = true
        local icon_line = ""
        for app in windows:gmatch "[^\r\n]+" do
          no_app = false
          local lookup = icon_map[app]
          local icon = ((lookup == nil) and icon_map["default"] or lookup)
          icon_line = icon_line .. " " .. icon
        end
        sbar.animate("tanh", 10, function()
          if no_app then
            if space_name == focused_space then
              -- Show placeholder for empty focused workspace
              space:set {
                icon = { drawing = true },
                label = { drawing = true, string = " —" },
                padding_left = 4,
                padding_right = 4,
              }
            else
              -- Hide empty unfocused workspaces
              space:set {
                icon = { drawing = false },
                label = { drawing = false },
                padding_left = 0,
                padding_right = 0,
              }
            end
          else
            space:set {
              icon = { drawing = true },
              label = { drawing = true, string = icon_line },
              padding_left = 4,
              padding_right = 4,
            }
          end
        end)
      end)
    end

    space:subscribe("aerospace_workspace_change", function(env)
      focused_space = env.FOCUSED_WORKSPACE
      local selected = focused_space == space_name
      space:set {
        icon = { highlight = selected },
        label = { highlight = selected },
      }

      if selected then
        sbar.animate("tanh", 8, function()
          space:set {
            background = {
              shadow = {
                distance = 0,
              },
            },
            y_offset = -4,
            padding_left = 8,
            padding_right = 0,
          }
          space:set {
            background = {
              shadow = {
                distance = 4,
              },
            },
            y_offset = 0,
            padding_left = 4,
            padding_right = 4,
          }
        end)
      end
      update_windows()
    end)

    space:subscribe("aerospace_focus_change", function()
      update_windows()
    end)

    space:subscribe("space_windows_change", function()
      update_windows()
    end)

    space:subscribe("mouse.clicked", function()
      sbar.animate("tanh", 8, function()
        space:set {
          background = {
            shadow = {
              distance = 0,
            },
          },
          y_offset = -4,
          padding_left = 8,
          padding_right = 0,
        }
        space:set {
          background = {
            shadow = {
              distance = 4,
            },
          },
          y_offset = 0,
          padding_left = 4,
          padding_right = 4,
        }
      end)
    end)

    -- Set initial state
    update_windows()
  end

  -- Highlight the initially focused workspace
  sbar.exec("aerospace list-workspaces --focused", function(result)
    focused_space = result:gsub("%s+", "")
  end)
end)
