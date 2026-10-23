"""Manage the browser extensions listed in data/chromium and data/zen.

`add` lists an extension by its Chrome Web Store or addons.mozilla.org page, for Chromium or Zen, under the name in the page's URL unless one is given. A Chromium extension is also pinned in data/chromium/extensions.lock.json, since ungoogled-chromium never downloads extensions itself; Zen installs and updates its own from AMO. `update` re-pins every Chromium extension to its newest release. Run it from the repo root, through `just browser-extension-add` and `just chromium-extensions-update`.

    python3 scripts/browser_extensions.py add https://chromewebstore.google.com/detail/bitwarden-password-manager/nngceckbapebfimnlniiiahkandclblb
    python3 scripts/browser_extensions.py add https://addons.mozilla.org/firefox/addon/ublock-origin/ ublock
    python3 scripts/browser_extensions.py update
"""

from __future__ import annotations

import base64
import json
import re
import sys
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path

CHROMIUM_EXTENSIONS = Path("data/chromium/extensions.json")
CHROMIUM_LOCK = Path("data/chromium/extensions.lock.json")
ZEN_EXTENSIONS = Path("data/zen/extensions.json")

UPDATE_SERVICE = "https://clients2.google.com/service/update2/crx"
NAMESPACE = {"gupdate": "http://www.google.com/update2/response"}
AMO_ADDON_API = "https://addons.mozilla.org/api/v5/addons/addon"

# chromewebstore.google.com/detail/<name>/<id>, or the older chrome.google.com/webstore/detail/<name>/<id>.
WEB_STORE_PAGE = re.compile(r"/detail/(?:([^/]+)/)?([a-p]{32})")
AMO_PAGE = re.compile(r"addons\.mozilla\.org/(?:[^/]+/)?firefox/addon/([^/?#]+)")


def read_json(path: Path) -> dict:
    return json.loads(path.read_text())


def write_json(path: Path, data: dict) -> None:
    path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")


def pin(extension_ids: list[str]) -> tuple[dict[str, dict[str, str]], list[str]]:
    # Higher than any real Chromium, so the service answers with each extension's newest release.
    query = [
        ("response", "updatecheck"),
        ("acceptformat", "crx3"),
        ("prodversion", "999.0"),
    ]
    query += [("x", f"id={extension_id}&uc") for extension_id in extension_ids]
    with urllib.request.urlopen(
        f"{UPDATE_SERVICE}?{urllib.parse.urlencode(query)}"
    ) as response:
        apps = ET.fromstring(response.read()).findall("gupdate:app", NAMESPACE)

    pins = {}
    unavailable = []
    for app in apps:
        extension_id = app.attrib["appid"]
        release = app.find("gupdate:updatecheck", NAMESPACE)
        if release is None or release.get("status") != "ok":
            unavailable.append(extension_id)
            continue
        digest = bytes.fromhex(release.attrib["hash_sha256"])
        pins[extension_id] = {
            "hash": "sha256-" + base64.b64encode(digest).decode(),
            "url": release.attrib["codebase"],
            "version": release.attrib["version"],
        }
    return pins, unavailable


def update() -> int:
    names_by_id = {
        extension_id: name
        for name, extension_id in read_json(CHROMIUM_EXTENSIONS).items()
    }
    pins, unavailable = pin(list(names_by_id))
    if unavailable:
        names = ", ".join(sorted(names_by_id[i] for i in unavailable))
        print(f"not served by the Chrome Web Store: {names}", file=sys.stderr)
        return 1

    write_json(CHROMIUM_LOCK, pins)
    print(f"pinned {len(pins)} extensions in {CHROMIUM_LOCK}")
    return 0


def add(page: str, name: str | None) -> int:
    if web_store := WEB_STORE_PAGE.search(page):
        listing, extension_id = CHROMIUM_EXTENSIONS, web_store[2]
        name = name or web_store[1]
    elif amo := AMO_PAGE.search(page):
        with urllib.request.urlopen(f"{AMO_ADDON_API}/{amo[1]}/") as response:
            listing, extension_id = ZEN_EXTENSIONS, json.load(response)["guid"]
        name = name or amo[1]
    else:
        print(
            "expected an extension's Chrome Web Store or addons.mozilla.org page",
            file=sys.stderr,
        )
        return 2
    if name is None:
        print("the page's URL carries no name; pass one after it", file=sys.stderr)
        return 2

    extensions = read_json(listing)
    if extension_id in extensions.values():
        print(f"{extension_id} is already in {listing}")
        return 0
    if name in extensions:
        print(f"{name} already names {extensions[name]} in {listing}", file=sys.stderr)
        return 1

    if listing == CHROMIUM_EXTENSIONS:
        pins, unavailable = pin([extension_id])
        if unavailable:
            print(f"{name} is not served by the Chrome Web Store", file=sys.stderr)
            return 1
        write_json(CHROMIUM_LOCK, read_json(CHROMIUM_LOCK) | pins)

    write_json(listing, extensions | {name: extension_id})
    print(f"added {name} to {listing}")
    return 0


def main(argv: list[str]) -> int:
    args = argv[1:]
    if args[:1] == ["add"] and len(args) in (2, 3):
        return add(args[1], args[2] if len(args) == 3 else None)
    if args == ["update"]:
        return update()

    print(__doc__)
    return 2


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
