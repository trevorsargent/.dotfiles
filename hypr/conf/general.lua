-- See https://wiki.hypr.land/Configuring/Basics/Variables/ for more
hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 0,
        border_size = 1,
        col = {
            active_border = { colors = { "rgba(ffffff55)", "rgba(ffffff33)" }, angle = 45 },
            inactive_border = "rgba(ffffff00)",
        },
        layout = "master",
        resize_on_border = true,
    },

    debug = {
        disable_logs = false,
    },
})
