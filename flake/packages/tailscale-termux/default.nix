{
  pkgs,
  lib,
}:
# Patched Tailscale for Termux (Android 11+), built from source.
#
# Upstream bropines/tailscale-termux-cli ships this as a Termux .deb; we rebuild
# the same patched binaries from the flake's nixpkgs tailscale source so the
# phone's tailscale is fully Nix-managed (home.packages -> ~/.local/bin wrapper
# -> kernel chroot, same as every other nix tool on the phone).
#
# The two patch files are vendored from bropines/tailscale-termux-cli at rev
# 0a98906f457d2ba887f17881c26e7f737322ee17 (see ./patches/):
#   - fix_args_android.go  (android || linux): default the CLI's --socket to
#     ~/.tailscale/tailscaled.sock; work around Termux's duplicate-argv quirk.
#   - fix_android_netmon.go (android only): replace Android's restricted
#     netlink interface monitoring with ioctl (/proc/net/if_inet6) + ifconfig +
#     UDP-probe discovery, and pin Go's resolver to 8.8.8.8. This is why the
#     daemon must be built with GOOS=android — that's what activates the
#     `android` build tag.
#
# The binaries are static (CGO_ENABLED=0) aarch64 ELF and run inside the
# phone's kernel chroot. The daemon runs in userspace-networking mode (no
# /dev/net/tun, no root) and serves the SOCKS5 proxy that the phone's ssh
# aliases route through (see flake/home-manager/apps/tailscale.nix).
#
# Build notes:
#   - Go modules are fetched at build time (the phone's Nix runs with
#     `sandbox = false` and a resolv.conf inside the chroot). The netmon patch
#     needs github.com/wlynxg/anet, which is not in tailscale's go.mod —
#     `go get` adds it (upstream's build.sh also runs `go mod tidy`, but that
#     drags in the whole tool graph for no benefit).
#   - ts_omit_ssh is required: tailscale's built-in SSH (feature/ssh) does not
#     compile on GOOS=android, so `tailscale ssh` is unavailable on the phone
#     (same as the upstream .deb — no regression).

pkgs.stdenv.mkDerivation {
  pname = "tailscale-termux";
  version = pkgs.tailscale.version;

  src = pkgs.tailscale.src;

  nativeBuildInputs = [ pkgs.go pkgs.cacert ];

  preConfigure = ''
    # The phone's chroot fake /etc has no CA bundle, and builds are
    # unsandboxed (network + module downloads), so point Go at nixpkgs' cacert
    # explicitly.
    export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
    export NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
    cp ${./patches/fix_args_android.go} cmd/tailscaled/fix_args_android.go
    cp ${./patches/fix_args_android.go} cmd/tailscale/fix_args_android.go
    cp ${./patches/fix_android_netmon.go} cmd/tailscaled/fix_android_netmon.go
    # Enable the localapi cert endpoint on Android (upstream build.sh).
    sed -i 's/!android && //g' ipn/localapi/cert.go
    sed -i 's/ || android//g' ipn/localapi/disabled_stubs.go
    export GOTOOLCHAIN=local
    export GOFLAGS=-mod=mod
    # Go's caches default to $HOME — which is /homeless-shelter in Nix builds —
    # leaving thousands of read-only module files there that trip the phone's
    # post-build-hook (clear-homeless-shelter.sh). Keep everything in the
    # build dir instead.
    export GOPATH="$NIX_BUILD_TOP/gopath"
    export GOMODCACHE="$NIX_BUILD_TOP/gopath/pkg/mod"
    export GOCACHE="$NIX_BUILD_TOP/gopath/.cache"
    # anet is needed by the netmon patch. `go get` adds it to go.mod/go.sum;
    # deliberately NO `go mod tidy` (it would pull the whole tool graph).
    go get github.com/wlynxg/anet@v0.0.5
  '';

  buildPhase = ''
    runHook preBuild
    export GOOS=android
    export GOARCH=arm64
    export CGO_ENABLED=0
    export GOTOOLCHAIN=local
    export GOFLAGS=-mod=mod
    tags="ts_no_clipboard,ts_omit_taildrop,ts_omit_systray,ts_omit_kube,ts_omit_aws,ts_omit_bird,ts_omit_desktop_sessions,ts_omit_networkmanager,ts_omit_sdnotify,ts_omit_ssh"
    go build -trimpath -tags "$tags" -ldflags "-s -w -checklinkname=0" -buildmode=pie -o tailscale ./cmd/tailscale
    go build -trimpath -tags "$tags" -ldflags "-s -w -checklinkname=0" -buildmode=pie -o tailscaled ./cmd/tailscaled
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp tailscale tailscaled $out/bin/
    runHook postInstall
  '';
}
