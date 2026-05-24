local icons = require "icons"
local colors = require("colors").sections.widgets.wifi

local popup_width = 250
local wifi_iface = "en0"   -- BSD device name, used for ipconfig
local wifi_svc   = "Wi-Fi" -- networksetup service name, used for SSID lookup

local wifi = sbar.add("item", "widgets.wifi", {
  position = "right",
  icon = {
    color = colors.icon,
  },
  label = {
    drawing = false,
    padding_right = 6,
  },
  background = { drawing = false },
  popup = {
    align = "center",
    height = 30,
    y_offset = 2,
  },
  padding_left = 4,
  padding_right = 4,
})

local ip = sbar.add("item", {
  position = "popup." .. wifi.name,
  icon = {
    align = "left",
    string = "IP:",
    width = popup_width / 2,
  },
  label = {
    string = "???.???.???.???",
    width = popup_width / 2,
    align = "right",
  },
  background = { drawing = false },
})

local mask = sbar.add("item", {
  position = "popup." .. wifi.name,
  icon = {
    align = "left",
    string = "Subnet mask:",
    width = popup_width / 2,
  },
  label = {
    string = "???.???.???.???",
    width = popup_width / 2,
    align = "right",
  },
  background = { drawing = false },
})

local router = sbar.add("item", {
  position = "popup." .. wifi.name,
  icon = {
    align = "left",
    string = "Router:",
    width = popup_width / 2,
  },
  label = {
    string = "???.???.???.???",
    width = popup_width / 2,
    align = "right",
  },
  background = { drawing = false },
})

local function update_wifi()
  local cmd = [[for i in $(ifconfig -lX "en[0-9]"); do ipconfig getsummary "$i" | awk '/ SSID/{print $NF}'; done 2>/dev/null]]
  sbar.exec(cmd, function(result)
    local ssid = result:match("^%s*(.-)%s*$") or ""
    local connected = ssid ~= "" and ssid ~= "<redacted>"

    if connected then
      sbar.exec([[scutil --nwi | grep -c utun]], function(vpn)
        local vpn_on = tonumber(vpn) and tonumber(vpn) > 0
        wifi:set {
          icon = {
            string = vpn_on and icons.wifi.vpn or icons.wifi.connected,
            color = colors.icon,
          },
          label = { drawing = true, string = ssid },
        }
      end)
    else
      wifi:set {
        icon = { string = icons.wifi.disconnected, color = colors.icon },
        label = { drawing = true, string = "No WiFi" },
      }
    end
  end)
end

wifi:subscribe({ "wifi_change", "system_woke" }, update_wifi)

-- Detect both the BSD device name (for ipconfig) and the service name
-- (for networksetup -getairportnetwork) from listallhardwareports.
-- Output looks like:
--   Hardware Port: Wi-Fi
--   Device: en1
sbar.exec([[networksetup -listallhardwareports | awk '
  /Wi-Fi|AirPort/ { svc=$3 }
  svc && /Device:/ { print svc; print $2; exit }
']], function(result)
  local lines = {}
  for line in result:gmatch("[^\n]+") do lines[#lines + 1] = line end
  if lines[1] and lines[1] ~= "" then wifi_svc  = lines[1] end
  if lines[2] and lines[2] ~= "" then wifi_iface = lines[2] end
  update_wifi()
end)

local function hide_details()
  wifi:set { popup = { drawing = false } }
end

local function toggle_details()
  local should_draw = wifi:query().popup.drawing == "off"
  if should_draw then
    wifi:set { popup = { drawing = true } }
    sbar.exec("ipconfig getifaddr " .. wifi_iface, function(result)
      ip:set { label = result }
    end)
    sbar.exec("networksetup -getinfo Wi-Fi | awk -F 'Subnet mask: ' '/^Subnet mask: / {print $2}'", function(result)
      mask:set { label = result }
    end)
    sbar.exec("networksetup -getinfo Wi-Fi | awk -F 'Router: ' '/^Router: / {print $2}'", function(result)
      router:set { label = result }
    end)
  else
    hide_details()
  end
end

wifi:subscribe("mouse.clicked", function()
  toggle_details()
end)

local function copy_label_to_clipboard(env)
  local label = sbar.query(env.NAME).label.value
  sbar.exec('echo "' .. label .. '" | pbcopy')
  sbar.set(env.NAME, { label = { string = icons.clipboard, align = "center" } })
  sbar.delay(1, function()
    sbar.set(env.NAME, { label = { string = label, align = "right" } })
  end)
end

ip:subscribe("mouse.clicked", copy_label_to_clipboard)
mask:subscribe("mouse.clicked", copy_label_to_clipboard)
router:subscribe("mouse.clicked", copy_label_to_clipboard)
