#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "gemini-webapi[browser]==2.1.1",
# ]
# ///
"""Store the cookies gemini-bridge needs, then prove they work.

gemini.google.com is reached with your logged-in browser session, so there is no
API key to configure — only two cookies to capture. This walks that through:

    gemini-auth                     paste __Secure-1PSID / __Secure-1PSIDTS
    gemini-auth --from-firefox      read them out of your Firefox profile
    gemini-auth --from-json FILE    import a browser extension's JSON export

Whatever the source, the result is written to $GEMINI_COOKIE_FILE (default
~/.config/gemini-webapi/cookies.json, mode 0600) and then validated against
Gemini, so you find out here rather than on the next request. gemini-webapi
rotates __Secure-1PSIDTS by itself from then on; the cache it keeps beside that
file is why the file must stay where it is.
"""

from __future__ import annotations

import argparse
import asyncio
import getpass
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

from gemini_webapi import GeminiClient, set_log_level
from gemini_webapi.constants import AccountStatus
from gemini_webapi.exceptions import AuthError

PSID = "__Secure-1PSID"
PSIDTS = "__Secure-1PSIDTS"

_config_home = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config")
COOKIE_FILE = Path(os.environ.get("GEMINI_COOKIE_FILE") or _config_home / "gemini-webapi" / "cookies.json")
SERVICE = "gemini-api"

HOWTO = f"""
Get the cookies from a browser you are signed in to gemini.google.com with:

  1. open https://gemini.google.com in a *private* window and sign in
     (a throwaway session; it is not your main profile's)
  2. F12 -> Network tab -> reload the page
  3. click any request and copy the values of these two cookies:
       {PSID}
       {PSIDTS}
  4. paste them below

Only {PSID} is strictly required. Press Ctrl-C to abort.
""".rstrip()


def normalise(raw: object) -> dict[str, str]:
    """Accept a mapping or a browser-extension array-of-objects export."""
    if isinstance(raw, list):
        raw = {c.get("name"): c.get("value") for c in raw if isinstance(c, dict)}
    if not isinstance(raw, dict):
        raise SystemExit("expected a JSON object or a cookie-extension export")
    return {str(k): str(v) for k, v in raw.items() if isinstance(v, str)}


def ask(label: str, required: bool) -> str:
    while True:
        try:
            value = getpass.getpass(f"{label}: ").strip() if sys.stdin.isatty() else input(f"{label}: ").strip()
        except EOFError:
            raise SystemExit("no input — nothing written")
        if value or not required:
            return value
        print("  this one is required", file=sys.stderr)


def from_firefox() -> dict[str, str]:
    try:
        import browser_cookie3
    except ImportError as exc:
        raise SystemExit("browser-cookie3 is not installed in this environment") from exc
    try:
        jar = browser_cookie3.firefox(domain_name="google.com")
    except Exception as exc:  # profile not found, sqlite locked, ...
        raise SystemExit(f"could not read Firefox cookies: {exc}") from exc
    return {c.name: c.value for c in jar if c.name in (PSID, PSIDTS)}


async def validate(cookies: dict[str, str]) -> list[str]:
    set_log_level("WARNING")
    client = GeminiClient(secure_1psid=cookies[PSID], secure_1psidts=cookies.get(PSIDTS, ""))
    try:
        await client.init(timeout=60, auto_refresh=False, verbose=False)
    except AuthError as exc:
        raise SystemExit(f"Gemini rejected those cookies: {exc}")
    except Exception as exc:
        raise SystemExit(f"could not reach Gemini: {exc}")
    # init() does not fail on expired cookies — it simply fetches less — so the
    # account status is what actually proves the cookies work.
    if client.account_status != AccountStatus.AVAILABLE:
        status = client.account_status
        raise SystemExit(f"Gemini says this session is {status.name}: {status.description}")

    try:
        return [m.model_name or m.display_name for m in (client.list_models() or [])]
    finally:
        try:
            await client.close()
        except Exception:
            pass


def restart_service() -> None:
    """The bridge caches its client, so an already-running one keeps the old
    cookies until it is restarted."""
    if not shutil.which("systemctl"):
        return
    try:
        active = subprocess.run(
            ["systemctl", "--user", "is-active", SERVICE], capture_output=True, text=True
        ).stdout.strip()
        if active == "active":
            subprocess.run(["systemctl", "--user", "restart", SERVICE], check=True)
            print(f"restarted {SERVICE} so the new cookies take effect")
    except Exception as exc:
        print(f"(could not restart {SERVICE}: {exc} — do it yourself with "
              f"`systemctl --user restart {SERVICE}`)", file=sys.stderr)


def main() -> int:
    parser = argparse.ArgumentParser(description="Store and verify Gemini web cookies.")
    source = parser.add_mutually_exclusive_group()
    source.add_argument("--from-firefox", action="store_true", help="read the cookies out of Firefox")
    source.add_argument("--from-json", metavar="FILE", help="import a cookies JSON export")
    parser.add_argument("--file", default=str(COOKIE_FILE), help=f"where to write (default {COOKIE_FILE})")
    args = parser.parse_args()

    target = Path(args.file)

    if args.from_firefox:
        cookies = from_firefox()
        if not cookies.get(PSID):
            raise SystemExit(f"Firefox has no {PSID} — sign in to gemini.google.com there first")
    elif args.from_json:
        cookies = normalise(json.loads(Path(args.from_json).read_text(encoding="utf-8")))
        if not cookies.get(PSID):
            raise SystemExit(f"{args.from_json} has no {PSID}")
    else:
        print(HOWTO + "\n")
        cookies = {PSID: ask(PSID, True)}
        psidts = ask(f"{PSIDTS} (optional, Enter to skip)", False)
        if psidts:
            cookies[PSIDTS] = psidts

    print("\nchecking the cookies against Gemini …")
    models = asyncio.run(validate(cookies))
    print("signed in ✓")

    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(cookies, indent=2) + "\n", encoding="utf-8")
    target.chmod(0o600)

    print(f"wrote {target}")
    if models:
        print("models available to this account: " + ", ".join(models))
    restart_service()
    return 0


if __name__ == "__main__":
    sys.exit(main())
