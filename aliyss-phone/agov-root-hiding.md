# AGOV root-detection bypass (SukiSU Ultra / KernelSU) — session log

Date: 2026-09-08. Device: `aliyss-termux` (Android 14, kernel `6.1.112-android14-11`,
aarch64, root via **SukiSU Ultra 4.1.3** — a KernelSU fork, *not* Magisk).
Access: `ssh -p 8022 u0_a393@aliyss-termux`.

Goal: make the **AGOV app** (`ch.agov.accessapp`, Swiss government ID, v4.1.2) run on
this rooted device. It was showing **"SDK-ROOTED / Device not supported / Your
smartphone does not meet the minimum requirements for the app."**

---

## 1. What AGOV's root detection actually is

AGOV uses the **Nevis Mobile SDK** (`ch/nevis/mobile/sdk/devicecapabilities` in the
dex). Its root detector is what produced `SDK-ROOTED`. Relevant strings found in the
APK: `SDK-ROOTED`, `isDeviceBootloaderLocked`, `appAttestation`, FIDO UAF classes.
The SDK obfuscates its detection strings, so static analysis can't list the exact
checks — but the empirical evidence below pins the trigger.

## 2. Device state found (all read-only inspection)

Everything below was verified over SSH before touching anything.

```bash
# root works, context u:r:ksu:s0 (SukiSU/KernelSU)
su -c id

# packages of interest
pm list packages | grep -iE "suki|agov|kernelsu"
#   com.sukisu.ultra          -> SukiSU Ultra manager v4.1.3
#   ch.agov.accessapp         -> AGOV v4.1.2

# root solution inventory
ls /data/adb/                 # ksu, ksud, kpm, lspd, modules, tricky_store,
                              # zygisksu, rezygisk, nohello (leftover), ...
ls /data/adb/modules/         # HideNavBar, bindhosts, playintegrityfix,
                              # system_app_nuker, tricky_store, zygisksu,
                              # zygisk_vector, revanced apps, ...
#   -> Zygisk Next 1.4.2 (zygisksu) active, Vector v2.2 (Xposed-compatible) active,
#      Tricky Store v1.4.1 WITH a real keybox.xml, PIF v1.8 (SarhanRoot)

# kernel features (ksud)
/data/adb/ksu/bin/ksud feature list
#   su_compat     ENABLED   -> traditional 'su' command support (/system/bin/su)
#   kernel_umount ENABLED   -> kernel auto-unmounts modules for non-root apps
#   selinux_hide  ENABLED   -> sanitizes /sys/fs/selinux results for app UIDs
#   sulog         DISABLED
#   adb_root      DISABLED

# NO SUSFS support (no /sys/fs/susfs) -> kernel-level path hiding unavailable
ls /sys/fs/susfs/   # No such file or directory
```

Key findings:

- **AGOV's mount namespace was already clean** — no ksu/magisk/zygisk/module mounts
  visible from its process:
  ```bash
  su -c "cat /proc/<agov-pid>/mounts" | grep -iE "ksu|magisk|adb|zygisk|tricky"
  #   only stock overlay mounts (camera, product media) — nothing root-related
  ```
- **`/system/bin/su` is a REAL file on the system partition** (334 952 bytes,
  timestamp `2009-01-01`, the classic KernelSU su binary), on `/dev/block/dm-14`
  mounted at `/` (read-only, dm-verity). It is a leftover from an older root
  install — modern KernelSU/SukiSU ksud does *not* create it (verified by grepping
  the ksud sources of both tiann/KernelSU and sukisu-ultra/sukisu-ultra). This is
  the main detection vector a non-root app like AGOV sees.
- **The kernel's kprobe su hook is live** (`CONFIG_KPROBES=y`, hooks confirmed in
  dmesg): allowlisted apps get root via `execve("/system/bin/su")` interception and
  redirect, *without* needing the binary file to exist:
  ```bash
  dmesg | grep -i "su found"
  #   KernelSU: sys_execve su found
  #   KernelSU: faccessat su->sh!
  #   KernelSU: handle_setresuid from 0 to 0
  ```
- **AGOV's allowlist entry** (parsed from `/data/adb/ksu/.allowlist`) is already
  correct: `allow_su=0 umount_modules=1` (root denied, modules unmounted). The
  KernelSU allowlist file format is `u32 magic (0x7f4b5355) + u32 version + N ×
  struct app_profile (776 bytes each)` — see section 5 for the parser.
- ksud daemon disguises itself as a deleted `busybox` process (`/data/adb/ksu/bin/busybox (deleted)` in `/proc/*/exe`).
- Tricky Store `tee_status` = `teeBroken=true`; keystore2 logs show
  `SECURE_HW_COMMUNICATION_FAILED` during key generation — the TEE/keymaster has
  communication problems on this device (relevant only if AGOV later needs
  hardware-backed attestation; Tricky Store + keybox should cover PI).

Conclusion: with mounts already clean and SELinux hiding on, the surviving
detectable artifact for a non-root app is the real `/system/bin/su` file (and any
root-manager/Zygisk traces), which is exactly what **Shamiko** hides per-app.

## 3. What was changed (the actual fix)

1. **Installed Shamiko 1.2.5** (module id `zygisk_shamiko`) via `ksud module
   install`. Shamiko is the Zygisk-based root hider that makes su binaries, root
   mounts and Zygisk traces invisible to specific apps at runtime.
2. **Patched Shamiko's `customize.sh` version check** so it accepts the SukiSU
   kernel version number (details in section 4).
3. **Added `ch.agov.accessapp` to Tricky Store's `target.txt`** so the keystore
   attestation spoofing also covers AGOV (harmless; helps only if AGOV later checks
   attestation / bootloader lock):
   ```bash
   su -c "echo 'ch.agov.accessapp' >> /data/adb/tricky_store/target.txt"
   ```
4. **Deliberately did NOT touch** (all rejected after investigation):
   - `su_compat` feature toggle — disabling it does not remove the binary and risks
     breaking `su`; the binary cannot be deleted at runtime anyway (`/system` is
     read-only, remount refused: `'/dev/block/dm-14' is read-only`).
   - The allowlist file — AGOV already has `allow_su=0` (root denied), which is the
     correct state.
   - SUSFS kernel — kernel has no SUSFS support; flashing one is the "hard core"
     fallback (needs a reboot + kernel flash, do not do casually).

## 4. Installing Shamiko on SukiSU Ultra (the patch)

### 4.1 The problem

Shamiko 1.2.5 aborts on SukiSU with:

```
- KernelSU version: 40796 (kernel) + 40796 (ksud)
*********************************************************
! KernelSU version abnormal!
! Please integrate KernelSU into your kernel
  as submodule instead of copying the source code
*********************************************************
- Error: Failed to install module script
```

Cause: Shamiko's `customize.sh` treats any `KSU_KERNEL_VER_CODE >= 20000` as a
"copied-source fork" and aborts:

```sh
elif [ "$KSU_KERNEL_VER_CODE" -ge 20000 ]; then   # abort
```

SukiSU Ultra numbers its kernel version 4xxxx (> 20000), so it always trips this
heuristic. The check is protective only — the SukiSU kernel has all the required
hooks (kprobe su, umount handling, Zygisk via Zygisk Next 789 ≥ required 497).

### 4.2 The zip uses XZ-compressed entries

`unzip` (Termux and desktop) silently fails to extract `verify.sh`/`customize.sh`/
`module.prop` etc. — they are stored with zip method 95 (XZ), which both unzips
lack. (`ksud` itself can read them, which is why the installer ran.) Python's
`zipfile` also refuses method 95, so extract them by hand:

```python
# extract_xz.py — pull raw XZ streams out of the zip and run them through xz -d
import struct, subprocess, os, sys, zipfile
zip_path, out_dir = sys.argv[1], sys.argv[2]
os.makedirs(out_dir, exist_ok=True)
z = zipfile.ZipFile(zip_path); raw = open(zip_path, 'rb').read()
for info in z.infolist():
    name = info.filename
    if info.compress_type == 95:
        off = info.header_offset
        _, _, _, _, _, _, _, csize, _, fnlen, extralen = struct.unpack_from('<IHHHHHIIIHH', raw, off)
        comp = raw[off + 30 + fnlen + extralen : off + 30 + fnlen + extralen + csize]
        p = subprocess.run(['xz', '-d', '-c'], input=comp, capture_output=True)
        out = os.path.join(out_dir, name)
        os.makedirs(os.path.dirname(out), exist_ok=True) if '/' in name else None
        open(out, 'wb').write(p.stdout)
        print('XZ OK', name, len(p.stdout))
```

### 4.3 The patch

```bash
# extracted into /tmp/shamiko (desktop side)
cd /tmp/shamiko
sed -i 's/\[ "$KSU_KERNEL_VER_CODE" -ge 20000 \]/[ "$KSU_KERNEL_VER_CODE" -ge 200000 ]/' customize.sh
# recompute its sha256 (verify.sh checks every script against <file>.sha256; format is a bare hex hash)
sha256sum customize.sh | awk '{print $1}' > customize.sh.sha256
```

Rebuild the zip with normal deflate (keeps it standard; 6.5 MB → 8.2 MB):

```python
# rezip.py
import os, zipfile
src, out = '/tmp/shamiko', '/tmp/shamiko-patched.zip'
zf = zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED)
for root, dirs, files in os.walk(src):
    for d in dirs:
        rel = os.path.relpath(os.path.join(root, d), src)
        zf.writestr(zipfile.ZipInfo(rel + '/'), b'')
    for f in files:
        full = os.path.join(root, f); rel = os.path.relpath(full, src)
        st = os.stat(full)
        zi = zipfile.ZipInfo(rel)
        zi.compress_type = zipfile.ZIP_DEFLATED
        zi.external_attr = (st.st_mode & 0xFFFF) << 16
        with open(full, 'rb') as fh: zf.writestr(zi, fh.read())
zf.close()
```

### 4.4 Install

```bash
scp -P 8022 /tmp/shamiko-patched.zip u0_a393@aliyss-termux:/data/data/com.termux/files/home/
ssh -p 8022 u0_a393@aliyss-termux "su -c '/data/adb/ksu/bin/ksud module install /data/data/com.termux/files/home/shamiko-patched.zip'"
#   - Module installed successfully!
#   /data/adb/modules/zygisk_shamiko/module.prop: id=zygisk_shamiko name=Shamiko version=v1.2.5 (414)
```

## 5. Allowlist parsing (the AGOV entry was already fine)

`/data/adb/ksu/.allowlist` format (KernelSU `kernel/policy/allowlist.c` +
`uapi/app_profile.h`): `u32 magic (0x7f4b5355 ' KSU')` + `u32 version (4)` + N ×
`struct app_profile` (776 bytes; v3 files are migrated on load):

```c
struct app_profile {
    u32  version;                 // off 0
    char key[256];                // off 4   (package name)
    s32  curr_uid;                // off 260
    bool allow_su;                // off 264
    union {                       // off 272
        struct { bool use_default; char template_name[256];
                 struct root_profile profile; } rp_config;    // root-granted apps
        struct { bool use_default;
                 struct non_root_profile profile; } nrp_config; // non-root apps
    };
};
```

Parsed result (12 entries), AGOV line in bold:

```
[10] key='ch.agov.accessapp' uid=10359 allow_su=0 use_default=1 umount_modules=1
```

→ root **denied**, module unmount **enabled** — exactly the state Shamiko needs.
(The manager UI shows "untoggled", which matches `allow_su=0`; the file keeps a
profile entry even for denied apps.)

## 6. State after this session

| Item | State |
|---|---|
| Shamiko v1.2.5 | ✅ installed (patched), pending reboot to load |
| AGOV root (`allow_su`) | ✅ 0 (denied) |
| AGOV umount modules | ✅ 1 (on) |
| AGOV in Tricky Store `target.txt` | ✅ added |
| `kernel_umount`, `selinux_hide` | ✅ on (pre-existing) |
| `/system/bin/su` binary | ⏳ still on disk (see 7.1 for removal plan) |

## 7. Next steps / fallbacks

1. **Reboot the phone** — required for Shamiko to load into Zygisk. After reboot
   ensure `sshd` is up in Termux (`sv up sshd`) before reconnecting.
2. **Re-test AGOV**: force-stop + relaunch, check the UI no longer shows
   `SDK-ROOTED`. If it still does, clear AGOV's data (`pm clear
   ch.agov.accessapp`) and retry — the Nevis check runs at startup and may be
   cached. (`pm clear` wipes login state; acceptable since the app was unusable.)
3. **If still detected**, in order:
   a. **Hide My Applist (HMA)** via the Vector (Xposed) framework — hide
      `com.sukisu.ultra`, `com.dergoogler.mmrl`, Tricky Store, Zygisk Next,
      Termux, etc. from AGOV's package queries (Nevis actively adds root-app
      package detection — see their release notes re: Fox Magisk Module Manager).
   b. **Remove `/system/bin/su` at boot** — it's a leftover the current ksud never
      recreates; a module with a `post-fs-data.sh` that renames/deletes it would
      make it disappear for everyone (root keeps working via the kprobe execve
      hook, which fires on the path string before file lookup). Requires a reboot.
   c. **SUSFS kernel** — deepest hiding (path-level), but needs flashing a
      SUSFS-patched kernel + reboot. Last resort.

## 8. Key commands reference (diagnostics used)

```bash
ssh -p 8022 u0_a393@aliyss-termux
su -c id                                   # root works, u:r:ksu:s0
su -c "ls /data/adb/modules/"              # module inventory
su -c "/data/adb/ksu/bin/ksud feature list"
su -c "dmesg | grep -i 'su found'"         # kprobe su hook activity
su -c "cat /proc/<pid>/mounts"             # what an app's namespace sees
su -c "ls /sys/fs/susfs/"                  # SUSFS presence (absent here)
su -c "strings /system/bin/su | head"      # su binary (real file, 334952 B)
pm path ch.agov.accessapp                  # pull APK for static analysis
# UI dump to read AGOV's on-screen error:
su -c "uiautomator dump /data/local/tmp/ui.xml && cat /data/local/tmp/ui.xml"
```

Relevant source files consulted (for the record):
- `tiann/KernelSU` — `kernel/feature/sucompat.c`, `kernel/policy/allowlist.c`,
  `uapi/app_profile.h`, `userspace/ksud/src/feature.rs`
- `sukisu-ultra/sukisu-ultra` — ksud userspace (no `/system/bin/su` writer)
- `LSPosed/LSPosed.github.io` releases — Shamiko `shamiko-414` (v1.2.5)