-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/ for more

-- left screen has workspaces 1-5
-- right screen has workspaces 6-10
-- no screen has workspaces 11-15
local leftMonitor = 0

-- Chat apps - workspace 5
hl.window_rule({ name = "discord-ws5", match = { class = "^(discord)$" }, workspace = 5 })
hl.window_rule({ name = "slack-ws5",   match = { class = "^(Slack)$" },   workspace = 5 })

-- Spotify / Bluebubbles - workspace 4
hl.window_rule({ name = "spotify-ws4",     match = { class = "^(Spotify)$" },     workspace = 4 })
hl.window_rule({ name = "bluebubbles-ws4", match = { class = "^(bluebubbles)$" }, workspace = 4 })

-- Link UI
hl.window_rule({ name = "link-ui-monitor", match = { class = "^(link-ui)$" }, monitor = leftMonitor })

-- Unreal Editor - suppress initial focus
hl.window_rule({
    name  = "unreal-no-initial-focus",
    match = { class = "^(UnrealEditor)$", title = [[^\w*$]] },
    no_initial_focus = true,
})

-- Keep modal/tool dialogs usable
local unrealDialogTitle = [[^(Open|Save|Import|Export|Project Settings|Editor Preferences|Pick Parent Class|Message|Warning|Error).*]]
hl.window_rule({
    name  = "unreal-dialogs-float-center",
    match = { class = "^(UnrealEditor)$", title = unrealDialogTitle },
    float  = true,
    center = true,
})
