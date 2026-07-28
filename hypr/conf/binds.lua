-- See https://wiki.hypr.land/Configuring/Basics/Binds/ for more
-- wev for finding keycodes

-- hyprsplit is now a lua library (the C++ hyprpm plugin is deprecated):
-- https://github.com/shezdy/hyprsplit cloned to ~/.config/hypr/hyprsplit
local hs = require("hyprsplit")

local mainMod = "SUPER"
local thumb = "CTRL"

-- PS4 controller / Stream Deck keycodes
local crop = "code:107"
local circle = "code:191"
local triangle = "code:192"
-- square = "code:193" (unused)

local knobR = "code:199"
local knobL = "code:198"
local knobPress = "code:200"

local headphones = "alsa_output.usb-SteelSeries_Arctis_7X_-00.analog-stereo"
local speakers = "alsa_output.pci-0000_10_00.6.analog-stereo"

-- Actions
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("alacritty")) -- Open Alacritty
hl.bind(thumb .. " + Q", hl.dsp.window.close()) -- Close current window
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("nautilus")) -- Opens the filemanager
hl.bind(mainMod .. " + T", hl.dsp.window.float({ action = "toggle" })) -- Toggle between tiling and floating window
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen()) -- Open the window in fullscreen
hl.bind(mainMod .. " + " .. thumb .. " + RETURN", hl.dsp.exec_cmd("GTK_THEME=Default wofi --show drun"))

hl.bind(mainMod .. " + R", hl.dsp.window.pin()) -- pin to
hl.bind(mainMod .. " + J", hl.dsp.layout("orientationcycle")) -- cycle master orientation
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("~/.config/hypr/scripts/open-browser.sh")) -- Opens the browser
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("makoctl reload && notify-send hello-world"))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("zed")) -- launch code normally
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("zed ~/.dotfiles"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("hyprpicker -a -n -f hex"))

-- Move focus with mainMod + SHIFT + arrow keys
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.focus({ direction = "down" }))

-- WORKSPACES

hs.config({
    num_workspaces = 9,
    persistent_workspaces = true,
})

-- Switch workspaces with thumb + [1-9], move the active window with
-- thumb + SHIFT + [1-9] — from the number row and the numpad alike
-- (numpad bound by keycode so NumLock state doesn't matter)
local numpad = { 87, 88, 89, 83, 84, 85, 79, 80, 81 } -- keycodes for KP_1 .. KP_9
for i = 1, 9 do
    hl.bind(thumb .. " + " .. i,                      hs.dsp.focus({ workspace = i }))
    hl.bind(thumb .. " + code:" .. numpad[i],         hs.dsp.focus({ workspace = i }))
    hl.bind(thumb .. " + SHIFT + " .. i,              hs.dsp.window.move({ workspace = i }))
    hl.bind(thumb .. " + SHIFT + code:" .. numpad[i], hs.dsp.window.move({ workspace = i }))
end

-- The old config bound SUPER+M twice (movetoroot, then swapwithmaster);
-- in lua that's one bind dispatching both
hl.bind(mainMod .. " + M", function()
    hl.dispatch(hl.dsp.layout("movetoroot"))
    hl.dispatch(hl.dsp.layout("swapwithmaster"))
end)
hl.bind(mainMod .. " + A", hl.dsp.layout("addmaster"))
hl.bind(mainMod .. " + S", hl.dsp.layout("removemaster"))

-- Move/resize windows with mainMod + LMB/RMB and dragging.
-- No bind options needed: window.drag()/window.resize() invoke the internal
-- mouse handlers (old bindm) and end the drag on release themselves. The
-- shipped example's `{ mouse = true }` is not a real option, and the real
-- `drag`/`click` opts would wrongly defer the bind to button release.
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag())   -- Move window
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize()) -- Resize window

-- Overview
hl.bind(thumb .. " + Tab", hl.dsp.exec_cmd("~/.config/hypr/scripts/window-switcher.sh")) -- Window switcher (wofi dmenu)

-- Audio
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd([[pactl -- set-sink-volume -0 +10% && notify-send "System: $(pactl get-sink-volume @DEFAULT_SINK@ | awk -F'/' '{gsub(/ /,"",$2); print $2}')"]]))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd([[pactl -- set-sink-volume -0 -10% && notify-send "System: $(pactl get-sink-volume @DEFAULT_SINK@ | awk -F'/' '{gsub(/ /,"",$2); print $2}')"]]))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pactl -- set-sink-mute -0 toggle"))
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))

hl.bind(knobR, hl.dsp.exec_cmd([[playerctl --player=spotify volume 0.05+ && notify-send "Spotify: $(playerctl --player=spotify volume | awk '{printf "%d%%", $1*100}')"]]))
hl.bind(knobL, hl.dsp.exec_cmd([[playerctl --player=spotify volume 0.05- && notify-send "Spotify: $(playerctl --player=spotify volume | awk '{printf "%d%%", $1*100}')"]]))
hl.bind(knobPress, hl.dsp.exec_cmd("playerctl --player=spotify play-pause"))

-- find sink indices with: pactl list short sinks
hl.bind(circle,   hl.dsp.exec_cmd("pactl -- set-default-sink " .. headphones .. ' && notify-send "Headphones"'))
hl.bind(triangle, hl.dsp.exec_cmd("pactl -- set-default-sink " .. speakers .. ' && notify-send "Speakers"'))

-- screenshots
hl.bind(thumb .. " + ALT + 1", hl.dsp.exec_cmd("hyprshot -m region"))
hl.bind(thumb .. " + ALT + 2", hl.dsp.exec_cmd("hyprshot -m window"))
hl.bind(crop, hl.dsp.exec_cmd("hyprshot -m region"))
hl.bind(thumb .. " + " .. crop, hl.dsp.exec_cmd("hyprshot -m region --raw | satty --filename -"))
