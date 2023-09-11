{ pkgs }:
pkgs.runCommand "firefox-patched" { } ''
  cp -r ${pkgs.firefox-unwrapped} $out
  # Add any extra files or modifications here
''
