{
  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        ids = ["*"];
        settings = {
          main = {
            # Tap = space, Hold = activate "space" layer
            space = "overloadt(meta, space, 200)";
          };

          control = {
            space = "C-space";
          };

          # Define the layer that Space activates
          "spacefn" = {
            # w = "layer(shift)"; # example: pressing Space+W activates another layer or key
            # Or if you just want Space+W to send a symbol:
            # w = "leftmeta-w"; # acts as Meta+W
          };
        };
      };
    };
  };
}
