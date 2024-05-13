{...}: {
  services.redis = {
    servers = {
      aliyss-assistant = {
        enable = true;
      };
    };
  };
}
