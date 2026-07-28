--  _   _                  _                 _
-- | | | |_   _ _ __  _ __| | __ _ _ __   __| |
-- | |_| | | | | '_ \| '__| |/ _` | '_ \ / _` |
-- |  _  | |_| | |_) | |  | | (_| | | | | (_| |
-- |_| |_|\__, | .__/|_|  |_|\__,_|_| |_|\__,_|
--        |___/|_|
--
-- Lua config (Hyprland >= 0.55). Preferred over hyprland.conf at startup;
-- hyprland.conf is kept as the rollback fallback until this has proven
-- itself — see LUA-MIGRATION.md. Config edits go here, in conf/*.lua.

require("conf.monitor")
require("conf.autostart")
require("conf.cursor")
require("conf.environments")
require("conf.input")
require("conf.general")
require("conf.decoration")
require("conf.animations")
require("conf.misc")
require("conf.windowrules")
require("conf.binds")
-- layouts.conf held only empty dwindle{}/master{} blocks; nothing to port
