import configparser
import json
import re
import socket
import subprocess
import sys
import tempfile
import time
from collections.abc import Generator
from contextlib import contextmanager
from pathlib import Path
from typing import Any

TERMINAL_CODES = re.compile(r"\x1b\[[0-9;]*m|\r")


def log(message: str) -> None:
    # Under systemd stdout is a pipe, and print would hold back a whole run's lines.
    print(message, flush=True)


def endpoint(profile_path: Path) -> dict[str, Any]:
    profile = configparser.ConfigParser()
    profile.read(profile_path)
    interface, peer = profile["Interface"], profile["Peer"]
    host, port = peer["Endpoint"].rsplit(":", 1)
    return {
        "type": "wireguard",
        "tag": "warp",
        "mtu": interface.getint("MTU"),
        "address": [address.strip() for address in interface["Address"].split(",")],
        "private_key": interface["PrivateKey"],
        "peers": [
            {
                "address": host,
                "port": int(port),
                "public_key": peer["PublicKey"],
                "allowed_ips": [ip.strip() for ip in peer["AllowedIPs"].split(",")],
            }
        ],
    }


@contextmanager
def new_account(config: dict[str, Any]) -> Generator[Path]:
    """The WireGuard profile of a new WARP account, written beside the deployed one so it can replace it in place."""
    with tempfile.TemporaryDirectory(dir=Path(config["profile"]).parent) as directory:
        for command in (["register", "--accept-tos"], ["generate"]):
            subprocess.run([config["wgcf"], *command], cwd=directory, check=True)
        yield Path(directory) / "wgcf-profile.conf"


def ipv6_result(output: str) -> str:
    # `-F` prints the check's IPv4 result and then its IPv6 one, each under its own header line.
    lines = TERMINAL_CODES.sub("", output).splitlines()
    return lines[lines.index("IPv6:") + 1].split(":", 1)[1].strip()


def unlocked(config: dict[str, Any], proxy: str | None = None) -> bool:
    for check in config["checks"]:
        run = subprocess.run(
            [
                config["regionRestrictionCheck"],
                "-F",
                check,
                *(["-P", proxy] if proxy else []),
            ],
            capture_output=True,
            check=True,
            text=True,
        )
        result = ipv6_result(run.stdout)
        log(f"{check}: {result}")
        # warp_unlock also counts ChatGPT's web-only result as unlocked.
        if not result.startswith(("Yes", "Web Only")):
            return False
    return True


@contextmanager
def proxy_through(config: dict[str, Any], candidate: Path) -> Generator[str]:
    with socket.socket() as probe:
        probe.bind(("127.0.0.1", 0))
        port = probe.getsockname()[1]
    settings = {
        "log": {"level": "warn"},
        # Over IPv6 the WARP peer would be reached through the running sing-box's own WARP.
        "dns": {
            "servers": [{"type": "local", "tag": "local"}],
            "strategy": "ipv4_only",
        },
        # The check runs curl with -4 and then -6, and through socks5:// curl resolves both localhost and the target in that family, so the -6 run leaves through WARP's IPv6.
        "inbounds": [
            {"type": "mixed", "tag": listen, "listen": listen, "listen_port": port}
            for listen in ("127.0.0.1", "::1")
        ],
        "endpoints": [endpoint(candidate)],
        "route": {"final": "warp", "default_domain_resolver": "local"},
    }
    path = candidate.parent / "sing-box.json"
    path.write_text(json.dumps(settings))
    process = subprocess.Popen(
        [config["singBox"], "run", "-c", path, "-D", candidate.parent]
    )
    try:
        while True:
            if process.poll() is not None:
                sys.exit(f"the throwaway sing-box exited with {process.returncode}")
            try:
                socket.create_connection(("127.0.0.1", port)).close()
                break
            except ConnectionRefusedError:
                time.sleep(0.1)
        yield f"socks5://localhost:{port}"
    finally:
        process.terminate()
        process.wait()


def render(config: dict[str, Any]) -> None:
    profile = Path(config["profile"])
    if not profile.exists():
        with new_account(config) as candidate:
            candidate.replace(profile)
    Path(config["fragment"]).write_text(json.dumps({"endpoints": [endpoint(profile)]}))


def unlock(config: dict[str, Any]) -> None:
    log("deployed account:")
    if unlocked(config):
        return
    for attempt in range(1, config["attempts"] + 1):
        log(f"new account {attempt}/{config['attempts']}:")
        with new_account(config) as candidate:
            with proxy_through(config, candidate) as proxy:
                passed = unlocked(config, proxy)
            if passed:
                candidate.replace(config["profile"])
                subprocess.run(
                    [config["systemctl"], "restart", "sing-box.service"], check=True
                )
                return
    sys.exit(f"none of {config['attempts']} new WARP accounts passed")


def main() -> None:
    command, path = sys.argv[1:]
    config = json.loads(Path(path).read_text())
    {"render": render, "unlock": unlock}[command](config)


if __name__ == "__main__":
    main()
