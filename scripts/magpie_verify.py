"""Disable magpie models whose number fingerprint isn't the model they claim to be.

Run on a timer by the software/ai/magpie feature, with the JSON config it generates. Each model is asked through magpie's own gateway, ranked by lm-detector's fpd against its reference bank, and disabled with `magpie model disable` after two failing rounds. Models disabled here are kept in the state directory and tried again on every run, so a relay that serves the real model again gets it back.
"""

import json
import re
import subprocess
import sys
import urllib.request
from pathlib import Path
from typing import Any

# Names these calls in magpie's Usage; the loopback gateway takes any key.
KEY = "magpie-verify"
# The reference bank was sampled at low effort.
FPD_ARGS = ["-k", KEY, "-a", "cc", "-e", "low", "--json"]
STATE = Path.home() / ".local/state/magpie-verify"

# Variants providers append to a model id, stripped one at a time until it names a bank identity.
SUFFIX = re.compile(
    r"(@\d+[km]|-\d+[km]|:free|-\d{8}|-\d{4}"
    r"|-(max|high|medium|low|minimal|none|priority|fast|thinking|tiered))$"
)
# Providers write claude-opus-5-5 where the bank writes claude-opus-5.5.
DASHED_VERSION = re.compile(r"(?<=[a-z]-)(\d+)-(\d+)(?=-|$)")
# deepseek-v4-pro-0813 is a dated snapshot of deepseek-v4-pro.
SNAPSHOT = re.compile(r"-\d{4}$")


def identity(model: str, bank: set[str], aliases: dict[str, str]) -> str | None:
    name = model.rsplit("/", 1)[-1].lower()
    while True:
        for candidate in (name, DASHED_VERSION.sub(r"\1.\2", name)):
            candidate = aliases.get(candidate, candidate)
            if candidate in bank:
                return candidate
        stripped = SUFFIX.sub("", name)
        if stripped == name:
            return None
        name = stripped


def served(gateway: str) -> list[str]:
    request = urllib.request.Request(
        f"{gateway}/models", headers={"Authorization": f"Bearer {KEY}"}
    )
    with urllib.request.urlopen(request) as response:
        rows = json.load(response)["data"]
    # Routing groups, and the bare ids bareModelIDs adds, don't start with their owner's id.
    return [row["id"] for row in rows if row["id"].startswith(row["owned_by"] + "/")]


def check(
    config: dict[str, Any], model: str, claimed: str
) -> tuple[dict[str, Any] | None, float | None, str]:
    """One fpd round: its report, the share of it the claimed identity and its snapshots hold, and what it found. The share is None without a calibrated ranking."""
    try:
        run = subprocess.run(
            [config["fpd"], *FPD_ARGS, "-b", config["gateway"], "-m", model],
            capture_output=True,
            # fpd exits 1 for a round it couldn't rank; its JSON still says why.
            check=False,
            text=True,
            # A relay can hold a stream open forever once its first byte is in.
            timeout=600,
        )
    except subprocess.TimeoutExpired:
        return None, None, "fpd took over 10 minutes"
    if not run.stdout:
        return None, None, run.stderr.strip()
    report = json.loads(run.stdout)
    round_ = report["rounds"][0]
    analysis = round_.get("analysis")
    if not analysis or analysis["probability_status"] != "reference_calibrated":
        errors = [s["error"] for s in round_["samples"] if s.get("error")]
        return report, None, errors[0] if errors else analysis["evidence"]["reason"]
    base = SNAPSHOT.sub("", claimed)
    results = analysis["results"]
    share = sum(
        r["probability"] for r in results if SNAPSHOT.sub("", r["model"]) == base
    )
    top = results[0]
    return (
        report,
        share,
        f"{claimed} {share:.0%}, top {top['model']} {top['probability']:.0%}",
    )


def judge(
    config: dict[str, Any], model: str, claimed: str, rounds: int
) -> tuple[str, list[dict[str, Any] | None], str]:
    """Up to rounds fpd rounds, stopping at the first that passes or can't be ranked. Fake only when every one fell under the threshold."""
    reports = []
    for _ in range(rounds):
        report, share, found = check(config, model, claimed)
        reports.append(report)
        if share is None:
            return "inconclusive", reports, found
        if share >= config["threshold"]:
            return "ok", reports, found
    return "fake", reports, found


def magpie(config: dict[str, Any], verb: str, model: str) -> None:
    subprocess.run(
        [config["magpie"], "model", verb, model], check=True, stdout=subprocess.DEVNULL
    )


def disable(
    config: dict[str, Any], model: str, reports: list[dict[str, Any] | None]
) -> None:
    magpie(config, "disable", model)
    state = STATE / f"{model.replace('/', '--')}.json"
    state.write_text(json.dumps({"model": model, "reports": reports}, indent=2))


def log(verdict: str, model: str, found: str) -> None:
    # Under systemd stdout is a pipe, and print would hold back a whole run's lines.
    print(f"{verdict:<12} {model}  {found}", flush=True)


def main() -> None:
    config = json.loads(Path(sys.argv[1]).read_text())
    bank = {m["id"] for m in json.loads(Path(config["bank"]).read_text())["models"]}
    excluded = set(config["excludeProviders"])
    STATE.mkdir(parents=True, exist_ok=True)

    # The gateway refuses a disabled model before any upstream call, so each one disabled here is let back in for its round.
    retested = set()
    for path in sorted(STATE.glob("*.json")):
        model = json.loads(path.read_text())["model"]
        if model.split("/", 1)[0] in excluded:
            continue
        retested.add(model)
        magpie(config, "enable", model)
        claimed = identity(model, bank, config["aliases"])
        if claimed is None:
            path.unlink()
            log("released", model, "no longer in the reference bank")
            continue
        verdict, reports, found = judge(config, model, claimed, 1)
        if verdict == "ok":
            path.unlink()
            log("restored", model, found)
        else:
            disable(config, model, reports)
            log("kept off", model, found)

    for model in served(config["gateway"]):
        if model.split("/", 1)[0] in excluded or model in retested:
            continue
        claimed = identity(model, bank, config["aliases"])
        if claimed is None:
            log("skipped", model, "not in the reference bank")
            continue
        verdict, reports, found = judge(config, model, claimed, 2)
        if verdict == "fake":
            disable(config, model, reports)
            verdict = "disabled"
        log(verdict, model, found)


if __name__ == "__main__":
    main()
