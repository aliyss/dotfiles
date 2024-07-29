{...}: {
  services.redis = {
    servers = {
      aliyss-assistant = {
        enable = true;
        port = 6379;
        settings = {
          loadmodule = [
            "/etc/systemd/redis/librejson.so"
            "/etc/systemd/redis/timeserietimeseriess.so"
          ];
        };
      };
    };
  };
}
