#!/usr/bin/env python3
"""Regenerate the skills table in README.md from each SKILL.md's frontmatter.

    python3 scripts/sync-skill-index.py [--check]

The table lives between the SKILLS:START / SKILLS:END markers in README.md.
Existing row order is preserved; skills not yet in the table are appended
alphabetically. --check exits 1 if the file is out of date, printing nothing
else — for use as a pre-commit gate.

Descriptions are the frontmatter description truncated at "Use when", since
everything after it is trigger phrasing aimed at the model rather than at a
human reading the index.
"""

import argparse
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
README = ROOT / "README.md"
START, END = "<!-- SKILLS:START -->", "<!-- SKILLS:END -->"


def frontmatter(skill_md):
    """name and description from a SKILL.md, without a YAML dependency."""
    text = skill_md.read_text()
    if not text.startswith("---\n"):
        return None
    block = text.split("\n---", 1)[0][4:]
    out = {}
    key = None
    for line in block.splitlines():
        m = re.match(r"^([A-Za-z_-]+):\s*(.*)$", line)
        if m:
            key, val = m.group(1), m.group(2).strip()
            out[key] = val
        elif key and line.startswith((" ", "\t")):
            out[key] += " " + line.strip()
    return out if "name" in out else None


def summarise(description):
    """The human-facing half: everything before the model-facing triggers."""
    head = re.split(r"\s*(?:Use when|Use this skill when|TRIGGER)\b", description, 1)[0].strip()
    if not head:
        # The description opens with its triggers: drop that sentence, keep the rest.
        head = re.sub(r"^[^.]*\.\s*", "", description).strip()
    return (head or description).rstrip(".")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()

    skills = {}
    for d in sorted((ROOT / "skills").iterdir()):
        if (d / "SKILL.md").exists() and (fm := frontmatter(d / "SKILL.md")):
            skills[d.name] = summarise(fm.get("description", ""))

    readme = README.read_text()
    if START not in readme or END not in readme:
        sys.exit(f"markers {START} / {END} not found in README.md")
    before, rest = readme.split(START, 1)
    current, after = rest.split(END, 1)

    # Preserve the order already in the table; append anything new alphabetically.
    listed = [n for n in re.findall(r"\[([^\]]+)\]\(skills/", current) if n in skills]
    order = listed + [n for n in sorted(skills) if n not in listed]

    rows = "\n".join(
        f"| [{n}](skills/{n}/) | {skills[n]} |" for n in order
    )
    table = (
        f"\n| Skill | Description |\n|-------|-------------|\n{rows}\n"
    )
    updated = f"{before}{START}{table}{END}{after}"

    if args.check:
        sys.exit(0 if updated == readme else 1)
    if updated != readme:
        README.write_text(updated)
        print(f"README.md index updated — {len(order)} skills")
    else:
        print("README.md index already current")


if __name__ == "__main__":
    main()
