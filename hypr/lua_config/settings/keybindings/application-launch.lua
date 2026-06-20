local mainMod = "SUPER"

hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("wlr-which-key -k e"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("foot --title clipse_clipboard -e clipse"))
