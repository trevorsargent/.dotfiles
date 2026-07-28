-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/ for more
hl.config({
    animations = {
        enabled = true,
    },
})

hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })

hl.animation({ leaf = "windows",    enabled = true, speed = 5,  bezier = "default" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 5,  bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border",     enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "fade",       enabled = true, speed = 5,  bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3,  bezier = "default" })
-- the old `borderangle` leaf has no 0.55 lua equivalent; dropped
