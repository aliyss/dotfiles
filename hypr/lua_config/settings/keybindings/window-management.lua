local mainMod = "SUPER"

hl.bind(mainMod .. " + W", hl.dsp.submap("window_management"))

hl.bind("", "c",       hl.dsp.window.kill())
hl.bind("", "c",       hl.dsp.submap("reset"))
hl.bind(mainMod .. " + c", hl.dsp.window.kill(),   { repeating = true })
hl.bind(mainMod .. " + c", hl.dsp.submap("reset"))

hl.bind("", "h",       hl.dsp.focus({ direction = "left" }))
hl.bind("", "h",       hl.dsp.submap("reset"))
hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "left" }), { repeating = true })

hl.bind("", "j",       hl.dsp.focus({ direction = "up" }))
hl.bind("", "j",       hl.dsp.submap("reset"))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "up" }),   { repeating = true })

hl.bind("", "k",       hl.dsp.focus({ direction = "down" }))
hl.bind("", "k",       hl.dsp.submap("reset"))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "down" }), { repeating = true })

hl.bind("", "l",       hl.dsp.focus({ direction = "right" }))
hl.bind("", "l",       hl.dsp.submap("reset"))
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "right" }), { repeating = true })

hl.bind("", "escape",  hl.dsp.submap("reset"))
hl.bind("", "catchall", hl.dsp.submap("reset"))
