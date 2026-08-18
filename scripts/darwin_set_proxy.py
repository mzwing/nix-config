"""Set proxy for nix-daemon to speed up downloads.

Breaks a chicken-and-egg problem on a new Mac: this config installs sing-box from NUR, but nix cannot fetch NUR without a proxy. Point it at a temporary one, build, then --unset.
Standard library only, so it runs before nix and devenv work.

    sudo python3 scripts/darwin_set_proxy.py
    sudo python3 scripts/darwin_set_proxy.py http://10.0.0.2:1080
    sudo python3 scripts/darwin_set_proxy.py --unset

https://github.com/NixOS/nix/issues/1472#issuecomment-1532955973
"""

from __future__ import annotations

import os
import plistlib
import shlex
import subprocess
import sys
from pathlib import Path

NIX_DAEMON_PLIST = Path("/Library/LaunchDaemons/org.nixos.nix-daemon.plist")

# http proxy provided by clash or other proxy tools
DEFAULT_PROXY = "http://127.0.0.1:7890"


def set_proxy(proxy: str | None) -> None:
    pl = plistlib.loads(NIX_DAEMON_PLIST.read_bytes())
    env = pl.setdefault("EnvironmentVariables", {})

    # NOTE: curl only accept the lowercase of `http_proxy`!
    # NOTE: https://curl.se/libcurl/c/libcurl-env.html
    if proxy is None:
        env.pop("http_proxy", None)
        env.pop("https_proxy", None)
    else:
        env["http_proxy"] = proxy
        env["https_proxy"] = proxy

    os.chmod(NIX_DAEMON_PLIST, 0o644)
    NIX_DAEMON_PLIST.write_bytes(plistlib.dumps(pl))
    os.chmod(NIX_DAEMON_PLIST, 0o444)


def reload_daemon() -> None:
    for cmd in (
        f"launchctl unload {NIX_DAEMON_PLIST}",
        f"launchctl load {NIX_DAEMON_PLIST}",
    ):
        print(cmd)
        subprocess.run(shlex.split(cmd), capture_output=False, check=False)


def main(argv: list[str]) -> int:
    args = argv[1:]

    if args and args[0] in ("-h", "--help"):
        print(__doc__)
        return 0

    if len(args) > 1:
        print(f"expected at most one argument, got {len(args)}", file=sys.stderr)
        return 2

    if args and args[0] == "--unset":
        proxy = None
    elif args:
        proxy = args[0]
    else:
        proxy = DEFAULT_PROXY

    set_proxy(proxy)
    print(f"nix-daemon proxy {'cleared' if proxy is None else f'set to {proxy}'}")
    reload_daemon()
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
