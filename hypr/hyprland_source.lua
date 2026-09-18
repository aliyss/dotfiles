local mainMod = "SUPER"


hl.monitor({
    output   = "DP-2",
    mode     = "5120x1440",
    position = "0x0",
    scale    = 1,
})
--
-- hl.monitor({
--     output   = "DP-1",
--     mode     = "5120x1440",
--     position = "0x0",
--     scale    = 1,
-- })

hl.monitor({
    output   = "desc:BNQ BenQ BL2405 JAJ02877SL0",
    mode     = "1920x1080@60",
    position = "3840x0",
    scale    = 1,
})
hl.workspace_rule({
    workspace = "3",
    monitor = "desc:BNQ BenQ BL2405 JAJ02877SL0",
})

hl.monitor({
    output   = "desc:BNQ BenQ BL2405 G1K00731SL0",
    mode     = "1920x1080@60",
    position = "1920x0",
    scale    = 1,
})

hl.monitor({
    output   = "eDP-1",
    mode     = "3840x2400",
    position = "0x0",
    scale    = 2,
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
hl.env("WEBKIT_DISABLE_DMABUF_RENDERER", "1")
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
        movefocus_cycles_fullscreen = true
    },
})

hl.config({
    input = {
        kb_layout = "ga,de",
        follow_mouse = 0,
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
    size = { 1200, 800 },
    center = true,
})

hl.window_rule({
    match = { title = "^(RDP Launcher)$" },
    size = { 1000, 600 },
    center = true,
    float = true,
})

hl.window_rule({
    match = { title = "^(VPN Launcher)$" },
    float = true,
    size = { 1000, 600 },
    center = true,
})

hl.window_rule({
    match = { title = "^(VPN Kill)$" },
    float = true,
    size = { 600, 200 },
    center = true,
})

hl.window_rule({
    match = { title = "^(clipse_clipboard)$" },
    float = true,
    size = { 622, 652 },
})

hl.window_rule({
    match = { class = "^(affinity%.exe)$" },
    tile = true,
})

-- Affinity "Sub" toolbar - pin to current pos 87,189 (size not fixed). No window.move event in Hypr
-- (see wiki.hypr.land/configuring/core/advanced-configuration/events/ - only window.open/title etc.),
-- so poll via timer and on update_rules (tool toggle triggers rule re-eval).
-- start hidden (special) until pinned to 87,189 - opacity doesn't hide XWayland reliably
-- Sub relative to Affinity (main 11,11 -> Sub 87,189 = offset 76,178) without hiding
local subOffsetX, subOffsetY = 76, 178
hl.window_rule({
    match = { class = "^(affinity%.exe)$", title = "^(Sub)$" },
    float = true,
    move = { 87, 189 },
    workspace = 2,
    no_anim = true,
    no_focus = true,
    no_follow_mouse = true,
    focus_on_activate = false,
    no_initial_focus = true,
})
local subPinTimer = hl.timer(function()
    local sub = hl.get_window("title:Sub")
    local aff = hl.get_window("title:Affinity")
    if not sub or sub.class ~= "affinity.exe" or not aff then return end
    local tx, ty = aff.at.x + subOffsetX, aff.at.y + subOffsetY
    if sub.at.x == 0 and sub.at.y == 0 then
        hl.config({ animations = { enabled = false } })
        hl.dispatch(hl.dsp.window.move({ x = tx, y = ty, window = "title:Sub" }))
        hl.timer(function() hl.config({ animations = { enabled = true } }) end, { timeout = 30, type = "oneshot" })
    elseif sub.at.x ~= tx or sub.at.y ~= ty then
        if sub.workspace.id == aff.workspace.id then
            hl.config({ animations = { enabled = false } })
            hl.dispatch(hl.dsp.window.move({ x = tx, y = ty, window = "title:Sub" }))
            hl.timer(function() hl.config({ animations = { enabled = true } }) end, { timeout = 30, type = "oneshot" })
        end
    end
end, { timeout = 120, type = "repeat" })

-- Alice voice overlay (tauri) — three surfaces, one window each, the same
-- arrangement the egui overlay had. Each surface is its own process because
-- Hyprland matches on the Wayland app_id and GTK reports one app_id per process,
-- so the class is what tells the marble, the chat strip and the pill apart.
--
-- The marble is drawn *into* the window, so a blurred backdrop would read as a
-- frosted card around the glass: `no_blur` + `no_shadow` kill the blur and its
-- shadow, `rounding = 0` stops the surface being clipped to a rounded rect, and
-- `no_dim` / an explicit 1.0 opacity keep `decoration.dim_inactive` and
-- `inactive_opacity` off it. It is `no_focus` too: the marble is decoration, it
-- asks the compositor for an empty input region (see tauri/src-tauri/src/
-- clickthrough.rs), and clicks and keys belong to the window underneath.
hl.window_rule({
    match = { class = "^(alice-tauri-orb)$" },
    float = true,
    move = "0 0",
    size = "monitor_w monitor_h",
    no_focus = true,
    no_dim = true,
    rounding = 0,
    border_size = 0,
    no_blur = true,
    no_shadow = true,
    no_anim = true,
    opacity = "1.0 1.0",
})

-- The chat strip is `no_blur` on purpose: Hyprland blurs a whole window rect,
-- not the shapes a client paints inside it, so with the blur on the entire
-- strip frosts — gaps included — and the panel could never be transparent. The
-- bubbles fake the glass themselves instead (a translucent fill, a soft white
-- halo and one bright line along the top edge), which keeps the desktop visible
-- right up to the edge of each bubble. The chat stops short of the input pill
-- so the two never overlap.
hl.window_rule({
    match = { class = "^(alice-tauri-chat)$" },
    no_blur = true,
    float = true,
    move = "monitor_w-460 0",
    size = "460 monitor_h-104",
    no_dim = true,
    rounding = 0,
    border_size = 0,
    no_shadow = true,
    no_anim = true,
    opacity = "1.0 1.0",
})

-- The input pill has no such rule: its plate *is* the whole window, so a real
-- blur fits it exactly.
hl.window_rule({
    match = { class = "^(alice-tauri-input)$" },
    float = true,
    move = "monitor_w/2-480 monitor_h-104",
    size = "960 96",
    no_dim = true,
    rounding = 26,
    border_size = 0,
    no_shadow = true,
    no_anim = true,
    opacity = "1.0 1.0",
})

hl.on("hyprland.start", function()
    hl.exec_cmd("hyprlock --immediate-render")
    -- No gnome-keyring-daemon here on purpose: greetd's PAM module
    -- (security.pam.services.greetd.enableGnomeKeyring) starts the daemon and
    -- unlocks the login collection at login, so org.freedesktop.secrets already
    -- has a usable owner by the time the session comes up. Hand-starting a
    -- second daemon races that: it can win the bus name while holding no login
    -- password, leaving the keyring locked and NetworkManager failing with
    -- "No valid secrets".
    hl.exec_cmd("forticlient-tray")
    -- Secret agent that pops the openconnect SSO login window (e.g. AnyConnect WebAuth VPN).
    hl.exec_cmd("env GDK_BACKEND=x11 WEBKIT_DISABLE_DMABUF_RENDERER=1 WEBKIT_DISABLE_COMPOSITING_MODE=1 nm-applet")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd(
        "sh ~/.config/hypr/wallpapers/wrapped_awww.sh ~/.config/images/wallpapers/light/ ~/.config/images/wallpapers/dark/")
    hl.exec_cmd("systemctl --user start activitywatch-watcher-aw-watcher-window-wayland.service")
    hl.exec_cmd("systemctl --user start activitywatch-watcher-aw-watcher-afk.service")
end)

require("settings.keybindings")
