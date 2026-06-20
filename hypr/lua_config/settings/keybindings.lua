-- KEYBINDINGS

local mainMod = "SUPER"

hl.config({
    binds = {
        allow_workspace_cycles = true,
    },
})

-- System Management
require("settings.keybindings.system-management")

-- Sound Control
require("settings.keybindings.sound-control")

-- Window Management
require("settings.keybindings.window-management")

-- Application Management
require("settings.keybindings.application-launch")

-- Screenshot
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy"))

-- Application Action Keybindings
hl.bind(mainMod .. " + f", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + q", hl.dsp.window.kill())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

-- Workspace Focus Cycle
hl.bind(mainMod .. " + Tab",       hl.dsp.focus({ workspace = "cyclenext" }))
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.focus({ workspace = "cycleprev" }))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.window.float({ action = "toggle" }))

-- Application -> Workspace Movement
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Application Focus
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Application Swap
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.swap({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.swap({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.swap({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.swap({ direction = "down" }))

-- Application Resize
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.resize({ width = 30,  height = 0 }),  { repeating = true })
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.resize({ width = -30, height = 0 }),  { repeating = true })
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.resize({ width = 0,   height = 30 }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.resize({ width = 0,   height = -30 }), { repeating = true })

-- Application Focus Cycle
hl.bind("ALT + Tab",          hl.dsp.focus({ workspace = "cyclenext" }))
hl.bind("ALT + SHIFT + Tab",  hl.dsp.focus({ workspace = "cycleprev" }))

-- Workspace Focus
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
end

-- Workspace Focus Cycle
hl.bind(mainMod .. " + Tab",          hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + SHIFT + Tab",  hl.dsp.focus({ workspace = "e-1" }))

-- MOUSEBINDINGS
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
