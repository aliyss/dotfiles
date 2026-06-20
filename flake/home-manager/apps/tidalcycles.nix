{pkgs, ...}: {
  programs.tidalcycles = {
    enable = true;
    supercollider.enable = true;
    superdirt.enable = true;
    helpers.wrapSclang = false;
    package = pkgs.haskellPackages.ghcWithPackages (h: [h.tidal]);
    development.enableGhc = false;
    boot = {
      verbose = false;
      profile = "standard";
      connection = {
        address = "127.0.0.1";
        port = 57120;
      };
      extraFunctions = ''
        import Sound.Tidal.Context
        -- Standard setup
        tidal <- startTidal (superdirtTarget {oAddress = "127.0.0.1", oPort = 57120}) (defaultConfig {cVerbose = True})
        let p = streamReplace tidal
            d1 = p 1
            d2 = p 2
            d3 = p 3
            -- Define the custom operator $:
            -- This makes ($:) an alias for (d1 $)
            ($:) = d1

        -- Optional: If you want $: to be more flexible,
        -- you usually just stick to the standard $ or define shortcuts for d1, d2, etc.
      '';
    };
    # editor = {
    #   vim.enable = true;
    # };
  };
}
