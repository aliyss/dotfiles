#!/bin/sh
# Clear Nix's HOME purity-check leftover. Nix sets $HOME=/homeless-shelter for
# every builder; with `sandbox = false` (chroot, no namespaces) some builders
# (e.g. cargo/rustdoc, or anything writing to $HOME) create that directory, and
# the next build then fails with "home directory /homeless-shelter exists".
# Running as post-build-hook removes it after every build. Never fail the build
# over this: some trees (read-only Go module caches) can't be removed by the
# unprivileged user — root-clean them with: su -c "rm -rf /homeless-shelter"
chmod -R u+w /homeless-shelter 2>/dev/null
rm -rf /homeless-shelter 2>/dev/null || true
