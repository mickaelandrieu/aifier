//! Deterministic rendering of the templates from `aifier.yml`.
//!
//! The contract is the one the former Python renderer of `init` established, and the golden files under
//! `tests/expected/render/` hold it: same targets, same placeholder rules, same summary.
//!
//! Rules, in order of application on a template:
//! 1. `{{#name}}…{{/name}}` repeats its body per item of `name` (a mapping: one item per key,
//!    with `dir`, `name` and, for `areas` and `subareas`, the area's `from` and `gates`; a
//!    sequence: one item per value, with `path` and `value`). A scalar renders the body once when
//!    it is truthy. `{{^name}}…{{/name}}` renders its body once when `name` is absent, null,
//!    false or empty. An unknown or empty `name` renders nothing.
//! 2. On each line, `{{dotted.key}}` becomes the value; a null or false value drops the whole
//!    line; an unknown key is left as is for the engine to fill; a sequence joins with ", ".
//!
//! The configuration is checked before the first write: `engines` (a scalar counts as a
//! one-element sequence), `areas` (a mapping of mappings), `memory.*` (non-empty paths) and the
//! `--skills` directory. The renderer derives `subareas` (the areas minus `root`) and
//! `multi_area` (whether there is any) for the constitution.

use serde_yaml::{Mapping, Value};
use std::fmt::Write as _;
use std::fs;
use std::path::{Path, PathBuf};

pub struct Options {
    pub config: PathBuf,
    pub templates: PathBuf,
    pub target: PathBuf,
    pub force: bool,
    pub skills: Option<PathBuf>,
}

pub fn parse_args(args: &[String]) -> Result<Options, String> {
    let mut positional = Vec::new();
    let mut force = false;
    let mut skills = None;
    let mut i = 0;
    while i < args.len() {
        match args[i].as_str() {
            "--force" => force = true,
            "--skills" => {
                i += 1;
                skills = Some(PathBuf::from(
                    args.get(i).ok_or("--skills needs a directory")?,
                ));
            }
            other if other.starts_with("--") => return Err(format!("unknown option {other}")),
            other => positional.push(PathBuf::from(other)),
        }
        i += 1;
    }
    if positional.len() != 3 {
        return Err("expected <aifier.yml> <templates dir> <target repo>".into());
    }
    let mut it = positional.into_iter();
    Ok(Options {
        config: it.next().unwrap(),
        templates: it.next().unwrap(),
        target: it.next().unwrap(),
        force,
        skills,
    })
}

/// Template source (relative to the templates directory) and its destination in the
/// repository. `{memory.*}` in a destination resolves against the configuration.
const TARGETS: &[(&str, &str)] = &[
    ("AGENTS.md", "AGENTS.md"),
    ("CLAUDE.md", "CLAUDE.md"),
    (
        "github/ISSUE_TEMPLATE_change.yml",
        ".github/ISSUE_TEMPLATE/change.yml",
    ),
    (
        "github/PULL_REQUEST_TEMPLATE.md",
        ".github/PULL_REQUEST_TEMPLATE.md",
    ),
    ("memory/learned-rules.md", "{memory.rules}"),
    ("memory/decisions-README.md", "{memory.decisions}/README.md"),
    (
        "memory/0000-template.md",
        "{memory.decisions}/0000-template.md",
    ),
    ("memory/handoff.md", "{memory.handoff}"),
];

/// Skills that are never substituted in place: they run from the aifier checkout.
const UNRENDERED_SKILLS: &[&str] = &["assess", "init"];

const AREAS_SHAPE: &str = "areas must be a mapping of <dir>: { guide, stack }";

pub fn run(opts: &Options) -> Result<String, String> {
    let text = fs::read_to_string(&opts.config)
        .map_err(|e| format!("cannot read {}: {e}", opts.config.display()))?;
    let mut ctx: Mapping = match serde_yaml::from_str::<Value>(&text)
        .map_err(|e| format!("{} is not YAML: {e}", opts.config.display()))?
    {
        Value::Mapping(m) => m,
        _ => return Err(format!("{} must be a mapping", opts.config.display())),
    };
    ctx.insert(key("date"), Value::String(today()));
    set_default(&mut ctx, "default_branch", &["branches", "default"]);
    set_default(&mut ctx, "target_branch", &["branches", "target"]);
    set_default(&mut ctx, "label_prefix", &["labels", "prefix"]);
    set_default(&mut ctx, "required_checks", &["ci", "required_checks"]);

    // Every shape error is raised here, before the first write, so a failure never leaves a
    // half-rendered tree behind a lost report.
    let engines = engines(&ctx);
    let areas = areas(&ctx)?;
    let rules = memory_path(&ctx, "rules")?;
    let decisions = memory_path(&ctx, "decisions")?;
    let handoff = memory_path(&ctx, "handoff")?;
    if let Some(skills) = &opts.skills {
        fs::read_dir(skills).map_err(|e| {
            format!(
                "--skills {} is not a readable directory: {e}",
                skills.display()
            )
        })?;
    }
    add_area_views(&mut ctx, &areas);

    let mut written: Vec<String> = Vec::new();
    let mut skipped: Vec<String> = Vec::new();

    for (src, dst) in TARGETS {
        if *src == "CLAUDE.md" && !engines.iter().any(|e| e == "claude-code") {
            continue;
        }
        let dst = dst
            .replace("{memory.rules}", &rules)
            .replace("{memory.decisions}", decisions.trim_end_matches('/'))
            .replace("{memory.handoff}", &handoff);
        let template = read_template(&opts.templates, src)?;
        emit(
            opts,
            &dst,
            &render_text(&template, &ctx),
            &mut written,
            &mut skipped,
        )?;
    }

    if !areas.is_empty() {
        let template = read_template(&opts.templates, "AREA_AGENTS.md")?;
        for (k, area) in &areas {
            let name = scalar_to_string(k);
            if name == "root" {
                continue;
            }
            let mut item = ctx.clone();
            let mut area_map = match area {
                Value::Mapping(m) => m.clone(),
                _ => Mapping::new(),
            };
            area_map.insert(key("dir"), Value::String(name.clone()));
            area_map.insert(key("name"), Value::String(name.clone()));
            item.insert(key("area"), Value::Mapping(area_map));
            let dst = format!("{name}/AGENTS.md");
            emit(
                opts,
                &dst,
                &render_text(&template, &item),
                &mut written,
                &mut skipped,
            )?;
        }
    }

    if let Some(skills) = &opts.skills {
        render_skills(skills, &ctx, &mut written)?;
    }

    let mut out = String::from("rendered:\n");
    for w in &written {
        let _ = writeln!(out, "  - {w}");
    }
    if !skipped.is_empty() {
        out.push_str("skipped (exist, use --force to overwrite):\n");
        for s in &skipped {
            let _ = writeln!(out, "  - {s}");
        }
    }
    Ok(out)
}

/// `engines`: a sequence, or one scalar read as a one-element sequence.
fn engines(ctx: &Mapping) -> Vec<String> {
    match ctx.get("engines") {
        Some(Value::Sequence(s)) => s.iter().map(scalar_to_string).collect(),
        Some(v @ (Value::String(_) | Value::Number(_) | Value::Bool(_))) => {
            vec![scalar_to_string(v)]
        }
        _ => Vec::new(),
    }
}

/// `areas`: absent is no area; present, it must be a mapping whose values are mappings.
fn areas(ctx: &Mapping) -> Result<Mapping, String> {
    let areas = match ctx.get("areas") {
        None => return Ok(Mapping::new()),
        Some(Value::Mapping(m)) => m.clone(),
        Some(_) => return Err(AREAS_SHAPE.into()),
    };
    for (k, v) in &areas {
        if !matches!(v, Value::Mapping(_)) {
            return Err(format!(
                "area {} must be a mapping: {AREAS_SHAPE}",
                scalar_to_string(k)
            ));
        }
    }
    Ok(areas)
}

/// `subareas` is `areas` minus `root`; `multi_area` says whether there is any.
fn add_area_views(ctx: &mut Mapping, areas: &Mapping) {
    let mut subareas = Mapping::new();
    for (k, v) in areas {
        if scalar_to_string(k) != "root" {
            subareas.insert(k.clone(), v.clone());
        }
    }
    ctx.insert(key("multi_area"), Value::Bool(!subareas.is_empty()));
    ctx.insert(key("subareas"), Value::Mapping(subareas));
}

/// The knowledge skills are substituted in place with the gates of the area that owns the most
/// of them (ties: the one with a test gate, then the first declared).
fn render_skills(skills: &Path, ctx: &Mapping, written: &mut Vec<String>) -> Result<(), String> {
    let gates = match ctx.get("gates") {
        Some(Value::Mapping(m)) => m.clone(),
        _ => Mapping::new(),
    };
    let score = |v: &Value| -> (usize, usize) {
        match v {
            Value::Mapping(m) => (
                m.values().filter(|x| truthy(x)).count(),
                usize::from(m.get("test").map(truthy).unwrap_or(false)),
            ),
            _ => (0, 0),
        }
    };
    let mut best: Option<(String, Value)> = None;
    for (k, v) in &gates {
        let s = score(v);
        if best.as_ref().map(|(_, bv)| s > score(bv)).unwrap_or(true) {
            best = Some((scalar_to_string(k), v.clone()));
        }
    }
    let mut flat = ctx.clone();
    flat.insert(
        key("gates"),
        match &best {
            Some((_, Value::Mapping(m))) => Value::Mapping(m.clone()),
            _ => Value::Mapping(Mapping::new()),
        },
    );
    let mut names: Vec<String> = fs::read_dir(skills)
        .map_err(|e| format!("cannot list {}: {e}", skills.display()))?
        .filter_map(|e| e.ok())
        .map(|e| e.file_name().to_string_lossy().into_owned())
        .collect();
    names.sort();
    for name in names {
        if UNRENDERED_SKILLS.contains(&name.as_str()) {
            continue;
        }
        let file = skills.join(&name).join("SKILL.md");
        let Ok(text) = fs::read_to_string(&file) else {
            continue;
        };
        if !text.contains("{{") {
            continue;
        }
        let rendered = render_text(&text, &flat);
        let mut out: String = rendered
            .split('\n')
            .filter(|l| !l.starts_with("<!-- placeholders:"))
            .collect::<Vec<_>>()
            .join("\n");
        if let Some((b, _)) = &best {
            out = out.replacen(
                "\n---\n",
                &format!("\n---\n<!-- gate commands are those of `{b}` -->\n"),
                1,
            );
        }
        fs::write(&file, out).map_err(|e| format!("cannot write {}: {e}", file.display()))?;
        written.push(file.to_string_lossy().into_owned());
    }
    Ok(())
}

fn emit(
    opts: &Options,
    rel: &str,
    content: &str,
    written: &mut Vec<String>,
    skipped: &mut Vec<String>,
) -> Result<(), String> {
    let path = opts.target.join(rel);
    if path.exists() && !opts.force {
        skipped.push(rel.to_string());
        return Ok(());
    }
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)
            .map_err(|e| format!("cannot create {}: {e}", parent.display()))?;
    }
    fs::write(&path, content).map_err(|e| format!("cannot write {}: {e}", path.display()))?;
    written.push(rel.to_string());
    Ok(())
}

fn read_template(dir: &Path, name: &str) -> Result<String, String> {
    let p = dir.join(name);
    fs::read_to_string(&p).map_err(|e| format!("cannot read template {}: {e}", p.display()))
}

/// `memory.<k>`: a non-empty string, or the rendering stops before writing anything.
fn memory_path(ctx: &Mapping, k: &str) -> Result<String, String> {
    let memory = match ctx.get("memory") {
        Some(Value::Mapping(m)) => m,
        _ => return Err("memory: is missing from the configuration".into()),
    };
    match memory.get(k) {
        None => Err(format!("memory.{k} is missing from the configuration")),
        Some(Value::String(s)) if !s.trim().is_empty() => Ok(s.clone()),
        Some(_) => Err(format!("memory.{k} must be a path")),
    }
}

fn set_default(ctx: &mut Mapping, k: &str, path: &[&str]) {
    if ctx.contains_key(k) {
        return;
    }
    let v = lookup_path(ctx, path).cloned().unwrap_or(Value::Null);
    ctx.insert(key(k), v);
}

fn lookup_path<'a>(ctx: &'a Mapping, path: &[&str]) -> Option<&'a Value> {
    let mut cur = ctx.get(path[0])?;
    for part in &path[1..] {
        cur = match cur {
            Value::Mapping(m) => m.get(*part)?,
            _ => return None,
        };
    }
    Some(cur)
}

fn lookup<'a>(ctx: &'a Mapping, dotted: &str) -> Option<&'a Value> {
    let parts: Vec<&str> = dotted.split('.').collect();
    lookup_path(ctx, &parts)
}

fn key(k: &str) -> Value {
    Value::String(k.to_string())
}

/// `AIFIER_DATE` when set (tests), the local date otherwise.
fn today() -> String {
    std::env::var("AIFIER_DATE").unwrap_or_else(|_| local_date())
}

fn local_date() -> String {
    // Local date, as the Python renderer printed it; libc keeps the binary dependency-free.
    let mut tm: libc::tm = unsafe { std::mem::zeroed() };
    // SAFETY: time(NULL) only returns the clock; localtime_r writes into the tm we own.
    unsafe {
        let now = libc::time(std::ptr::null_mut());
        libc::localtime_r(&now, &mut tm);
    }
    format!(
        "{:04}-{:02}-{:02}",
        tm.tm_year + 1900,
        tm.tm_mon + 1,
        tm.tm_mday
    )
}

fn truthy(v: &Value) -> bool {
    match v {
        Value::Null => false,
        Value::Bool(b) => *b,
        Value::String(s) => !s.is_empty(),
        Value::Sequence(s) => !s.is_empty(),
        Value::Mapping(m) => !m.is_empty(),
        Value::Number(_) => true,
        Value::Tagged(_) => true,
    }
}

/// What a placeholder prints: strings as is, numbers and booleans as YAML writes them, a
/// sequence as its items joined with ", ".
fn scalar_to_string(v: &Value) -> String {
    match v {
        Value::String(s) => s.clone(),
        Value::Bool(b) => b.to_string(),
        Value::Number(n) => n.to_string(),
        Value::Null => String::new(),
        Value::Sequence(s) => s
            .iter()
            .map(scalar_to_string)
            .collect::<Vec<_>>()
            .join(", "),
        Value::Mapping(_) | Value::Tagged(_) => serde_yaml::to_string(v)
            .unwrap_or_default()
            .trim_end()
            .to_string(),
    }
}

pub fn render_text(text: &str, ctx: &Mapping) -> String {
    let text = render_blocks(text, ctx);
    let mut lines: Vec<String> = Vec::new();
    for line in text.split('\n') {
        if let Some(rendered) = render_line(line, ctx) {
            lines.push(rendered);
        }
    }
    lines.join("\n")
}

/// The earliest opening tag, `{{#` (false) or `{{^` (true, inverted).
fn find_open(s: &str) -> Option<(usize, bool)> {
    match (s.find("{{#"), s.find("{{^")) {
        (Some(a), Some(b)) if b < a => Some((b, true)),
        (Some(a), _) => Some((a, false)),
        (None, Some(b)) => Some((b, true)),
        (None, None) => None,
    }
}

/// `{{#name}}` … `{{/name}}` and `{{^name}}` … `{{/name}}`, the first closing tag wins; an
/// opening tag without its closing tag is left as is. A newline right after the opening tag and
/// right after the closing tag belongs to the tags, not to the body.
fn render_blocks(text: &str, ctx: &Mapping) -> String {
    let mut out = String::new();
    let mut rest = text;
    loop {
        let Some((open, inverted)) = find_open(rest) else {
            out.push_str(rest);
            return out;
        };
        let after_open = &rest[open + 3..];
        let Some(name_end) = after_open.find("}}") else {
            out.push_str(rest);
            return out;
        };
        let name = &after_open[..name_end];
        if !is_key(name) {
            out.push_str(&rest[..open + 3]);
            rest = after_open;
            continue;
        }
        let mut body_start = open + 3 + name_end + 2;
        if rest[body_start..].starts_with('\n') {
            body_start += 1;
        }
        let close_tag = format!("{{{{/{name}}}}}");
        let Some(close) = rest[body_start..].find(&close_tag) else {
            out.push_str(&rest[..body_start]);
            rest = &rest[body_start..];
            continue;
        };
        let body = &rest[body_start..body_start + close];
        let mut after = body_start + close + close_tag.len();
        if rest[after..].starts_with('\n') {
            after += 1;
        }
        out.push_str(&rest[..open]);
        if inverted {
            if !lookup(ctx, name).map(truthy).unwrap_or(false) {
                out.push_str(&render_text(body, ctx));
            }
        } else {
            out.push_str(&render_items(name, body, ctx));
        }
        rest = &rest[after..];
    }
}

fn render_items(name: &str, body: &str, ctx: &Mapping) -> String {
    let Some(items) = lookup(ctx, name) else {
        return String::new();
    };
    let mut out = String::new();
    match items {
        Value::Mapping(m) => {
            for (k, v) in m {
                let k_str = scalar_to_string(k);
                let mut item = ctx.clone();
                match v {
                    Value::Mapping(vm) => {
                        for (kk, vv) in vm {
                            item.insert(kk.clone(), vv.clone());
                        }
                    }
                    other => {
                        item.insert(key("value"), other.clone());
                    }
                }
                let dir = if k_str == "root" {
                    String::new()
                } else {
                    k_str.clone()
                };
                item.insert(key("dir"), Value::String(dir));
                item.insert(key("name"), Value::String(k_str.clone()));
                if name == "areas" || name == "subareas" {
                    let from = if k_str == "root" {
                        "the root".to_string()
                    } else {
                        format!("`{k_str}/`")
                    };
                    item.insert(key("from"), Value::String(from));
                    let g = match ctx.get("gates") {
                        Some(Value::Mapping(gm)) => {
                            gm.get(k).cloned().unwrap_or(Value::Mapping(Mapping::new()))
                        }
                        _ => Value::Mapping(Mapping::new()),
                    };
                    item.insert(key("gates"), g);
                }
                out.push_str(&render_text(body, &item));
            }
        }
        Value::Sequence(s) => {
            for v in s {
                let mut item = ctx.clone();
                match v {
                    Value::Mapping(vm) => {
                        for (kk, vv) in vm {
                            item.insert(kk.clone(), vv.clone());
                        }
                    }
                    other => {
                        item.insert(key("path"), other.clone());
                        item.insert(key("value"), other.clone());
                    }
                }
                out.push_str(&render_text(body, &item));
            }
        }
        scalar => {
            if truthy(scalar) {
                out.push_str(&render_text(body, ctx));
            }
        }
    }
    out
}

/// One line: every `{{key}}` substituted; `None` when a key resolved to null or false (the line
/// is dropped).
fn render_line(line: &str, ctx: &Mapping) -> Option<String> {
    let mut out = String::new();
    let mut rest = line;
    let mut drop = false;
    while let Some(open) = rest.find("{{") {
        let after = &rest[open + 2..];
        match after.find("}}") {
            Some(end) if is_key(&after[..end]) => {
                out.push_str(&rest[..open]);
                match lookup(ctx, &after[..end]) {
                    None => out.push_str(&rest[open..open + 2 + end + 2]),
                    Some(Value::Null) | Some(Value::Bool(false)) => drop = true,
                    Some(v) => out.push_str(&scalar_to_string(v)),
                }
                rest = &after[end + 2..];
            }
            _ => {
                out.push_str(&rest[..open + 2]);
                rest = after;
            }
        }
    }
    out.push_str(rest);
    if drop {
        None
    } else {
        Some(out)
    }
}

/// `[a-z_][a-z0-9_.]*`, the placeholder grammar.
fn is_key(s: &str) -> bool {
    let mut chars = s.chars();
    match chars.next() {
        Some(c) if c.is_ascii_lowercase() || c == '_' => {}
        _ => return false,
    }
    chars.all(|c| c.is_ascii_lowercase() || c.is_ascii_digit() || c == '_' || c == '.')
}

#[cfg(test)]
mod tests {
    use super::*;

    fn ctx(yaml: &str) -> Mapping {
        match serde_yaml::from_str::<Value>(yaml).unwrap() {
            Value::Mapping(m) => m,
            _ => panic!("mapping"),
        }
    }

    const MEMORY: &str =
        "memory:\n  rules: docs/learned-rules.md\n  decisions: docs/decisions\n  handoff: docs/handoff.md\n";

    /// Renders `yaml` with the real templates into a fresh scratch tree; returns the report and
    /// the target directory.
    fn run_with(name: &str, yaml: &str) -> (Result<String, String>, PathBuf) {
        let dir = std::env::temp_dir().join(format!("aifier-render-{}-{name}", std::process::id()));
        let _ = fs::remove_dir_all(&dir);
        let target = dir.join("target");
        fs::create_dir_all(&target).unwrap();
        let config = dir.join("aifier.yml");
        fs::write(&config, yaml).unwrap();
        let opts = Options {
            config,
            templates: PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("templates"),
            target: target.clone(),
            force: false,
            skills: None,
        };
        (run(&opts), target)
    }

    fn entries(dir: &Path) -> usize {
        fs::read_dir(dir).unwrap().count()
    }

    #[test]
    fn placeholders_null_drops_the_line_and_unknown_stays() {
        let c = ctx("a: x\nb: null\nl: [one, two]\n");
        assert_eq!(
            render_text("{{a}} {{l}}\n{{b}} gone\n{{zz}} kept", &c),
            "x one, two\n{{zz}} kept"
        );
    }

    #[test]
    fn false_gate_drops_the_line() {
        let c = ctx("gates: { lint: false, test: pytest, build: null }\n");
        assert_eq!(
            render_text("{{gates.lint}}\n{{gates.test}}\n{{gates.build}}\nend", &c),
            "pytest\nend"
        );
    }

    #[test]
    fn mapping_block_gives_dir_name_and_gates() {
        let c = ctx("areas:\n  root: { stack: docs }\n  api: { stack: py }\ngates:\n  api: { lint: ruff, test: null }\n");
        let t = "{{#areas}}[{{name}}|{{dir}}|{{stack}}|{{gates.lint}}]\n{{/areas}}end";
        assert_eq!(
            render_text(t, &c),
            "[root||docs|{{gates.lint}}]\n[api|api|py|ruff]\nend"
        );
    }

    #[test]
    fn areas_give_from_and_subareas_skip_root() {
        let mut c = ctx("areas:\n  root: { stack: docs }\n  api: { stack: py }\n");
        let areas = areas(&c).unwrap();
        add_area_views(&mut c, &areas);
        let t = "{{#areas}}From {{from}}:\n{{/areas}}{{#multi_area}}table\n{{/multi_area}}{{#subareas}}- {{dir}}\n{{/subareas}}{{^multi_area}}one\n{{/multi_area}}";
        assert_eq!(
            render_text(t, &c),
            "From the root:\nFrom `api/`:\ntable\n- api\n"
        );
    }

    #[test]
    fn single_area_renders_the_inverted_block_only() {
        let mut c = ctx("areas:\n  root: { stack: docs }\n");
        let areas = areas(&c).unwrap();
        add_area_views(&mut c, &areas);
        let t = "{{#multi_area}}table\n{{/multi_area}}{{#subareas}}- {{dir}}\n{{/subareas}}{{^multi_area}}one\n{{/multi_area}}end";
        assert_eq!(render_text(t, &c), "one\nend");
    }

    #[test]
    fn sequence_block_gives_path_and_empty_block_renders_nothing() {
        let c = ctx("p: [a/, b/]\nq: []\n");
        assert_eq!(
            render_text(
                "{{#p}}- {{path}}\n{{/p}}{{#q}}x{{/q}}{{#none}}y{{/none}}{{^q}}z{{/q}}",
                &c
            ),
            "- a/\n- b/\nz"
        );
    }

    #[test]
    fn open_tag_without_close_is_left_as_is() {
        let c = ctx("p: [a]\n");
        assert_eq!(render_text("{{#p}} open", &c), "{{#p}} open");
        assert_eq!(render_text("{{^p}} open", &c), "{{^p}} open");
    }

    #[test]
    fn engines_scalar_renders_claude_md() {
        let yaml = format!("project: p\nengines: claude-code\nareas:\n  root: {{ guide: AGENTS.md, stack: docs }}\n{MEMORY}");
        let (report, target) = run_with("engines-scalar", &yaml);
        let report = report.unwrap();
        assert!(report.contains("  - CLAUDE.md\n"), "{report}");
        assert!(target.join("CLAUDE.md").is_file());
    }

    #[test]
    fn areas_sequence_is_an_error() {
        let yaml = format!("project: p\nengines: [claude-code]\nareas: [api, web]\n{MEMORY}");
        let (report, target) = run_with("areas-sequence", &yaml);
        assert_eq!(report.unwrap_err(), AREAS_SHAPE);
        assert_eq!(entries(&target), 0, "nothing is written before the check");
    }

    #[test]
    fn memory_null_is_an_error() {
        let yaml = "project: p\nengines: [claude-code]\nareas:\n  root: { guide: AGENTS.md, stack: docs }\nmemory:\n  rules: null\n  decisions: docs/decisions\n  handoff: docs/handoff.md\n";
        let (report, target) = run_with("memory-null", yaml);
        assert_eq!(report.unwrap_err(), "memory.rules must be a path");
        assert_eq!(entries(&target), 0, "nothing is written before the check");
        let yaml = "project: p\nareas: {}\nmemory:\n  rules: docs/learned-rules.md\n  decisions: \"\"\n  handoff: docs/handoff.md\n";
        let (report, _) = run_with("memory-empty", yaml);
        assert_eq!(report.unwrap_err(), "memory.decisions must be a path");
    }

    #[test]
    fn date_is_iso() {
        let d = local_date();
        assert_eq!(d.len(), 10);
        assert_eq!(&d[4..5], "-");
        assert_eq!(&d[7..8], "-");
    }
}
