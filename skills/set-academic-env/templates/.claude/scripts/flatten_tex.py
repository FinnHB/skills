#!/usr/bin/env python3
"""Flatten a LaTeX file by recursively inlining \\input{}/\\include{} relative to the
file's directory. Prints flattened source to stdout. Identity on files with no includes.
Usage: flatten_tex.py paper/main.tex"""
import re, sys, os
INC = re.compile(r'(?<!\\)\\(?:input|include)\{([^}]+)\}')
def flatten(path, seen=None):
    seen = set() if seen is None else seen
    ap = os.path.abspath(path)
    if ap in seen: return ""
    seen.add(ap)
    base = os.path.dirname(ap)
    try: src = open(ap, encoding="utf-8", errors="replace").read()
    except FileNotFoundError: return ""
    out, pos = [], 0
    for m in INC.finditer(src):
        out.append(src[pos:m.start()])
        inc = m.group(1)
        if not os.path.splitext(inc)[1]: inc += ".tex"
        out.append(flatten(os.path.join(base, inc), seen))
        pos = m.end()
    out.append(src[pos:])
    return "".join(out)
if __name__ == "__main__":
    sys.stdout.write(flatten(sys.argv[1]) if len(sys.argv) > 1 else "")
