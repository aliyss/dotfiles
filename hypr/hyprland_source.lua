local mainMod = "SUPER"

hl.monitor({
    output   = "DP-2",
    mode     = "5120x1440",
    position = "0x0",
    scale    = 1,
})

hl.monitor({
    output   = "DP-1",
    mode     = "5120x1440",
    position = "0x0",
    scale    = 1,
})

hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1080",
    position = "0x0",
    scale    = 1,
})

hl.monitor({
    output   = "Unknown-1",
    disabled = true,
})

hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("GBM_BACKEND", "nvidia_drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("__GL_GSYNC_ALLOWED", "1")
hl.env("WLR_NO_HARDWARE_CURSORS", "1")
hl.env("WLR_DRM_NO_ATOMIC", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("HYPRCURSOR_THEME", "Simp1e-Dark")
hl.env("XCURSOR_SIZE", "24")

hl.config({
    general = {
        gaps_in     = 5,
        gaps_out    = 10,
        border_size = 1,
        col         = {
            active_border   = { colors = { "rgba(008000ee)", "rgba(ffff99ee)" }, angle = 45 },
            inactive_border = { colors = { "rgba(00ff99aa)", "rgba(008000aa)" }, angle = 45 },
        },
        layout      = "dwindle",
    },

    decoration = {
        rounding         = 0,
        inactive_opacity = 0.8,
        dim_inactive     = false,
        dim_strength     = 0.4,
        blur             = {
            size              = 10,
            passes            = 2,
            brightness        = 0.8,
            new_optimizations = true,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    binds = {
        allow_workspace_cycles = true,
    },
})

hl.config({
    input = {
        kb_layout = "ga,de",
    },
})

hl.config({
    cursor = {
        inactive_timeout = 3,
    },
})

hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 7, bezier = "myBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default" })

hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})

hl.window_rule({
    match = { class = "^(firefox)$" },
    no_blur = true,
})

hl.window_rule({
    match = { initial_title = "^(Spotify Free)$" },
    opacity = "0.90 0.90",
})

hl.window_rule({
    match = { initial_title = "^(Spotify Free)$" },
    workspace = 2,
})

hl.window_rule({
    match = { initial_title = "^(com.github.th_ch.youtube_music)$" },
    workspace = 2,
})

hl.window_rule({
    match = { class = "^(Slack)$" },
    workspace = 2,
})

hl.window_rule({
    match = { class = "^(emacs)$" },
    workspace = 1,
})

hl.window_rule({
    match = { class = "^(firefox)$" },
    workspace = 1,
})

hl.window_rule({
    match = { title = "^(foot_install)$" },
    float = true,
})

hl.window_rule({
    match = { title = "^(foot_install)$" },
    size = { 1200, 800 },
})

hl.window_rule({
    match = { title = "^(foot_install)$" },
    center = true,
})

hl.window_rule({
    match = { title = "^(clipse_clipboard)$" },
    float = true,
})

hl.window_rule({
    match = { title = "^(clipse_clipboard)$" },
    size = { 622, 652 },
})

hl.window_rule({
    match = { class = "^(affinity%.exe)$" },
    tile = true,
})

hl.on("hyprland.start", function()
    hl.exec_cmd("hyprlock --immediate-render")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd(
        "sh ~/.config/hypr/wallpapers/wrapped_awww.sh ~/.config/images/wallpapers/light/ ~/.config/images/wallpapers/dark/")
    hl.exec_cmd("clipse -listen")
    hl.exec_cmd("systemctl --user start activitywatch-watcher-aw-watcher-window-wayland.service")
    hl.exec_cmd("systemctl --user start activitywatch-watcher-aw-watcher-afk.service")
end)

require("settings.keybindings")
