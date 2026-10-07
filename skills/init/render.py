#!/usr/bin/env python3
"""aifier init renderer: deterministic rendering of the templates from aifier.yml.

usage: render.py <aifier.yml> <templates dir> <target repo> [--force] [--skills <dir>]

Placeholders written as two braces around a dotted key resolve against the configuration; a line whose placeholder resolves
to null is dropped; an unknown placeholder is left as is for the engine to fill. Blocks between
`{{#list}}` and `{{/list}}` repeat per item. Existing target files are skipped unless --force.
With --skills, the `{{ }}` of every SKILL.md in that directory are substituted in place.
"""
import re, sys, os, datetime

def parse_scalar(v):
    v = v.strip()
    if v == "" or v == "null" or v == "~": return None
    if v[0] in "\"'" and v[-1] == v[0]: return v[1:-1]
    if v.startswith("[") and v.endswith("]"):
        inner = v[1:-1].strip()
        return [parse_scalar(x) for x in split_top(inner)] if inner else []
    if v.startswith("{") and v.endswith("}"):
        out = {}
        for part in split_top(v[1:-1]):
            k, _, val = part.partition(":"); out[k.strip()] = parse_scalar(val)
        return out
    return v

def split_top(s):
    parts, depth, cur, q = [], 0, "", None
    for ch in s:
        if q: cur += ch; q = None if ch == q else q; continue
        if ch in "\"'": q = ch; cur += ch; continue
        if ch in "[{": depth += 1
        if ch in "]}": depth -= 1
        if ch == "," and depth == 0: parts.append(cur); cur = ""; continue
        cur += ch
    if cur.strip(): parts.append(cur)
    return [p.strip() for p in parts]

def parse_yaml(text):
    root, stack = {}, [(-1, {})]
    stack[0] = (-1, root)
    for raw in text.splitlines():
        line = raw.split(" #")[0].rstrip() if not raw.lstrip().startswith("#") else ""
        if not line.strip(): continue
        indent = len(line) - len(line.lstrip())
        while stack and stack[-1][0] >= indent: stack.pop()
        parent = stack[-1][1]
        body = line.strip()
        if body.startswith("- "):
            parent.setdefault("__list__", []).append(parse_scalar(body[2:])); continue
        k, _, v = body.partition(":")
        if v.strip() == "":
            node = {}; parent[k.strip()] = node; stack.append((indent, node))
        else:
            parent[k.strip()] = parse_scalar(v)
    return fix_lists(root)

def fix_lists(node):
    if isinstance(node, dict):
        if "__list__" in node and len(node) == 1: return node["__list__"]
        return {k: fix_lists(v) for k, v in node.items()}
    return node

def lookup(ctx, path):
    cur = ctx
    for part in path.split("."):
        if isinstance(cur, dict) and part in cur: cur = cur[part]
        else: return ("missing", None)
    return ("ok", cur)

VAR = re.compile(r"\{\{([a-z_][a-z0-9_.]*)\}\}")
BLOCK = re.compile(r"\{\{#([a-z_][a-z0-9_.]*)\}\}\n?(.*?)\{\{/\1\}\}\n?", re.S)

def render_text(text, ctx):
    def block(m):
        status, items = lookup(ctx, m.group(1))
        if status != "ok" or not items: return ""
        out = []
        if isinstance(items, dict):
            for key, val in items.items():
                item = dict(ctx); item.update(val if isinstance(val, dict) else {"value": val})
                item["dir"] = "" if key == "root" else key; item["name"] = key
                if m.group(1) == "areas":
                    g = ctx.get("gates", {}).get(key, {}) if isinstance(ctx.get("gates"), dict) else {}
                    item["gates"] = g
                out.append(render_text(m.group(2), item))
        else:
            for val in items:
                item = dict(ctx); item.update(val if isinstance(val, dict) else {"path": val, "value": val})
                out.append(render_text(m.group(2), item))
        return "".join(out)
    text = BLOCK.sub(block, text)
    lines = []
    for line in text.split("\n"):
        drop = False
        def var(m):
            nonlocal drop
            status, val = lookup(ctx, m.group(1))
            if status != "ok": return m.group(0)
            if val is None: drop = True; return ""
            if isinstance(val, list): return ", ".join(str(x) for x in val)
            return str(val)
        new = VAR.sub(var, line)
        if not drop: lines.append(new)
    return "\n".join(lines)

TARGETS = [
    ("AGENTS.md", "AGENTS.md"),
    ("CLAUDE.md", "CLAUDE.md"),
    ("github/ISSUE_TEMPLATE_change.yml", ".github/ISSUE_TEMPLATE/change.yml"),
    ("github/PULL_REQUEST_TEMPLATE.md", ".github/PULL_REQUEST_TEMPLATE.md"),
    ("memory/learned-rules.md", "{memory.rules}"),
    ("memory/decisions-README.md", "{memory.decisions}/README.md"),
    ("memory/0000-template.md", "{memory.decisions}/0000-template.md"),
    ("memory/handoff.md", "{memory.handoff}"),
]

def main(argv):
    if len(argv) < 4: print(__doc__); return 2
    cfg_path, tdir, repo = argv[1], argv[2], argv[3]
    force, skills = "--force" in argv, (argv[argv.index("--skills") + 1] if "--skills" in argv else None)
    ctx = parse_yaml(open(cfg_path).read())
    ctx["date"] = datetime.date.today().isoformat()
    ctx.setdefault("default_branch", (ctx.get("branches") or {}).get("default"))
    ctx.setdefault("target_branch", (ctx.get("branches") or {}).get("target"))
    ctx.setdefault("label_prefix", (ctx.get("labels") or {}).get("prefix"))
    ctx.setdefault("required_checks", (ctx.get("ci") or {}).get("required_checks"))
    written, skipped = [], []
    def emit(rel, content):
        path = os.path.join(repo, rel)
        if os.path.exists(path) and not force: skipped.append(rel); return
        os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
        open(path, "w").write(content); written.append(rel)
    engines = ctx.get("engines") or []
    for src, dst in TARGETS:
        if src == "CLAUDE.md" and "claude-code" not in engines: continue
        dst = dst.replace("{memory.rules}", str(ctx["memory"]["rules"])).replace("{memory.decisions}", str(ctx["memory"]["decisions"]).rstrip("/")).replace("{memory.handoff}", str(ctx["memory"]["handoff"]))
        emit(dst, render_text(open(os.path.join(tdir, src)).read(), ctx))
    areas = ctx.get("areas") or {}
    for key, area in areas.items():
        if key == "root": continue
        item = dict(ctx); item["area"] = dict(area, dir=key, name=key)
        emit(os.path.join(key, "AGENTS.md"), render_text(open(os.path.join(tdir, "AREA_AGENTS.md")).read(), item))
    if skills:
        gates = ctx.get("gates") or {}
        score = lambda a: (sum(1 for v in (gates[a] or {}).values() if v), 1 if (gates[a] or {}).get("test") else 0)
        best = max(gates, key=score) if gates else None
        flat = dict(ctx); flat["gates"] = gates.get(best, {}) if best else {}
        for name in sorted(os.listdir(skills)):
            f = os.path.join(skills, name, "SKILL.md")
            if not os.path.exists(f) or name in ("assess", "init"): continue
            text = open(f).read()
            if "{{" not in text: continue
            out = render_text(text, flat)
            out = "\n".join(l for l in out.split("\n") if not l.startswith("<!-- placeholders:"))
            if best: out = out.replace("\n---\n", "\n---\n<!-- gate commands are those of `%s` -->\n" % best, 1)
            open(f, "w").write(out); written.append(f)
    print("rendered:"); [print("  - " + w) for w in written]
    if skipped: print("skipped (exist, use --force to overwrite):"); [print("  - " + s) for s in skipped]
    return 0

if __name__ == "__main__": sys.exit(main(sys.argv))
