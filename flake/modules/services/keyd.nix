{ pkgs, ... }: {
  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        ids = ["*"];
        settings = {
          main = {
            space = "overloadt(meta, space, 200)";
          };
          control = {
            space = "C-space";
          };
          "spacefn" = {};
        };
      };
    };
  };

  security.sudo.extraRules = [
    {
      users = ["aliyss"];
      commands = [
        {
          command = "${pkgs.systemd}/bin/systemctl start keyd.service";
          options = ["NOPASSWD"];
        }
        {
          command = "${pkgs.systemd}/bin/systemctl stop keyd.service";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];
}
