#!/usr/bin/env python3
"""interactive-html — serve a page of questions on localhost, wait for one submission.

    python3 form.py spec.json answers.json [--port 0] [--timeout-min 0]

Prints the URL on stdout, then blocks. Exits 0 once the form is submitted and
answers.json is written; 2 if --timeout-min is set and elapses. Stdlib only.

Two layouts, chosen by whether "document" is present:

  PANEL — one document, several questions about it as a whole. The file renders
  in a left pane, the questions sit in a right pane.

  INLINE — questions each attached to a different part of the material. Omit
  "document" and interleave "prose" blocks with questions in one column, so each
  question sits directly under the thing it is about.

spec.json:
  {
    "title":    "Research follow-ups",
    "intro":    "<p>HTML, optional — shown above the questions.</p>",
    "document": "report.html",        # PANEL layout; omit for INLINE
    "questions": [
      {"type": "prose", "html": "<h2>Caching</h2><p>Any HTML.</p>"},
      {"id": "db", "question": "Which database?", "type": "choice",
       "context": "<p>HTML, optional — shown under the question.</p>",
       "options": [{"label": "Postgres", "description": "why"}, {"label": "SQLite"}],
       "required": true},
      {"id": "notes", "question": "Anything else?", "type": "longtext"}
    ]
  }

type: choice (radios) | multi (checkboxes) | text (one line) | longtext (box)
    | prose (a document block — no input, carries "html" instead of "id").
choice and multi always carry a free-text "Other" field.
"""

import argparse
import http.server
import json
import pathlib
import socketserver
import sys
import threading
from html import escape

CSS = """
:root {
  --paper:#f7f6f3; --card:#fffefb; --border:#e7e4dd; --ink:#1c1d20;
  --ink-soft:#3a3d42; --muted:#6b6f76; --accent:#3b5bdb; --ok:#2f9e44;
}
@media (prefers-color-scheme: dark) {
  :root {
    --paper:#16171a; --card:#1e2023; --border:#33363c; --ink:#eceef1;
    --ink-soft:#c6cad0; --muted:#8b9099; --accent:#8ba4ff; --ok:#51cf66;
  }
}
* { box-sizing: border-box; }
body { margin:0; background:var(--paper); color:var(--ink); line-height:1.55;
       font-family:"IBM Plex Sans", system-ui, -apple-system, sans-serif; }
.split { display:flex; height:100vh; align-items:stretch; overflow:hidden; }
.doc { flex:1 1 55%; border-right:1px solid var(--border); background:var(--card); }
.doc iframe { width:100%; height:100%; border:0; display:block; }
.split .pane { flex:1 1 45%; height:100vh; overflow-y:auto; }
.wrap { max-width:720px; margin:0 auto; padding:40px 28px 140px; }
.kicker { font-size:12px; letter-spacing:.08em; text-transform:uppercase;
          color:var(--muted); margin:0 0 8px; }
h1 { font-family:Fraunces, Georgia, serif; font-weight:600; font-size:28px;
     margin:0 0 10px; letter-spacing:-.01em; }
.intro { color:var(--ink-soft); font-size:15px; margin:0 0 28px; }
.prose { margin:0 0 18px; color:var(--ink-soft); font-size:15px; }
.prose :first-child { margin-top:0; }
.prose h2 { font-family:Fraunces, Georgia, serif; font-weight:600; font-size:19px;
            color:var(--ink); margin:34px 0 10px; }
.prose h3 { font-size:15px; color:var(--ink); margin:24px 0 8px; }
.prose img, .prose svg { max-width:100%; }
.q { background:var(--card); border:1px solid var(--border); border-radius:10px;
     padding:20px 22px; margin:0 0 18px; }
.q.missing { border-color:#e03131; }
.qhead { display:flex; gap:10px; align-items:baseline; margin:0 0 4px; }
.num { font-family:"IBM Plex Mono", ui-monospace, monospace; font-size:12px;
       color:var(--muted); flex:none; padding-top:2px; }
.qtext { font-weight:600; font-size:16px; margin:0; }
.req { color:#e03131; font-weight:400; }
.ctx { color:var(--ink-soft); font-size:14px; margin:8px 0 0; }
.ctx :first-child { margin-top:0; } .ctx :last-child { margin-bottom:0; }
.opts { margin:14px 0 0; display:flex; flex-direction:column; gap:8px; }
label.opt { display:flex; gap:10px; padding:10px 12px; border:1px solid var(--border);
            border-radius:8px; cursor:pointer; align-items:flex-start; }
label.opt:hover { border-color:var(--accent); }
label.opt:has(input:checked) { border-color:var(--accent);
            box-shadow:inset 0 0 0 1px var(--accent); }
label.opt input { margin:4px 0 0; flex:none; accent-color:var(--accent); }
.olabel { font-size:14px; font-weight:500; }
.odesc { font-size:13px; color:var(--muted); margin-top:2px; }
input[type=text], textarea {
  width:100%; font:inherit; font-size:14px; color:var(--ink); background:var(--paper);
  border:1px solid var(--border); border-radius:8px; padding:10px 12px; margin-top:12px; }
input[type=text]:focus, textarea:focus { outline:2px solid var(--accent); outline-offset:1px; }
textarea { min-height:110px; resize:vertical; }
.other { margin-top:0; }
.bar { position:fixed; bottom:0; right:0; width:100%; background:var(--card);
       border-top:1px solid var(--border); padding:14px 28px;
       display:flex; gap:16px; align-items:center; justify-content:flex-end; }
.split .bar { width:45%; }
.count { color:var(--muted); font-size:13px; margin-right:auto;
         font-family:"IBM Plex Mono", ui-monospace, monospace; }
button { font:inherit; font-size:14px; font-weight:600; color:#fff; background:var(--accent);
         border:0; border-radius:8px; padding:11px 22px; cursor:pointer; }
button:hover { filter:brightness(1.08); }
kbd { font-family:"IBM Plex Mono", ui-monospace, monospace; font-size:11px;
      border:1px solid var(--border); border-radius:4px; padding:1px 5px; color:var(--muted); }
.done { max-width:520px; margin:22vh auto; text-align:center; padding:0 24px; }
.done h1 { color:var(--ok); }
@media (max-width:900px) { .doc { display:none; } .split .bar { width:100%; } }
"""

JS = """
function collect() {
  const out = {}, missing = [];
  document.querySelectorAll('.q').forEach(q => {
    q.classList.remove('missing');
    const id = q.dataset.id, type = q.dataset.type;
    const other = q.querySelector('.other') ? q.querySelector('.other').value.trim() : '';
    let val;
    if (type === 'multi') {
      val = [...q.querySelectorAll('input[type=checkbox]:checked')].map(i => i.value);
      if (other) val.push(other);
    } else if (type === 'choice') {
      const picked = q.querySelector('input[type=radio]:checked');
      val = other ? other : (picked ? picked.value : '');
    } else {
      val = q.querySelector('textarea, input[type=text]').value.trim();
    }
    const empty = Array.isArray(val) ? val.length === 0 : val === '';
    if (empty && q.dataset.required === '1') { missing.push(q); q.classList.add('missing'); }
    if (!empty) out[id] = val;
  });
  return {out, missing};
}
function tally() {
  const total = document.querySelectorAll('.q').length;
  const {out} = collect();
  document.querySelectorAll('.q').forEach(q => q.classList.remove('missing'));
  document.getElementById('count').textContent =
    Object.keys(out).length + ' of ' + total + ' answered';
}
document.addEventListener('input', tally);
document.addEventListener('change', tally);
async function submit() {
  const {out, missing} = collect();
  if (missing.length) { missing[0].scrollIntoView({behavior:'smooth', block:'center'}); return; }
  await fetch('/submit', {method:'POST', headers:{'Content-Type':'application/json'},
                          body: JSON.stringify(out)});
  document.body.innerHTML =
    '<div class="done"><h1>Answers received</h1>' +
    '<p class="intro">Claude has them and is continuing. You can close this tab.</p></div>';
}
document.addEventListener('keydown', e => {
  if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') submit();
});
window.addEventListener('load', tally);
"""


def render_question(i, q):
    qtype = q.get("type", "text")
    if qtype == "prose":
        return f'<div class="prose">{q["html"]}</div>'
    qid = escape(str(q["id"]))
    required = "1" if q.get("required") else "0"
    star = ' <span class="req">*</span>' if q.get("required") else ""
    parts = [
        f'<div class="q" data-id="{qid}" data-type="{escape(qtype)}" data-required="{required}">',
        f'<div class="qhead"><span class="num">{i:02d}</span>'
        f'<p class="qtext">{escape(q["question"])}{star}</p></div>',
    ]
    if q.get("context"):
        parts.append(f'<div class="ctx">{q["context"]}</div>')

    if qtype in ("choice", "multi"):
        control = "radio" if qtype == "choice" else "checkbox"
        parts.append('<div class="opts">')
        for opt in q.get("options", []):
            label = escape(opt["label"])
            checked = " checked" if opt.get("label") == q.get("default") else ""
            desc = (
                f'<div class="odesc">{escape(opt["description"])}</div>'
                if opt.get("description")
                else ""
            )
            parts.append(
                f'<label class="opt"><input type="{control}" name="{qid}" '
                f'value="{label}"{checked}>'
                f'<span><span class="olabel">{label}</span>{desc}</span></label>'
            )
        parts.append("</div>")
        parts.append(
            '<input type="text" class="other" placeholder="Other — type your own answer">'
        )
    elif qtype == "longtext":
        parts.append(f'<textarea placeholder="Your answer…">{escape(q.get("default", ""))}</textarea>')
    else:
        parts.append(
            f'<input type="text" value="{escape(q.get("default", ""))}" placeholder="Your answer…">'
        )
    parts.append("</div>")
    return "".join(parts)


def render(spec, has_doc):
    body = [
        f'<p class="kicker">{escape(spec.get("kicker", "Questions"))}</p>',
        f'<h1>{escape(spec.get("title", "A few questions"))}</h1>',
    ]
    if spec.get("intro"):
        body.append(f'<div class="intro">{spec["intro"]}</div>')
    n = 0
    for q in spec["questions"]:
        if q.get("type") != "prose":
            n += 1
        body.append(render_question(n, q))

    page = (
        f'<div class="pane"><div class="wrap">{"".join(body)}</div></div>'
        '<div class="bar"><span class="count" id="count"></span>'
        '<kbd>⌘</kbd><kbd>↵</kbd>'
        '<button onclick="submit()">Submit answers</button></div>'
    )
    if has_doc:
        page = f'<div class="split"><div class="doc"><iframe src="/document"></iframe></div>{page}</div>'

    return (
        "<!DOCTYPE html><html lang=en><head><meta charset=utf-8>"
        f'<title>{escape(spec.get("title", "Answer form"))}</title>'
        '<meta name=viewport content="width=device-width,initial-scale=1">'
        '<link rel=preconnect href="https://fonts.googleapis.com">'
        '<link href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,600'
        '&family=IBM+Plex+Mono:wght@400&family=IBM+Plex+Sans:wght@400;500;600&display=swap" rel=stylesheet>'
        f"<style>{CSS}</style></head><body>{page}<script>{JS}</script></body></html>"
    )


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("spec")
    ap.add_argument("answers")
    ap.add_argument("--port", type=int, default=0)
    ap.add_argument("--timeout-min", type=float, default=0, help="0 = wait indefinitely")
    a = ap.parse_args()

    spec = json.loads(pathlib.Path(a.spec).read_text())
    doc = pathlib.Path(spec["document"]).resolve() if spec.get("document") else None
    if doc and not doc.exists():
        sys.exit(f"document not found: {doc}")
    page = render(spec, bool(doc)).encode()
    submitted = threading.Event()

    class Handler(http.server.BaseHTTPRequestHandler):
        def _send(self, code, body, ctype="text/html; charset=utf-8"):
            self.send_response(code)
            self.send_header("Content-Type", ctype)
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def do_GET(self):
            if self.path == "/document" and doc:
                self._send(200, doc.read_bytes())
            elif self.path in ("/", "/index.html"):
                self._send(200, page)
            else:
                self._send(404, b"not found")

        def do_POST(self):
            raw = self.rfile.read(int(self.headers.get("Content-Length", 0)))
            pathlib.Path(a.answers).write_text(
                json.dumps(json.loads(raw), indent=2, ensure_ascii=False) + "\n"
            )
            self._send(200, b'{"ok":true}', "application/json")
            submitted.set()

        def log_message(self, *args):
            pass

    with socketserver.TCPServer(("127.0.0.1", a.port), Handler) as srv:
        url = f"http://127.0.0.1:{srv.server_address[1]}/"
        print(f"FORM READY {url}", flush=True)
        threading.Thread(target=srv.serve_forever, daemon=True).start()
        if not submitted.wait(timeout=(a.timeout_min * 60) or None):
            print("FORM TIMEOUT — no submission", flush=True)
            sys.exit(2)
    print(f"FORM SUBMITTED {a.answers}", flush=True)


if __name__ == "__main__":
    main()
