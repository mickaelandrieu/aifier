# aifier — passation de contexte (2026-10-07)

Ce fichier résume la session de cadrage menée depuis le dépôt RAISE. À lire avant toute action.

## Origine

RAISE (`Sfeir/raise-plateform-genai`, local `~/Projects/raise-plateform-genai`) embarque sous `.claude/`
un framework d'agents Claude Code appelé **RAISEBot** : 9 commandes orchestratrices, 17 agents,
30 skills, un catalogue de 21 rules apprises (`learned-rules`), une machine à états par labels
GitHub (`raisebot:todo / in-progress / done / partial / needs-input`, `raisebot:pr:ok / need-work / rejected`).
Il est explicitement aligné (PR #2000) sur le **SDLC augmenté** de SFEIR : 11 phases, 3 gates
humains (Define = intention, Plan = architecture, Ship = acceptation), 2 capitalisations
(Compound-1 pré-release, Compound-2 incident de prod), discipline de preuve.

Concepts SFEIR de référence : https://www.sfeir.com/concepts/sdlc-augmente/ ,
/concepts/context-engineering/ , /concepts/harness-engineering/ , /concepts/cdlc/ ,
/concepts/issue-based-development/ , /concepts/context-flywheel/ .

## Décisions prises

1. RAISEBot est mal nommé pour un projet public : "RAISE" = nom du client, "Bot" contredit les
   gates humains. On n'extrait pas RAISEBot en bloc.
2. Nouveau projet autonome **aifier** = (a) description de la méthode, (b) commandes d'analyse et
   de setup pour "AI-fier" le SDLC d'un projet existant, (c) socle portable installé dans le projet
   cible. Le cycle qualify / plan / fix / review reste dans RAISE comme workflow de référence,
   hors v1.
3. Portable sur **Claude Code, opencode et pi**. Faits vérifiés :
   - les skills `SKILL.md` (frontmatter `name` + `description` seulement) sont la seule unité
     portable aux trois hôtes ; opencode lit `.claude/skills/` et `.agents/skills/` ; pi suit le
     format agentskills.
   - le frontmatter `skills:` de préchargement des agents est Claude-only → remplacer par une
     consigne explicite "charge les skills X, Y" en tête du corps de l'agent.
   - agents : `.claude/agents/*.md` (tools/model/skills) vs `.opencode/agents/*.md`
     (mode/permission) ; pi n'a pas de sous-agents natifs → les orchestrateurs auto-suffisants
     (sans sous-agent) sont un atout.
   - commandes : skills Claude vs `.opencode/commands/*.md` (`agent:`, `subtask:`, `$ARGUMENTS`)
     vs prompt templates pi. Chemins pi exacts à confirmer sur une installation réelle.
   - hooks / settings.local.json : non portables, hors v1.
4. Dépôt : https://github.com/mickaelandrieu/aifier (privé, compte perso, transférable à Sfeir).

## Commandes prévues (v1)

| Commande | Phase | Rôle |
|---|---|---|
| assess | 0 Setup | audit de maturité : harnessability, contexte, workflow GitHub, gates ; note par phase, écarts priorisés ; lecture seule |
| init | 0 Setup | génère AGENTS.md, `aifier.yml` (repo, branches, préfixe labels, gates, langue), labels, templates d'issue deux audiences et de PR, installe skills + rules, propose les packs selon la stack |
| gates | 4 Verify | détecte/déclare lint, typecheck, tests, build ; vérifie qu'ils tournent ; preflight généralisé |
| context | CDLC | audit du contexte : context rot, découpage hot/warm/cold, charge par session |
| compound | 6 / 9 | capture une leçon en rule, modes pré-release et incident |
| status | toutes | position du projet sur les 11 phases |

Layout cible du dépôt : `method/` (une page par phase et concept), `skills/` (portables),
`packs/` (stack optionnels), `adapters/` (générateurs .claude / .opencode / pi à partir d'un
manifeste). Dans le projet cible : `AGENTS.md`, `aifier.yml`, `.agents/skills/`,
`.github/ISSUE_TEMPLATE/`, `PULL_REQUEST_TEMPLATE.md`, adaptateurs générés jamais édités à la main.

## Inventaire de ce qui se réutilise depuis RAISE (`.claude/` de raise-plateform-genai)

Reprendre sans réécriture (générique) :
- `raisebot/WORKFLOW.md` (machine à états, gates humains, health gates) → gabarit, préfixe de labels à paramétrer
- `raisebot/config.yml` → embryon de `aifier.yml`
- `skills/compound`, `skills/verification-evidence`, `skills/review-checklist`,
  `skills/adversarial-test-plan`, `skills/adr-template`, `skills/diataxis-rules`
- `skills/learned-rules` : RULE-002, 003, 012, 013, 014, 016, 017, 018, 019 (processus git, preuve, PR)
  → catalogue de départ ; RULE-004 et 020 génériques avec exemples RAISE à neutraliser
- `agents/plan-orchestrator.md` (86 lignes) → modèle de taille pour tout orchestrateur
- format d'issue deux audiences de `agents/qualify-orchestrator.md` → template d'issue

Packs de stack (plus tard, pack "python-hexagonal + react") : hexagonal-rules, di-rules,
python-style, react-patterns, i18n-conventions, testid-discipline, opquast-rgaa,
playwright-patterns, front-test-cleanliness, agents backend/frontend-developer, e2e-author/validator,
RULE-001/005/006/007/009.

Reste dans RAISE : fix-orchestrator (504 l.) et self-review-orchestrator (409 l.) à réécrire
plutôt qu'à déplacer, env-preflight, pr-body (format FR 7 sections), capture-app-screenshot,
browser-test-auth, types rag-pipeline / extension-system, RULE-008/010/011/015/021,
settings.local.json, presentation.html.

## Prochaine étape convenue

Rédiger la **grille d'évaluation de `assess`**, phase par phase (critères, preuves attendues,
notation), car tout le reste en découle. Test de réalité : `assess` doit reconnaître RAISE comme
projet avancé, sinon la grille est fausse.

## Conventions de travail de l'utilisateur (héritées)

- Agir sans demander confirmation, exécuter soi-même les commandes, rapporter les résultats.
- Jamais de push force ; commits conventionnels sur une ligne.
- Pas de commentaires explicatifs dans le code ; explications dans README/docs.
- Chaînes de code et guidance de prompt en anglais ; échanges et docs de méthode en français.
- Livrables rédigés : version finale prête à l'emploi, itérée deux fois.
