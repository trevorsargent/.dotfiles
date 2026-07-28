-- Execute your favorite apps at launch
-- (the old `hyprpm reload -n` is gone: hyprsplit is now a lua library loaded
-- from conf/binds.lua, so nothing here needs hyprpm anymore)
hl.on("hyprland.start", function()
    hl.exec_cmd("mako")
    -- hl.exec_cmd("hypridle")
    hl.exec_cmd("systemctl --user start hyprpolkitagent.service")
    hl.exec_cmd('gsettings set org.gnome.desktop.interface gtk-theme "Fluent-Dark-compact"') -- for GTK3 apps
    hl.exec_cmd('gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"')      -- for GTK4 apps
    hl.exec_cmd("solaar")
    hl.exec_cmd("wl-paste --primary --watch wl-copy --primary --clear") -- disable middle-click paste by keeping primary selection empty
    hl.exec_cmd("eww open dock --screen HDMI-A-1")
end)

-- QT_QPA_PLATFORMTHEME lives in conf/environments.lua (it was set in both files)
