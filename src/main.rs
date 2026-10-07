//! aifier binary. V2 of the generator, one subcommand at a time; see ADR 0002.
//!
//! `aifier render <aifier.yml> <templates dir> <target repo> [--force] [--skills <dir>]`
//! renders the files `init` puts into a repository, byte for byte what the former Python
//! renderer produced. The daily collectors stay shell scripts: this binary runs once, at setup.

mod render;

use std::process::ExitCode;

const USAGE: &str =
    "usage: aifier render <aifier.yml> <templates dir> <target repo> [--force] [--skills <dir>]
       aifier --version

Placeholders written as two braces around a dotted key resolve against the configuration; a line
whose placeholder resolves to null is dropped; an unknown placeholder is left as is for the engine
to fill. Blocks between {{#list}} and {{/list}} repeat per item. Existing target files are skipped
unless --force. With --skills, the {{ }} of every SKILL.md in that directory are substituted in
place. AIFIER_DATE=YYYY-MM-DD overrides today's date (tests).";

fn main() -> ExitCode {
    let args: Vec<String> = std::env::args().skip(1).collect();
    match args.first().map(String::as_str) {
        Some("render") => match render::parse_args(&args[1..]) {
            Ok(opts) => match render::run(&opts) {
                Ok(report) => {
                    print!("{report}");
                    ExitCode::SUCCESS
                }
                Err(e) => {
                    eprintln!("aifier render: {e}");
                    ExitCode::from(1)
                }
            },
            Err(e) => {
                eprintln!("aifier render: {e}\n\n{USAGE}");
                ExitCode::from(2)
            }
        },
        Some("--version") | Some("-V") => {
            println!("aifier {}", env!("CARGO_PKG_VERSION"));
            ExitCode::SUCCESS
        }
        _ => {
            println!("{USAGE}");
            ExitCode::from(2)
        }
    }
}
