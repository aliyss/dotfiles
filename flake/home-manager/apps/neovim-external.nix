{
  pkgs,
  fetchFromGitHub,
  ...
}: {
  laravel-dev-tools = pkgs.php81.buildComposerProject (finalAttrs: {
    pname = "laravel-dev-tools";
    version = "1.0.0";

    src = fetchFromGitHub {
      owner = "haringsrob";
      repo = "laravel-dev-tools";
      rev = finalAttrs.version;
      hash = "sha256-gYIAP9pTjahNkpNNXx0c8sQm+9Kaq6/IAo/xI5bNy7Y=";
    };

    vendorHash = "sha256-HCbjW4HdyQNWDEHXj9U1t3S3EKcrPV1z/9I1ClFsMsc=";
  });
}
