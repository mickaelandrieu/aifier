# Grille d'évaluation de `assess`

`assess` mesure la maturité d'un dépôt existant vis-à-vis du SDLC augmenté, phase par phase. Il est
en lecture seule : il lit le dépôt, son historique git et, si `gh` est authentifié, les métadonnées
GitHub (labels, templates, protections de branche, checks). Il produit un rapport markdown avec une
note par critère, une note par phase, un niveau global et une liste d'écarts priorisés que `init`
et `gates` savent combler.

## Principes

- **Chaque critère se prouve mécaniquement.** Un critère sans sonde (fichier, commande, requête API)
  n'entre pas dans la grille. La colonne « Preuve » dit exactement ce que `assess` cherche.
- **Les gates humains se notent à l'envers.** Pour Define, Plan et Ship, le maximum n'est pas
  « automatisé » mais « tenu par un humain et impossible à contourner ». Un dépôt où un agent merge
  seul perd des points, il n'en gagne pas.
- **Déclaré n'est pas tenu.** Un gate documenté dans le README mais absent de la CI vaut 2, pas 3.
  Les niveaux 3 exigent une exécution observable (job CI, hook, check requis).
- **La grille sert avant et après.** La même grille, rejouée après `init` et quelques cycles, doit
  montrer l'écart. C'est l'argument de la méthode.

## Échelle

| Niveau | Nom | Signification |
|---|---|---|
| 0 | Absent | rien dans le dépôt ni sur GitHub |
| 1 | Ad hoc | existe par endroits, dépend des personnes, non documenté |
| 2 | Formalisé | documenté ou présent de façon reproductible, mais non vérifié |
| 3 | Tenu | automatisé, vérifié en CI ou par un contrôle requis, avec preuve |

Note de phase = moyenne des critères de la phase. Note globale = moyenne pondérée des phases
(poids ci-dessous). Niveau global :

| Note globale | Niveau | Lecture |
|---|---|---|
| < 1,0 | Classique | les agents n'ont ni contexte ni garde-fous |
| 1,0 à 1,9 | Assisté | l'IA aide des individus, le projet n'apprend pas |
| 2,0 à 2,5 | Augmenté | les gates existent, l'IA exécute entre eux |
| > 2,5 | Compound | chaque cycle améliore le suivant |

## Axes transverses

Deux axes traversent toutes les phases. Ils sont notés à part et entrent dans la note globale.

### H. Harnessability (poids 2)

Capacité de la base de code à être harnachée : plus le code est contraint, plus les sensors
rattrapent l'agent.

| # | Critère | Preuve | 0 | 3 |
|---|---|---|---|---|
| H1 | Typage statique | config du type-checker (`mypy.ini`, `pyproject [tool.mypy]`, `tsconfig strict`) et job CI qui l'exécute | langage dynamique sans vérificateur | strict, exécuté en CI, bloquant |
| H2 | Linter et formateur | config (`ruff`, `eslint`, `biome`, `prettier`…) et exécution CI ou hook | aucun | exécuté en CI et en pre-commit |
| H3 | Frontières de modules | structure de dossiers nommée (layers, bounded contexts) et règle d'import outillée (`import-linter`, `dependency-cruiser`, `eslint-boundaries`) | monolithe plat | frontières déclarées et vérifiées |
| H4 | Tests exécutables en une commande | commande unique documentée (Makefile, script `test`) qui tourne sans setup manuel | tests absents ou setup oral | une commande, verte au premier run |
| H5 | Reproductibilité de l'environnement | lockfile, version de runtime épinglée, conteneur ou script de setup | « ça marche chez moi » | setup scripté et testé en CI |
| H6 | Templates de topologie | exemples canoniques ou générateurs pour les motifs récurrents (un endpoint, un composant, une migration) | aucun | documentés et référencés depuis AGENTS.md |

### C. Contexte (poids 2)

Ce que l'agent sait du projet avant d'agir, et la fraîcheur de ce savoir.

| # | Critère | Preuve | 0 | 3 |
|---|---|---|---|---|
| C1 | Constitution (hot memory) | `AGENTS.md` ou `CLAUDE.md` à la racine, moins de 150 lignes, qui renvoie vers les guides par zone | absent | présent, court, en carte vers les guides |
| C2 | Guides par zone (warm) | `AGENTS.md` ou équivalent par sous-projet, ou skills chargeables à la demande | tout dans un seul fichier ou rien | un guide par zone, référencé depuis la constitution |
| C3 | Référence consultable (cold) | docs structurées (Diátaxis ou équivalent), ADR, diagrammes, index ou graphe de code | README seul | docs structurées et index navigable |
| C4 | Fraîcheur du contexte | date du dernier commit sur AGENTS.md et docs vs date des derniers changements de code dans la zone décrite ; chemins cités dans les docs qui existent encore | docs orphelines, chemins morts | docs modifiées dans les mêmes PR que le code, zéro chemin mort |
| C5 | Charge par session | taille cumulée de ce qui est chargé à chaque session (constitution + fichiers inclus) | > 2 000 lignes chargées ou 0 | < 500 lignes chargées, le reste à la demande |
| C6 | Conventions explicites | style, nommage, structure de commit, langue, décrits et outillés | implicites | décrits et vérifiés (commitlint, lint de style) |

## Phases

### Phase 0 — Setup (poids 2)

L'outillage du cycle lui-même.

| # | Critère | Preuve | 0 | 3 |
|---|---|---|---|---|
| S1 | Configuration du cycle | fichier de config du workflow (`aifier.yml` ou équivalent : repo, branches cibles, labels, commandes de gate) | aucune | présente, lue par les commandes |
| S2 | Skills de processus installés | dossier `.agents/skills/` ou `.claude/skills/` avec au moins preuve, revue, compound | aucun | les quatre présents et à jour |
| S3 | Catalogue de rules | fichier de rules apprises avec id, sévérité, détection | aucun | catalogue avec au moins une rule issue d'une revue réelle |
| S4 | Adaptateurs d'hôte | `.claude/`, `.opencode/` ou templates pi générés, cohérents entre eux | aucun ou divergents | générés, identiques en contenu |
| S5 | Hygiène des secrets | `.env` git-ignorés, `.env.example` présent, scanner de secrets en CI | secrets commités | scanner bloquant en CI |

### Phase 1 — Define, gate humain (poids 3)

L'intention produit devient un contrat lisible par un non-développeur.

| # | Critère | Preuve | 0 | 3 |
|---|---|---|---|---|
| D1 | Template d'issue | `.github/ISSUE_TEMPLATE/` avec problème, impact, critères d'acceptation | aucun | template à deux audiences : haut lisible PO, bloc technique replié |
| D2 | Critères d'acceptation comportementaux | échantillon des 20 dernières issues fermées : proportion avec critères vérifiables | < 20 % | > 80 % |
| D3 | État de qualification | label ou champ distinguant une issue brute d'une issue qualifiée | aucun | label d'état, machine à états documentée |
| D4 | Le gate est humain | la qualification ne ferme ni ne planifie une issue sans validation humaine ; aucun automate ne pose l'état « prêt » seul | un bot qualifie et enchaîne | validation humaine tracée (commentaire, assignation, label posé par un humain) |
| D5 | Lien issue → changement | proportion des PR des 90 derniers jours référençant une issue | < 20 % | > 90 % |

### Phase 2 — Plan, gate humain (poids 3)

L'architecture est arbitrée avant le code.

| # | Critère | Preuve | 0 | 3 |
|---|---|---|---|---|
| P1 | ADR | dossier d'ADR avec gabarit, au moins un ADR des 6 derniers mois | aucun | gabarit, index, ADR récents |
| P2 | Plan avant build sur les changements structurants | pour les PR touchant plusieurs couches ou > N fichiers, trace d'un plan (commentaire d'issue, ADR, doc) antérieur au premier commit | jamais | systématique, avec alternatives comparées |
| P3 | Le gate est humain | le choix d'approche est tracé comme humain ; un agent qui propose s'arrête avant d'implémenter | un agent choisit et code | choix humain tracé sur l'issue |
| P4 | Capitalisation consultée au plan | les rules et ADR sont cités ou chargés lors de la planification | jamais | le plan référence les rules applicables |

### Phase 3 — Build (poids 2)

| # | Critère | Preuve | 0 | 3 |
|---|---|---|---|---|
| B1 | Branches et conventions de commit | règle de nommage, conventional commits, protection de la branche cible | commits directs sur main | protection active, convention vérifiée |
| B2 | Tranches petites | taille médiane des PR fusionnées sur 90 jours (fichiers, lignes) | médiane > 1 000 lignes | médiane < 300 lignes |
| B3 | Tests livrés avec le changement | proportion des PR touchant du code qui touchent aussi des tests | < 30 % | > 85 % |
| B4 | Instructions par type de changement | guides spécifiques (bug API, UI, migration, sécurité…) chargés selon le type | aucun | un guide par type, référencé par l'orchestrateur ou la constitution |
| B5 | Point de reprise | mécanisme de checkpoint pour un travail agent interrompu | aucun | checkpoints persistés, reprise documentée |

### Phase 4 — Verify (poids 3)

| # | Critère | Preuve | 0 | 3 |
|---|---|---|---|---|
| V1 | Gates déclarés | lint, typecheck, tests, build listés en un seul endroit (config, Makefile) | dispersés ou oraux | déclarés dans la config du cycle |
| V2 | Gates exécutés en CI | chaque gate déclaré a un job CI qui le fait tourner | aucun | tous, et marqués checks requis |
| V3 | Parité locale / CI | la même commande tourne en local et en CI ; preflight d'environnement documenté | commandes différentes | identiques, preflight scripté |
| V4 | Couverture mesurée | rapport de couverture produit en CI, seuil ou tendance suivie | aucune | seuil bloquant ou tendance publiée |
| V5 | Discipline de preuve | les PR citent la sortie réelle des gates, pas une affirmation ; template de PR avec section validation | « tests OK » sans trace | sortie capturée exigée par le template et la revue |
| V6 | Tests de bout en bout | suite E2E ou d'intégration exécutée en CI sur les parcours critiques | aucune | en CI, isolée, avec nettoyage |

### Phase 5 — Review (poids 2)

| # | Critère | Preuve | 0 | 3 |
|---|---|---|---|---|
| R1 | Revue obligatoire | protection de branche exigeant au moins une approbation | aucune | approbation requise, auteur exclu |
| R2 | Checklist de revue | checklist versionnée (architecture, sécurité, tests, cohérence) | aucune | versionnée et appliquée (visible dans les commentaires) |
| R3 | Revue multi-angle consolidée | plusieurs lectures (code, architecture, sécurité, accessibilité si UI) fusionnées en un verdict | une seule lecture | plusieurs lectures et un verdict unique tracé |
| R4 | Indépendance du verdict | celui qui code ne se décerne pas l'état « prêt » ; état de PR posé par un relecteur distinct | auto-validation | label ou check posé par un tiers |
| R5 | Health gate | une PR en conflit ou avec un check rouge ne peut pas être marquée prête | ignoré | règle écrite et appliquée |

### Phase 6 — Compound-1, capitalisation pré-release (poids 3)

| # | Critère | Preuve | 0 | 3 |
|---|---|---|---|---|
| K1 | Mécanisme de capture | commande ou procédure qui transforme une leçon de revue en rule | aucun | commande dédiée, documentée |
| K2 | Rules réellement produites | nombre de rules datées des 6 derniers mois, avec leur PR d'origine | 0 | ≥ 1 par mois d'activité |
| K3 | Rules injectées | les rules sont chargées par les agents de build et de revue, pas seulement archivées | archivées | chargées systématiquement |
| K4 | Rules détectables | chaque rule a une méthode de détection (grep, lint, heuristique) | prose seule | détection écrite, idéalement outillée |
| K5 | Bug vu deux fois | échantillon de bugs rouverts ou récurrents : proportion couverte par une rule | aucune | chaque récurrence a produit une rule |

### Phase 7 — Ship, gate humain (poids 2)

| # | Critère | Preuve | 0 | 3 |
|---|---|---|---|---|
| L1 | Merge humain | protection de branche interdisant le merge automatique par un bot ; historique des merges | bots mergent | tous les merges sont humains |
| L2 | Changelog et versionnage | changelog tenu, tags ou releases | aucun | changelog alimenté par PR, releases taguées |
| L3 | Migrations sûres | migrations idempotentes, versionnées, rejouées en CI | aucune discipline | idempotence testée en CI |
| L4 | Pipeline de livraison | déploiement scripté, déclenché par merge ou tag | manuel | scripté, avec rollback documenté |

### Phase 8 — Ops (poids 1)

Souvent hors du dépôt applicatif. `assess` note ce qui est visible depuis le dépôt et signale le reste comme « non observable ».

| # | Critère | Preuve | 0 | 3 |
|---|---|---|---|---|
| O1 | Observabilité | logs structurés, traces, métriques, erreurs remontées avec `exc_info` ou équivalent | prints | structurés, corrélés, dashboards référencés |
| O2 | Déploiement progressif | feature flags, canary, pourcentage de trafic | big bang | progressif documenté |
| O3 | Boucle incident → dépôt | les incidents de prod produisent des issues dans le dépôt | aucune trace | issues étiquetées incident, liées aux PR correctives |

### Phase 9 — Compound-2, capitalisation runtime (poids 2)

| # | Critère | Preuve | 0 | 3 |
|---|---|---|---|---|
| K6 | Postmortems | gabarit et exemples de postmortem versionnés | aucun | gabarit, exemples récents |
| K7 | Incident → rule | proportion des incidents des 12 derniers mois ayant produit une rule ou un gate | 0 | > 50 % |
| K8 | Gate ajouté après incident | preuve qu'un gate CI ou une rule de détection est né d'un incident | aucune | au moins un, tracé |

### Phase 10 — Deprecation (poids 1)

| # | Critère | Preuve | 0 | 3 |
|---|---|---|---|---|
| X1 | Code mort détecté | outil de détection (vulture, knip, ts-prune) ou revue périodique | aucun | outillé en CI ou périodique tracé |
| X2 | Retrait documenté | procédure de dépréciation (flag, période d'observation, suppression) | aucune | procédure et exemples |
| X3 | Dépendances tenues | scanner de vulnérabilités, mises à jour tracées | aucun | scanner bloquant, bumps réguliers |

## Pondération récapitulative

| Axe ou phase | Poids | Pourquoi |
|---|---|---|
| H Harnessability | 2 | conditionne l'efficacité de tout le reste |
| C Contexte | 2 | conditionne la qualité de tout ce que produit l'agent |
| 0 Setup | 2 | c'est ce que `init` installe |
| 1 Define | 3 | premier gate humain |
| 2 Plan | 3 | deuxième gate humain |
| 3 Build | 2 | |
| 4 Verify | 3 | sans preuve, rien d'autre ne tient |
| 5 Review | 2 | |
| 6 Compound-1 | 3 | ce qui distingue Augmenté de Compound |
| 7 Ship | 2 | troisième gate humain |
| 8 Ops | 1 | souvent non observable depuis le dépôt |
| 9 Compound-2 | 2 | |
| 10 Deprecation | 1 | |

## Format du rapport

```
# aifier assess — <repo> — <date>

Niveau global : Augmenté (2,3 / 3)

| Phase | Note | Points forts | Écarts |
|---|---|---|---|
| ... | ... | ... | ... |

## Écarts priorisés
1. <critère> : <constat>, <preuve>, <ce que init ou gates propose>
...

## Non observable depuis le dépôt
- O2, O3 : vérifier dans <outil de prod>

## Détail par critère
<tableau complet avec la preuve trouvée ou l'absence constatée>
```

Priorisation des écarts : d'abord les gates humains manquants ou contournés (D4, P3, R4, L1),
puis les critères à poids 3 notés 0 ou 1, puis le reste par poids décroissant. Un écart que
`init` ou `gates` sait combler est marqué comme tel.

## Sondes communes

Les commandes que `assess` exécute, pour que le résultat soit reproductible d'un hôte à l'autre :

- fichiers : `AGENTS.md`, `CLAUDE.md`, `.github/`, `docs/`, `adr/` ou `docs/adr/`, `CHANGELOG.md`,
  `Makefile`, `package.json`, `pyproject.toml`, lockfiles, configs de lint et typecheck, dossiers
  de skills et d'agents
- git : `git log --since=90.days` pour PR, tailles, co-modification code/tests, dates des docs
- GitHub via `gh` : labels, templates, protections de branche, checks requis, 20 dernières
  issues fermées, PR fusionnées sur 90 jours, auteur des merges
- CI : fichiers de pipeline (`.github/workflows`, `cloudbuild.yaml`, `.gitlab-ci.yml`) parsés pour
  retrouver chaque gate déclaré

Sans `gh` authentifié, les critères D2, D3, D5, R1, R4, L1 sont notés « non observable » et la
note de phase est calculée sur les critères restants, en le signalant.

## Calibration attendue sur RAISE

Hypothèse à confirmer au premier run réel. Si `assess` donne un niveau inférieur à Augmenté sur
RAISE, c'est la grille ou les sondes qu'il faut corriger, pas RAISE.

| Axe ou phase | Attendu | Justification |
|---|---|---|
| H | 2,5 | typage et lint en CI, hexagonal outillé, uv et Docker ; templates de topologie partiels |
| C | 2,7 | AGENTS.md en carte, guides par zone, Diátaxis, graphify ; fraîcheur à mesurer |
| 0 Setup | 2,2 | config.yml minimal, skills et rules présents, adaptateurs Claude seulement |
| 1 Define | 2,6 | qualify à deux audiences, labels, gate humain documenté |
| 2 Plan | 2,3 | ADR présents, /plan s'arrête pour l'humain, rules consultées |
| 3 Build | 2,4 | conventions et protections, checkpoints, types par bug ; taille de PR à mesurer |
| 4 Verify | 2,8 | gates en CI, preflight, RULE-016, E2E Playwright |
| 5 Review | 2,6 | checklist, revues multi-angle, pr:ok par un tiers, health gate |
| 6 Compound-1 | 2,8 | 21 rules datées, injectées, avec détection |
| 7 Ship | 2,5 | merges humains, changelog, migrations idempotentes |
| 8 Ops | 1,5 | observabilité présente, rollout dans un autre dépôt |
| 9 Compound-2 | 1,8 | mode incident de compound existe, peu d'exemples tracés |
| 10 Deprecation | 1,5 | Trivy bloquant, pas de détection de code mort |
| **Global** | **≈ 2,4, Augmenté** | proche de Compound, freiné par Ops, Compound-2 et Deprecation |

## Calibration attendue sur un projet classique : smart-chatbot

`loveOSS/smart-chatbot` (local `~/Projects/smart-chatbot`) sert de projet témoin non aifié : FastAPI +
Streamlit, 89 commits, un workflow CI de tests, pre-commit, un CLAUDE.md de 11 Ko, pas de template
d'issue, pas d'AGENTS.md en carte, pas de rules. Il doit sortir **Assisté** (entre 1,0 et 1,5) :
Classique serait trop sévère au vu du CLAUDE.md et de la CI, Augmenté serait la preuve que la
grille note la présence et pas la tenue. Écarts attendus en tête : D1, D3, S1 à S4, K1 à K4, V5.
