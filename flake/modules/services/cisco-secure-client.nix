{
  pkgs,
  lib,
  ...
}: let
  # Cisco Secure Client — the AnyConnect successor, and the only client here that
  # can drive SSO-v2 "Login window" (e.g. Microsoft MFA / SAML). The NetworkManager
  # openconnect plugin's dialog dies before it can render that window
  # (nm-openconnect-auth-dialog: "process_stdin: assertion ... failed") and the
  # openconnect CLI is built without any SSO handler ("No SSO handler"), so the
  # vendor client is the way in. It drives SSO itself: acwebhelper dlopens
  # libwebkit2gtk.
  #
  # The deb is deliberately *not* a Nix input:
  #  - Cisco's web-deploy (e.g. vpn.example.com) only serves it to a real browser session
  #    (curl gets `302 -> /+CSCOE+/no_svc.html` regardless of UA/cookies), so fetchurl
  #    can't reach it, and
  #  - this flake is evaluated purely (`nixos-rebuild switch --flake`, no
  #    --impure), so a deb outside the tree can't be referenced either.
  # Instead `cisco-secure-client-install` unpacks the deb into /opt verbatim,
  # the same end state Cisco's own postinst produces; the host libraries are
  # supplied through LD_LIBRARY_PATH by the wrappers and vpnagentd.service,
  # never by rewriting the binaries (patchelf invalidates their signature).
  prefix = "/opt/cisco/secureclient";

  # Host libraries the binaries expect at Debian paths. Cisco's own libraries
  # (boost, openssl, curl, libvpncommon, libvpnapi, ...) live in $prefix/lib and
  # are reached through the vendor RPATH they already carry, so not listed.
  # lib.getLib so the library output is picked even where a package splits
  # libs out of its default output (systemd, glib, ...).
  libDir = p: "${lib.getLib p}/lib";
  # NB: parens are load-bearing — `[ libDir pkgs.x ]` is two list elements
  # (function + argument), not an application.
  # The GTK stack has to be complete, not just gtk3: the loader resolves each
  # binary's *direct* NEEDED entries before any RPATH of an already-loaded
  # library applies, so every direct dependency of vpnui / acwebhelper /
  # vpndownloader needs its own entry here (they link libpangocairo, libcairo,
  # libgdk_pixbuf and libatk directly).
  hostLibs = [
    (libDir pkgs.stdenv.cc.cc) # libstdc++.so.6 — the one thing ldd misses
    (libDir pkgs.glib)
    (libDir pkgs.gtk3)
    (libDir pkgs.pango)
    (libDir pkgs.cairo)
    (libDir pkgs.gdk-pixbuf)
    (libDir pkgs.at-spi2-core) # libatk-1.0.so.0 lives here now (was `atk`)
    (libDir pkgs.webkitgtk_4_1) # dlopen'd by acwebhelper (SSO login window)
    (libDir pkgs.zlib)
    (libDir pkgs.systemd)
    # dlopen'd by libvpncommoncrypt.so (CNSSCertUtils) for the NSS certificate
    # stores that `CertificateStoreLinux: All` selects. Missing them, the store
    # opens with no CAs at all —
    #   OpenStores: CollectiveCertStore.cpp Line: 490 Required NSS library was not found
    # — and the agent then rejects the gateway with
    #   Termination reason code 59: Connection attempt failed due to certificate problems.
    # libplc4/libplds4 are dlopen'd under the same names but live in NSPR.
    (libDir pkgs.nss)
    (libDir pkgs.nspr)
  ];

  # $prefix/lib comes first on purpose: the client bundles its own openssl,
  # curl and boost, and mixing those with the system copies breaks it.
  libPath = lib.concatStringsSep ":" (["${prefix}/lib"] ++ hostLibs);

  # The bundled binaries link Cisco's own OpenSSL (libacciscocrypto.so), built
  # with
  #   OPENSSLDIR: "/tmp/build/workspace/.../openssl"
  # — a path from Cisco's build machine. X509_STORE_set_default_paths() (imported
  # by libaccurl, libacruntime and libacciscossl, so both the profile downloader
  # and the gateway handshake) therefore resolves to a CA file and directory
  # that cannot exist on any real host, and verification fails with
  #   Termination reason code 59: Connection attempt failed due to certificate problems.
  # which the UI reports as "The certificate on the secure gateway is invalid."
  # The gateway is fine (chain validates against the system store) — the client
  # just has no trust anchors. OpenSSL consults SSL_CERT_FILE/SSL_CERT_DIR
  # before its compiled-in defaults, so hand it the system bundle.
  caBundle = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

  # The same CAs, in the layout OpenSSL's CApath lookup needs: one cert per
  # <subject-hash>.<n> file. NixOS gives /etc/ssl/certs only *bundle* files, and
  # a directory of bundles is invisible to that lookup — which is why the
  # client's PEM-file store (libvpncommoncrypt.so hardcodes /etc/ssl/certs/)
  # comes up empty here:
  #   $ openssl s_client -connect vpn.example.com:443 -CApath /etc/ssl/certs
  #   verify error:num=19:self-signed certificate in certificate chain
  # (example: vpn.example.com)
  caDir = pkgs.runCommand "cisco-ca-cert-dir" {} ''
    mkdir -p $out
    # One certificate per file — copied verbatim, so the auxiliary trust rules in
    # the bundle's `TRUSTED CERTIFICATE` blocks survive — plus the
    # `<subject-hash>.<n>` links the lookup resolves against. (`cacert.unbundled`
    # is not usable here: those files carry a label header, so rehash skips each
    # for not containing exactly one certificate.)
    AWK_OUT="$out" ${pkgs.gawk}/bin/awk '
      /^-----BEGIN (TRUSTED )?CERTIFICATE-----$/ { n++; f = sprintf("%s/cert-%04d.pem", ENVIRON["AWK_OUT"], n) }
      f != "" { print > f }
      /^-----END (TRUSTED )?CERTIFICATE-----$/ { close(f); f = "" }
    ' ${caBundle}
    cd $out
    ${pkgs.openssl}/bin/openssl rehash .
  '';

  # Cisco's shipped load_tun.sh calls /sbin/lsmod and /sbin/modprobe (neither
  # exists on NixOS) and only warns when both fail, so do it natively instead.
  ensureTun = pkgs.writeShellScript "cisco-ensure-tun" ''
    if [ ! -c /dev/net/tun ]; then
      ${pkgs.kmod}/bin/modprobe tun || true
      if [ ! -c /dev/net/tun ]; then
        ${pkgs.coreutils}/bin/mkdir -p /dev/net
        ${pkgs.coreutils}/bin/mknod /dev/net/tun c 10 200
        ${pkgs.coreutils}/bin/chmod 600 /dev/net/tun
      fi
    fi
  '';

  installer = pkgs.writeShellScriptBin "cisco-secure-client-install" ''
    export PATH="${lib.makeBinPath (with pkgs; [
      coreutils
      findutils
      binutils
      gnutar
      xz
      systemd
    ])}:$PATH"
    set -eu

    # The verified Cisco Secure Client 5.1.19.1862 build (the download is
    # manual — some gateways only serve it to a browser session).
    KNOWN_SHA="573553fa302d66d0782b03b523f24f88455f92a60433885319c19648ae1bd2a8"

    DEB="''${1:-}"
    if [ -z "$DEB" ] || [ ! -f "$DEB" ]; then
      echo "usage: sudo cisco-secure-client-install <cisco-secure-client-*.deb>" >&2
      exit 1
    fi

    # Resolve before anything else: extraction happens in a temp dir, so a
    # relative path would stop resolving after the cd below.
    DEB="$(realpath "$DEB")"

    # Fail early on an incomplete download. Firefox leaves <name>.deb.part
    # behind and a 0-byte placeholder with the real name, which otherwise
    # surfaces as "ar: file format not recognized".
    if [ ! -s "$DEB" ]; then
      echo "error: $DEB is empty — the download never completed" >&2
      echo "       (check for a .part file next to it, and re-download in the browser)" >&2
      exit 1
    fi
    if [ "$(head -c 8 "$DEB")" != "!<arch>" ]; then
      echo "error: $DEB is not a .deb archive (truncated or partial download?)" >&2
      exit 1
    fi
    ACTUAL_SHA="$(sha256sum "$DEB" | cut -d' ' -f1)"
    if [ "$ACTUAL_SHA" != "$KNOWN_SHA" ]; then
      echo "warning: unexpected build — not the verified 5.1.19.1862 deb" >&2
      echo "  expected $KNOWN_SHA" >&2
      echo "  actual   $ACTUAL_SHA" >&2
    fi

    if [ "$(id -u)" != 0 ]; then
      echo "must run as root: sudo cisco-secure-client-install '$DEB'" >&2
      exit 1
    fi

    PREFIX="${prefix}"
    TMP="$(mktemp -d)"
    trap 'rm -rf "$TMP"' EXIT

    echo "extracting $(basename "$DEB")"
    # A truncated download still starts with the ar magic, so ar is the first
    # thing that actually notices; turn its message into something actionable.
    if ! (cd "$TMP" && ar x "$DEB"); then
      echo "error: could not unpack $DEB — the download is incomplete" >&2
      echo "       (a .part file next to it means the browser never finished it)" >&2
      exit 1
    fi
    tar -xf "$TMP/data.tar.xz" -C "$TMP"
    if [ ! -d "$TMP/opt/cisco/secureclient" ]; then
      echo "error: unexpected deb layout — no opt/cisco/secureclient inside" >&2
      exit 1
    fi

    # Refresh the shipped tree but keep whatever the client wrote for itself
    # (vpn/profile, downloaded modules, its own logs) — the deb only overwrites
    # the files it actually ships.
    mkdir -p "$PREFIX"
    cp -a "$TMP/opt/cisco/." /opt/cisco/
    if [ -d "$TMP/opt/.cisco" ]; then
      cp -a "$TMP/opt/.cisco" /opt/
    fi
    chmod -R u+w "$PREFIX"

    # Deliberately NOT patching RPATHs here. The binaries already carry
    # RPATH=/opt/cisco/secureclient/lib, which covers Cisco's own libraries,
    # and the host libraries come from LD_LIBRARY_PATH (see the wrappers and
    # vpnagentd.service). Rewriting the ELFs with patchelf breaks the client:
    # Cisco appends a code-signature TLV to each binary and vpnagentd verifies
    # its own before doing anything, so a patched file dies with
    #   TLV_ERROR_INVALID_BUFFER ... File (/opt/cisco/secureclient/bin/vpnagentd)
    # and the service loops on start-limit-hit.

    echo "installed to $PREFIX"
    # The daemon reads the tree at startup, so bounce it to pick up the install.
    if command -v systemctl > /dev/null 2>&1; then
      systemctl restart vpnagentd \
        || echo "warning: could not (re)start vpnagentd — check: systemctl status vpnagentd" >&2
    fi
  '';

  # Wrappers rather than raw paths so the host libraries are always resolvable,
  # even for the dlopen'd webkit, and so the closure keeps those store paths.
  #
  # The SSO/MFA login window is a webkit view (acwebhelper dlopens
  # libwebkit2gtk), and webkitgtk under Hyprland/Wayland can render blank or
  # fail to composite — the same class of problem the nm-applet autostart works
  # around in hypr/hyprland_source.lua. Default the workarounds on (both are
  # overridable from the environment) so the login window is one you can type
  # into; a blank window otherwise shows up as a connect attempt that just
  # times out.
  #
  # The CA exports are for the vendor OpenSSL's bogus defaults (see caBundle and
  # caDir above). vpnagentd gets the same pair from its unit, because it is the
  # process that opens the gateway connection; these cover the GUI and the
  # downloader children it spawns.
  #
  # GIO_EXTRA_MODULES is here for the login window as well: acwebhelper is a
  # WebKitGTK view, WebKitGTK does https through libsoup, and libsoup looks up
  # its TLS backend as a GIO extension module (glib-networking's libgiognutls.so).
  # Without it every https navigation aborts with
  #   webViewLoadFailedCB: Failed to load page: TLS support is not available
  # and the attempt is reported as "Authentication failed due to problem
  # navigating to the single sign-on URL". env.nix adds the module to the session
  # for the same reason, but a session environment is captured at login, so a
  # login that predates the rebuild hands this process the old list — which the
  # client cannot tell apart from having no TLS at all. Prepending fixes that
  # regardless of the session's variable, and is idempotent.
  clientEnv = ''
    export WEBKIT_DISABLE_DMABUF_RENDERER=''${WEBKIT_DISABLE_DMABUF_RENDERER:-1}
    export WEBKIT_DISABLE_COMPOSITING_MODE=''${WEBKIT_DISABLE_COMPOSITING_MODE:-1}
    export SSL_CERT_FILE=''${SSL_CERT_FILE:-${caBundle}}
    export SSL_CERT_DIR=''${SSL_CERT_DIR:-${caDir}}
    export GIO_EXTRA_MODULES="${pkgs.glib-networking}/lib/gio/modules''${GIO_EXTRA_MODULES:+:$GIO_EXTRA_MODULES}"
  '';

  cli = pkgs.writeShellScriptBin "cisco-vpn" ''
    if [ ! -x ${prefix}/bin/vpn ]; then
      echo "Cisco Secure Client is not installed; run: sudo cisco-secure-client-install <deb>" >&2
      exit 1
    fi
    export LD_LIBRARY_PATH="${libPath}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    ${clientEnv}
    exec ${prefix}/bin/vpn "$@"
  '';

  gui = pkgs.writeShellScriptBin "cisco-vpnui" ''
    if [ ! -x ${prefix}/bin/vpnui ]; then
      echo "Cisco Secure Client is not installed; run: sudo cisco-secure-client-install <deb>" >&2
      exit 1
    fi
    export LD_LIBRARY_PATH="${libPath}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    ${clientEnv}
    exec ${prefix}/bin/vpnui "$@"
  '';

  # Launch entry for the GUI. `xdg.desktopEntries` doesn't exist in the nixpkgs
  # revision this flake pins, so ship the desktop file through the system
  # profile's share/applications (which is on XDG_DATA_DIRS) instead.
  desktopItem = pkgs.makeDesktopItem {
    name = "cisco-secure-client";
    desktopName = "Cisco Secure Client";
    comment = "Cisco VPN (SSO + MFA) — gateway from ~/Documents/vpn/*/ .env";
    exec = "cisco-vpnui";
    icon = "network-vpn";
    categories = ["Network"];
    terminal = false;
  };
in {
  # vpnagentd needs /dev/net/tun; module presence makes udev create it.
  boot.kernelModules = ["tun"];

  systemd.services.vpnagentd = {
    description = "Cisco Secure Client VPN agent";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];
    # The client shells out to iptables for its ACL/split-tunnel rules, and
    # loads the tun module itself on some paths.
    path = with pkgs; [iptables kmod coreutils];
    # The tree only exists after `cisco-secure-client-install`, so skip cleanly
    # on hosts that never installed it instead of failing at boot.
    unitConfig.ConditionPathExists = prefix;
    serviceConfig = {
      Type = "simple";
      ExecStartPre = "${ensureTun}";
      ExecStart = "${prefix}/bin/vpnagentd -execv_instance";
      # SSL_CERT_* work around the vendor OpenSSL's build-machine OPENSSLDIR
      # (see caBundle/caDir above); the agent is what verifies the gateway.
      Environment = [
        "LD_LIBRARY_PATH=${libPath}"
        "SSL_CERT_FILE=${caBundle}"
        "SSL_CERT_DIR=${caDir}"
      ];
      # Vendor parity: the shipped unit reads these too.
      EnvironmentFile = "-/etc/environment";
      Restart = "on-failure";
      KillMode = "process";
      PIDFile = "/run/vpnagentd.pid";
    };
  };

  environment.systemPackages = [cli gui installer desktopItem];
}
