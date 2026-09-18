{
  lib,
  runCommand,
  fetchurl,
}:
let
  # Weights for the on-machine intent router (~/Projects/intent-router).
  #
  # minishlab/potion-base-8M: Model2Vec static embeddings distilled from
  # bge-base-en-v1.5 — 7.5M parameters, 256 dimensions, 30 MB of f32 weights.
  # Not a transformer: one table lookup per token plus a mean pool, so a phrase
  # costs well under a millisecond on CPU and there is no ONNX runtime, no
  # model server and no GPU in the picture.
  #
  # Fetched here (rather than downloaded on first use) because the router is a
  # systemd user service: if the weights were missing at start-up, the only
  # symptom would be a service that quietly never answers. These same pins live
  # in the project as nix/model.nix — a pure flake cannot read ~/Projects, so
  # the two copies have to agree by hand.
  base = "https://huggingface.co/minishlab/potion-base-8M/resolve/main";

  fetch = name: hash:
    fetchurl {
      url = "${base}/${name}";
      inherit hash;
      name = "potion-base-8M-${name}";
    };

  config = fetch "config.json" "sha256-KmrA6aqjVqaKVogHDbePw6Rk/v6F0vBqGQXONxhodVM=";
  tokenizer = fetch "tokenizer.json" "sha256-5n6AP2JPtNZ96hxzDQbhBn4bFNgw4sIgJWnj7w9wu1A=";
  weights = fetch "model.safetensors" "sha256-9l0PMl+q3B4SHDGeL6pBFw0/oH2MiavUjKU1jZoiPeI=";
in
runCommand "potion-base-8M" {
  meta = with lib; {
    description = "Model2Vec static embedding model (potion-base-8M) for the local intent router";
    homepage = "https://huggingface.co/minishlab/potion-base-8M";
    license = licenses.mit;
    platforms = platforms.all;
  };
} ''
  mkdir -p $out
  ln -s ${config} $out/config.json
  ln -s ${tokenizer} $out/tokenizer.json
  ln -s ${weights} $out/model.safetensors
  # The loader reads exactly these three files; nothing else from the repo.
  echo "potion-base-8M (256-dim static embeddings, Model2Vec)" > $out/README
''
