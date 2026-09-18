{
  pkgs,
  lib,
  ...
}: let
  zenProxySrc = pkgs.fetchFromGitHub {
    owner = "12errh";
    repo = "zen-proxy";
    rev = "8dcf4b6c1b275059aef4e46ef65bb75828d211f9";
    hash = "sha256-Ne0+pjo/poznUmoS8n+07nmWTyO2YeCkhXCJXjUZ8ZI=";
  };

  zenProxyBin = pkgs.writeShellScriptBin "zen-proxy" ''
    exec ${pkgs.nodejs}/bin/node ${zenProxySrc}/zen-proxy.mjs "$@"
  '';
in {
  home.packages = [ zenProxyBin ];

  # Local OpenAI-compatible proxy that unlocks Opencode's anonymous free tier
  # for any agent (Aider, Cline, etc.) by injecting User-Agent + x-opencode-session.
  # See https://github.com/12errh/zen-proxy and https://github.com/anomalyco/opencode/issues/42500
  # Free tier is UA-gated: only `User-Agent: opencode/*` + session header gets past
  # `400 MissingSessionID` / `429 FreeUsageLimitError`. zen-proxy does that for you.
  systemd.user.services.zen-proxy = {
    Unit = {
      Description = "Zen Proxy - Opencode free tier for any agent";
      After = ["network-online.target"];
    };
    Service = {
      ExecStart = "${zenProxyBin}/bin/zen-proxy";
      Restart = "on-failure";
      RestartSec = 3;
      # Config via env (also lives in zen-proxy.json, hot-reloaded via dashboard at :8787)
      Environment = [
        "HOST=127.0.0.1"
        "PORT=8787"
        # Upstream is opencode's Zen gateway
        "ZEN_URL=https://opencode.ai/zen/v1"
        # autoUA=true tracks latest opencode releases for User-Agent
        "AUTO_UA=1"
      ];
    };
    Install.WantedBy = ["default.target"];
  };
}
