{ config, lib, pkgs, ... }:
{
  # hypridle disabled - commented out to prevent auto lock/sleep
  services.hypridle = {
    enable = false;
    # settings = {
    #   general = {
    #     lock_cmd = "hyprlock --immediate-render";
    #     before_sleep_cmd = "loginctl lock-session";
    #     after_sleep_cmd = "hyprctl dispatch dpms on";
    #   };
    #   listener = [
    #     {
    #       timeout = 300;
    #       on-timeout = "loginctl lock-session";
    #     }
    #     {
    #       timeout = 330;
    #       on-timeout = "hyprctl dispatch dpms off";
    #       on-resume = "hyprctl dispatch dpms on";
    #     }
    #     {
    #       timeout = 600;
    #       on-timeout = "systemctl suspend";
    #     }
    #   ];
    # };
  };
}
