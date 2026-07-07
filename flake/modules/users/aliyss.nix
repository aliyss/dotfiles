{ ... }: {
  users.users.aliyss = {
    isNormalUser = true;
    description = "aliyss";
    extraGroups = ["networkmanager" "wheel" "docker" "uinput" "video"];
  };
}
