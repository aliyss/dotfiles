{ pkgs, config, lib, ... }:

let
  extensions = {
    "ublock-origin" = {
      name = "ublock-origin";
      permissions = [ "activeTab" ];
    };
    "bitwarden" = {
      name = "bitwarden";
      permissions = [ "activeTab" ];
    };
    "darkreader" = {
      name = "darkreader";
      permissions = [ "activeTab" ];
    };
    "tridactyl" = {
      name = "tridactyl";
      permissions = [ "activeTab" ];
    };
    "mal-sync" = {
      name = "mal-sync";
      permissions = [ "activeTab" ];
    };
  };
in {

  assertions = lib.mapAttrsToList (k: v:
    let
      unaccepted = lib.subtractLists v.permissions
        config.nur.repos.rycee.firefox-addons.${v.name}.meta.mozPermissions;
    in {
      assertion = unaccepted == [ ];
      message = "Extension ${v.name} has unaccepted permissions: ${
          builtins.toJSON unaccepted
        }";
    }) extensions;

}
