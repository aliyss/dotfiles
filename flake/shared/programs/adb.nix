{...}: {
  programs.adb = {
    enable = true;
  };
  users.users.aliyss.extraGroups = ["adbusers"];
}
