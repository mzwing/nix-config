#!/usr/bin/env python3
"""Generate or edit one image through an OpenAI-compatible Images API."""

from __future__ import annotations

import argparse
import base64
import json
import mimetypes
import os
import urllib.error
import urllib.request
import uuid
from pathlib import Path

DEFAULT_BASE_URL = "https://api.openai.com/v1"
DEFAULT_MODEL = "gpt-image-2"


def env(*names: str) -> str | None:
    for name in names:
        value = os.environ.get(name, "").strip()
        if value:
            return value
    return None


def read_api_key() -> str:
    key = env("IMAGEGEN_API_KEY")
    key_file = env("IMAGEGEN_API_KEY_FILE")
    if not key and key_file:
        key = Path(key_file).read_text(encoding="utf-8").strip()
    key = key or env("OPENAI_API_KEY")
    if not key:
        raise SystemExit("No API key: set IMAGEGEN_API_KEY, IMAGEGEN_API_KEY_FILE, or OPENAI_API_KEY.")
    return key


def encode_multipart(fields: dict[str, str], files: list[tuple[str, Path]]) -> tuple[bytes, str]:
    boundary = uuid.uuid4().hex
    parts = []
    for name, value in fields.items():
        parts.append(f'--{boundary}\r\nContent-Disposition: form-data; name="{name}"\r\n\r\n{value}\r\n'.encode())
    for name, path in files:
        mime = mimetypes.guess_type(path.name)[0] or "application/octet-stream"
        header = f'--{boundary}\r\nContent-Disposition: form-data; name="{name}"; filename="{path.name}"\r\nContent-Type: {mime}\r\n\r\n'
        parts.append(header.encode() + path.read_bytes() + b"\r\n")
    parts.append(f"--{boundary}--\r\n".encode())
    return b"".join(parts), f"multipart/form-data; boundary={boundary}"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    for name in ("generate", "edit"):
        command = commands.add_parser(name)
        prompt = command.add_mutually_exclusive_group(required=True)
        prompt.add_argument("--prompt")
        prompt.add_argument("--prompt-file", type=Path)
        command.add_argument("--out", type=Path, required=True)
        command.add_argument("--model", default=env("IMAGEGEN_MODEL") or DEFAULT_MODEL)
        command.add_argument("--size", default="1024x1024")
        command.add_argument("--quality", choices=["low", "medium", "high", "auto"])
        command.add_argument("--background", choices=["transparent", "opaque", "auto"])
        command.add_argument("--force", action="store_true", help="Overwrite an existing --out file.")
        command.add_argument("--dry-run", action="store_true", help="Print the request instead of sending it.")
        if name == "edit":
            command.add_argument("--image", type=Path, action="append", required=True, help="Input image; repeat for several, in prompt order.")
            command.add_argument("--mask", type=Path)
            command.add_argument("--input-fidelity", choices=["low", "high"])
    return parser


def main() -> None:
    args = build_parser().parse_args()
    prompt = (args.prompt if args.prompt is not None else args.prompt_file.read_text(encoding="utf-8")).strip()
    if not prompt:
        raise SystemExit("The prompt is empty.")
    if args.out.exists() and not args.force:
        raise SystemExit(f"{args.out} exists; pick a new name or pass --force.")

    base_url = (env("IMAGEGEN_BASE_URL", "OPENAI_BASE_URL") or DEFAULT_BASE_URL).rstrip("/")
    fields = {"model": args.model, "prompt": prompt, "size": args.size}
    for key in ("quality", "background", "input_fidelity"):
        value = getattr(args, key, None)
        if value:
            fields[key] = value

    files = []
    if args.command == "edit":
        files = [("image[]", path) for path in args.image]
        if args.mask:
            files.append(("mask", args.mask))
        missing = [str(path) for _, path in files if not path.is_file()]
        if missing:
            raise SystemExit("Missing input image: " + ", ".join(missing))
    url = f"{base_url}/images/{'edits' if files else 'generations'}"

    if args.dry_run:
        print(json.dumps({"url": url, "fields": fields, "files": [f"{name}={path}" for name, path in files]}, ensure_ascii=False, indent=2))
        return

    body, content_type = encode_multipart(fields, files) if files else (json.dumps(fields).encode(), "application/json")
    request = urllib.request.Request(url, data=body, method="POST", headers={"Authorization": f"Bearer {read_api_key()}", "Content-Type": content_type})
    try:
        with urllib.request.urlopen(request, timeout=900) as response:
            payload = json.load(response)
    except urllib.error.HTTPError as error:
        raise SystemExit(f"HTTP {error.code} from {url}: {error.read().decode(errors='replace')}")
    except urllib.error.URLError as error:
        raise SystemExit(f"Cannot reach {url}: {error.reason}")

    item = (payload.get("data") or [{}])[0]
    if item.get("b64_json"):
        image = base64.b64decode(item["b64_json"])
    elif item.get("url"):
        with urllib.request.urlopen(item["url"], timeout=300) as response:
            image = response.read()
    else:
        raise SystemExit("No image in the response: " + json.dumps(payload, ensure_ascii=False)[:2000])

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_bytes(image)
    prompt_path = args.out.with_suffix(".prompt.txt")
    if args.prompt_file is None or prompt_path.resolve() != args.prompt_file.resolve():
        prompt_path.write_text(prompt + "\n", encoding="utf-8")
    print(args.out)
    if item.get("revised_prompt"):
        print(f"revised prompt: {item['revised_prompt']}")


if __name__ == "__main__":
    main()
