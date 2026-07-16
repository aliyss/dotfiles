local mainMod = "SUPER"

-- System Management
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("wlr-which-key -k p"))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("wlr-which-key -k s"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("wlr-which-key -k l"))

-- Sound Volume
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { repeating = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true })

-- Media Keys
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous"))
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause"))
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause"))
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next"))

-- Screenshot
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy'))

-- Application Launch
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("wlr-which-key -k e"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("foot --title clipse_clipboard -e clipse"))

-- Window Actions
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.window.float({ action = "toggle" }))

-- Move focus
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Swap windows
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.swap({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.swap({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.swap({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.swap({ direction = "d" }))

-- Resize active window
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.resize({ x = 30,  y = 0,   relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.resize({ x = -30, y = 0,   relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.resize({ x = 0,   y = 30,  relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.resize({ x = 0,   y = -30, relative = true }), { repeating = true })

-- Window focus cycle
hl.bind("ALT + Tab",       hl.dsp.window.cycle_next())
hl.bind("ALT + SHIFT + Tab", hl.dsp.window.cycle_next({ next = false }))

-- Workspace switch
hl.bind(mainMod .. " + 1", hl.dsp.focus({ workspace = 1 }))
hl.bind(mainMod .. " + 2", hl.dsp.focus({ workspace = 2 }))
hl.bind(mainMod .. " + 3", hl.dsp.focus({ workspace = 3 }))
hl.bind(mainMod .. " + 4", hl.dsp.focus({ workspace = 4 }))
hl.bind(mainMod .. " + 5", hl.dsp.focus({ workspace = 5 }))
hl.bind(mainMod .. " + 6", hl.dsp.focus({ workspace = 6 }))
hl.bind(mainMod .. " + 7", hl.dsp.focus({ workspace = 7 }))
hl.bind(mainMod .. " + 8", hl.dsp.focus({ workspace = 8 }))
hl.bind(mainMod .. " + 9", hl.dsp.focus({ workspace = 9 }))
hl.bind(mainMod .. " + 0", hl.dsp.focus({ workspace = 10 }))

-- Move window to workspace
hl.bind(mainMod .. " + SHIFT + 1", hl.dsp.window.move({ workspace = 1 }))
hl.bind(mainMod .. " + SHIFT + 2", hl.dsp.window.move({ workspace = 2 }))
hl.bind(mainMod .. " + SHIFT + 3", hl.dsp.window.move({ workspace = 3 }))
hl.bind(mainMod .. " + SHIFT + 4", hl.dsp.window.move({ workspace = 4 }))
hl.bind(mainMod .. " + SHIFT + 5", hl.dsp.window.move({ workspace = 5 }))
hl.bind(mainMod .. " + SHIFT + 6", hl.dsp.window.move({ workspace = 6 }))
hl.bind(mainMod .. " + SHIFT + 7", hl.dsp.window.move({ workspace = 7 }))
hl.bind(mainMod .. " + SHIFT + 8", hl.dsp.window.move({ workspace = 8 }))
hl.bind(mainMod .. " + SHIFT + 9", hl.dsp.window.move({ workspace = 9 }))
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

-- Workspace cycle with e+1/e-1
hl.bind(mainMod .. " + Tab",          hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + SHIFT + Tab",  hl.dsp.focus({ workspace = "e-1" }))

-- Mouse bindings
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272",  hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273",  hl.dsp.window.resize(), { mouse = true })

-- Window management submap
hl.bind(mainMod .. " + W", hl.dsp.submap("window_management"))

hl.define_submap("window_management", function()
    hl.bind("c", function()
        hl.dispatch(hl.dsp.window.close())
        hl.dispatch(hl.dsp.submap("reset"))
    end)
    hl.bind(mainMod .. " + c", function()
        hl.dispatch(hl.dsp.window.close())
        hl.dispatch(hl.dsp.submap("reset"))
    end)
    hl.bind("escape",  hl.dsp.submap("reset"))

    hl.bind("h", function()
        hl.dispatch(hl.dsp.focus({ direction = "left" }))
        hl.dispatch(hl.dsp.submap("reset"))
    end)
    hl.bind("j", function()
        hl.dispatch(hl.dsp.focus({ direction = "up" }))
        hl.dispatch(hl.dsp.submap("reset"))
    end)
    hl.bind("k", function()
        hl.dispatch(hl.dsp.focus({ direction = "down" }))
        hl.dispatch(hl.dsp.submap("reset"))
    end)
    hl.bind("l", function()
        hl.dispatch(hl.dsp.focus({ direction = "right" }))
        hl.dispatch(hl.dsp.submap("reset"))
    end)

    hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "left" }),  { repeating = true })
    hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "up" }),    { repeating = true })
    hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "down" }),  { repeating = true })
    hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "right" }), { repeating = true })

    hl.bind("catchall", hl.dsp.submap("reset"))
end)
