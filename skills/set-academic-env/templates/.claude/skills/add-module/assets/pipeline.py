#!/usr/bin/env python3
"""Per-module pipeline provenance. Record step runs; check presence/tamper/staleness.
  python pipeline.py record --step src/01_x.py --inputs a.csv --outputs output/fig.pdf
  python pipeline.py check [--strict]
Importable from Python (`from pipeline import record`); callable via CLI from any language.
State: pipeline_state.json next to this file. Paths are relative to this file's dir."""
import argparse, hashlib, json, os, subprocess, sys
from datetime import datetime, timezone
HERE = os.path.dirname(os.path.abspath(__file__))
STATE = os.path.join(HERE, "pipeline_state.json")
def _sha256(path):
    p = path if os.path.isabs(path) else os.path.join(HERE, path)
    if not os.path.exists(p): return None
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 16), b""): h.update(chunk)
    return h.hexdigest()
def _git_sha():
    try:
        return subprocess.check_output(["git","rev-parse","--short","HEAD"], cwd=HERE,
                                        stderr=subprocess.DEVNULL).decode().strip()
    except Exception: return None
def _load():
    try: return json.load(open(STATE))
    except Exception: return {}
def record(step, inputs=None, outputs=None):
    st = _load()
    st[step] = {"last_run": datetime.now(timezone.utc).isoformat(timespec="seconds"),
                "git_sha": _git_sha(), "script_sha256": _sha256(step),
                "inputs": [{"path": p, "sha256": _sha256(p)} for p in (inputs or [])],
                "outputs": [{"path": p, "sha256": _sha256(p)} for p in (outputs or [])]}
    json.dump(st, open(STATE, "w"), indent=2)
def check(strict=False):
    st, issues = _load(), 0
    for step, rec in st.items():
        if rec.get("script_sha256") and _sha256(step) != rec["script_sha256"]:
            print(f"STALE: script {step} changed since last run"); issues += 1
        for i in rec.get("inputs", []):
            n = _sha256(i["path"])
            if n is None: print(f"MISSING input: {i['path']} ({step})"); issues += 1
            elif i["sha256"] and n != i["sha256"]: print(f"STALE input: {i['path']} ({step})"); issues += 1
        for o in rec.get("outputs", []):
            n = _sha256(o["path"])
            if n is None: print(f"MISSING output: {o['path']} ({step})"); issues += 1
            elif o["sha256"] and n != o["sha256"]: print(f"TAMPERED output: {o['path']} ({step})"); issues += 1
    print(f"pipeline check: {issues} issue(s)" if issues else "pipeline check: all present and current")
    return issues
if __name__ == "__main__":
    ap = argparse.ArgumentParser(); sub = ap.add_subparsers(dest="cmd", required=True)
    r = sub.add_parser("record"); r.add_argument("--step", required=True)
    r.add_argument("--inputs", nargs="*", default=[]); r.add_argument("--outputs", nargs="*", default=[])
    c = sub.add_parser("check"); c.add_argument("--strict", action="store_true")
    a = ap.parse_args()
    if a.cmd == "record": record(a.step, a.inputs, a.outputs)
    else: issues = check(a.strict); sys.exit(1 if (a.strict and issues) else 0)
