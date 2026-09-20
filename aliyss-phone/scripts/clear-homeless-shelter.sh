#!/bin/sh
# Clear Nix's HOME purity-check leftover. Nix sets $HOME=/homeless-shelter for
# every builder; with `sandbox = false` (chroot, no namespaces) some builders
# (e.g. cargo/rustdoc, Go caches, yazi, fish plugins) create that directory,
# and the next build then fails with "home directory /homeless-shelter exists".
# Running as post-build-hook removes it after every derivation. Never fail the
# build: some trees are read-only (Go module caches) and need chmod first;
# if that still fails, try a root cleanup (KernelSU su is available even for
# the nixbld builder).
chmod -R u+w /homeless-shelter 2>/dev/null || true
rm -rf /homeless-shelter 2>/dev/null || true
if [ -d /homeless-shelter ]; then
  chmod -R u+w /homeless-shelter 2>/dev/null || true
  su -c "chmod -R u+w /homeless-shelter 2>/dev/null; rm -rf /homeless-shelter 2>/dev/null || true" 2>/dev/null || true
  rm -rf /homeless-shelter 2>/dev/null || true
fi
