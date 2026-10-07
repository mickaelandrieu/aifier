# packs/

Optional stack packs. A pack bundles the skills, rules and agent roles that only make sense for a
given stack: hexagonal Python, React with i18n, Playwright end-to-end, and so on. `init` proposes the
packs that match what it detects in the repository; nothing in a pack is installed by default.

A pack is a directory with a `pack.yml` manifest and the same `SKILL.md` layout as `skills/`.
