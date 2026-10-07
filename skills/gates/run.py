#!/usr/bin/env python3
"""aifier gates runner: run the gates declared in aifier.yml and capture their output.

usage: run.py <aifier.yml> [--area <name>] [--family lint|typecheck|test|build] [--preflight]
       [--compare-ci] [--out <dir>]

Prints a `## Verification Run` block: one line per gate with the command, the exit code and
the path of its captured output, or BLOCKED with the reason. Exit code 1 when a gate failed,
2 when the preflight failed (nothing else runs), 0 otherwise.
"""
import re, sys, os, subprocess, datetime

def parse(path):
    cfg, section, area = {"gates": {}, "preflight": [], "ci": {}}, None, None
    for raw in open(path):
        line = raw.rstrip("\n")
        if not line.strip() or line.lstrip().startswith("#"): continue
        indent = len(line) - len(line.lstrip())
        body = line.strip()
        if indent == 0:
            section = body.split(":")[0]; area = None
            if section == "preflight" and body.endswith("]"):
                inner = body.partition(":")[2].strip()[1:-1]
                cfg["preflight"] = [x.strip().strip('"\'') for x in inner.split(",") if x.strip()]
            continue
        if section == "gates":
            if indent == 2: area = body.rstrip(":"); cfg["gates"][area] = {}
            elif indent == 4 and area:
                k, _, v = body.partition(":"); v = v.strip()
                cfg["gates"][area][k.strip()] = None if v in ("null", "~", "") else v.strip('"\'')
        elif section == "preflight" and body.startswith("- "):
            cfg["preflight"].append(body[2:].strip().strip('"\''))
        elif section == "ci":
            k, _, v = body.partition(":"); cfg["ci"][k.strip()] = v.strip().strip('"\'')
    return cfg

def run(cmd, cwd, log):
    with open(log, "w") as f:
        f.write("$ %s   (cwd %s)\n" % (cmd, cwd))
        f.flush()
        p = subprocess.run(cmd, shell=True, cwd=cwd, stdout=f, stderr=subprocess.STDOUT)
    tail = open(log).read().splitlines()[-3:]
    return p.returncode, tail

def main(argv):
    if len(argv) < 2: print(__doc__); return 2
    cfg = parse(argv[1]); root = os.path.dirname(os.path.abspath(argv[1]))
    opt = lambda k: argv[argv.index(k) + 1] if k in argv else None
    out = opt("--out") or os.path.join(root, ".aifier", "gates")
    os.makedirs(out, exist_ok=True)
    stamp = datetime.datetime.now().strftime("%Y-%m-%dT%H-%M")
    print("## Verification Run\n")
    print("Date: %s · Config: %s\n" % (stamp, os.path.relpath(argv[1], root)))
    if "--preflight" in argv or cfg["preflight"]:
        for i, cmd in enumerate(cfg["preflight"]):
            code, tail = run(cmd, root, os.path.join(out, "preflight-%d.log" % i))
            if code != 0:
                print("BLOCKED: preflight `%s` exited %d\n  %s" % (cmd, code, "\n  ".join(tail)))
                return 2
            print("- preflight ok: `%s`" % cmd)
        if cfg["preflight"]: print()
    failed = 0
    if "--compare-ci" in argv:
        ci = cfg["ci"].get("file")
        text = open(os.path.join(root, ci)).read() if ci and os.path.exists(os.path.join(root, ci)) else ""
        print("CI comparison (%s):" % (ci or "no CI file declared"))
        for area, fams in cfg["gates"].items():
            for fam, cmd in fams.items():
                if not cmd: continue
                token = cmd.split()[0] if not cmd.startswith(("npm", "npx", "uv", "poetry")) else " ".join(cmd.split()[:3])
                print("- %s/%s: %s" % (area, fam, "found in CI" if token in text else "NOT in CI (`%s`)" % token))
        print()
    for area, fams in cfg["gates"].items():
        if opt("--area") and area != opt("--area"): continue
        cwd = root if area == "root" else os.path.join(root, area)
        for fam, cmd in fams.items():
            if opt("--family") and fam != opt("--family"): continue
            if not cmd:
                print("- %s/%s: not declared (gap)" % (area, fam)); continue
            log = os.path.join(out, "%s-%s.log" % (area, fam))
            code, tail = run(cmd, cwd, log)
            status = "OK" if code == 0 else "FAIL"
            failed += code != 0
            print("- %s/%s: %s (exit %d) `%s` → %s\n  %s" % (area, fam, status, code, cmd, os.path.relpath(log, root), "\n  ".join(tail)))
    print("\nVerdict: %s" % ("OK" if not failed else "FAIL (%d gate%s)" % (failed, "s" if failed > 1 else "")))
    return 1 if failed else 0

if __name__ == "__main__": sys.exit(main(sys.argv))
