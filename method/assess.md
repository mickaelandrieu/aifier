# Grille d'évaluation de `assess`

`assess` est un audit de maturité en lecture seule. Il parcourt un dépôt existant, phase par phase du
[SDLC augmenté](phases.md), et répond à une seule question : **que manque-t-il pour que des agents
puissent travailler ici sous gates humains, avec preuve ?** Il ne modifie rien ; il produit un profil
par phase et une liste d'écarts priorisés, chacun relié à la commande aifier qui le comble.

## Principes de notation

Chaque critère reçoit une note de 0 à 3. La note dit si la pratique existe et si elle est **prouvée**,
pas si elle est élégante.

| Note | Niveau | Ce que l'auditeur a constaté |
|---|---|---|
| 0 | absent | Aucune trace dans le dépôt ni dans le forge |
| 1 | ad hoc | Des traces (commits, issues, fichiers épars) mais rien d'écrit ni d'outillé |
| 2 | déclaré | Écrit et outillé (fichier, template, config, commande) mais sans preuve qu'il s'applique |
| 3 | gouverné | Déclaré **et** vérifié par une preuve récente : exécution en CI, échantillon d'issues ou de PR conformes, protection de branche active |

Règles d'agrégation :

- **Note de phase** = moyenne des critères évalués, arrondie au dixième.
- Un critère marqué **bloquant** à 0 plafonne la phase à 1. Un gate sans arrêt humain n'est pas un
  gate à moitié ; c'est un gate absent.
- Un critère que l'auditeur ne peut pas vérifier (forge inaccessible, `gh` refusé, pas de production
  visible) est marqué **non évalué** et exclu de la moyenne. Il n'est jamais compté 0.
- Les critères notés 3 exigent une preuve datée de moins de **90 jours** (dernier run de CI, dernière
  issue, dernier commit du fichier). Au-delà, la note redescend à 2 : une pratique qui ne s'exerce plus
  est déclarée, pas gouvernée.
- Un dépôt **dormant** (aucun commit depuis 90 jours) se signale une fois, dans les risques, avec la
  date du dernier commit. Le plafond à 2 s'y applique aux critères qui exigent une pratique récente
  (échantillons d'issues et de PR, runs de CI), pas aux artefacts déclarés dont la présence suffit au
  niveau visé.

Niveaux de phase : **absent** (< 1), **émergent** (1 à 1,9), **outillé** (2 à 2,7), **gouverné** (≥ 2,8).

Conventions qui suppriment les cas limites :

- les seuils en pourcentage sont **inclusifs** : « 70 % » se lit « 14 sur 20 passent » ;
- la **protection de branche** se juge sur les branches qui ont reçu les PR de l'échantillon, pas
  seulement sur la branche par défaut ; si celle-ci est protégée mais pas la branche qui reçoit
  l'essentiel des fusions, les critères 3.1, 5.1, 5.4, 5.5 et 7.1 sont plafonnés à 2 et le fait
  devient un **risque** ;
- une revue menée par un agent que l'auteur de la PR a lancé n'est **pas** une revue indépendante ;
- un **cadre sans rien de déclaré** (enum de flags vide, seuils de couverture jamais exécutés en CI,
  check requis dont le nom ne correspond plus à rien) vaut 1, pas 2 ;
- une constitution qui **recopie les règles d'un skill** au lieu d'y renvoyer est du contexte
  dupliqué : 0.3 plafonné à 2 ;
- la structure d'une issue compte qu'elle vienne du template de la forge ou d'un agent de
  qualification qui l'a réécrite : on note le contrat écrit, pas son origine.

Chaque critère porte un **axe** qui sert à la seconde lecture du rapport :

- **H** harnessability : la base de code se laisse-t-elle harnacher (typage, frontières, outillage) ?
- **C** contexte : ce que les agents lisent est-il écrit, étagé, à jour ?
- **W** workflow : les issues, branches, labels et PR portent-ils le cycle et ses gates ?
- **G** gates de vérification : lint, typage, tests, build, revue, avec preuve.

## Sources de preuve

`assess` ne lit que des choses vérifiables :

- l'arbre du dépôt et son historique (`git log`, `git show`), sans exécuter le code du projet ;
- les fichiers de configuration des hôtes agents : `AGENTS.md`, `CLAUDE.md`, `.cursorrules`,
  `GEMINI.md`, `.agents/skills/`, `.claude/`, `.opencode/`, `.github/copilot-instructions.md` ;
- les fichiers de forge : `.github/`, `.gitlab/`, `.gitlab-ci.yml`, `cloudbuild.yaml`,
  `CODEOWNERS`, `CONTRIBUTING.md`, `CHANGELOG.md`, `docs/` ;
- la forge elle-même quand elle est accessible (`gh` ou `glab`) : protections de branche, labels,
  échantillon des 20 dernières issues et des 20 dernières PR fusionnées, derniers runs de CI.

Les commandes de gates ne sont pas lancées par `assess` ; c'est le rôle de `gates`. `assess` constate
qu'elles sont déclarées et qu'une CI les a exécutées.

---

## Phase 0 · Setup

Le cadre dans lequel les agents travaillent. Tout le reste s'appuie dessus.

| # | Critère | Axe | Preuves attendues | 0 → 3 |
|---|---|---|---|---|
| 0.1 | **Constitution des agents** (bloquant) | C | Un fichier racine lu par les hôtes (`AGENTS.md`, à défaut `CLAUDE.md` ou équivalent) | 0 aucun · 1 un fichier généré non maintenu ou > 300 lignes de prose · 2 un fichier court qui joue le rôle de carte et renvoie vers des guides par zone · 3 idem, et chaque fichier référencé existe et a été modifié depuis moins de 90 jours |
| 0.2 | **Guides par zone** | C | Un guide dans chaque sous-projet (`back/AGENTS.md`, `front/AGENTS.md`, `e2e/AGENTS.md`...) | 0 aucun · 1 un seul guide pour un monorepo multi-stack · 2 un guide par zone · 3 chaque guide énonce des règles vérifiables, pas une description |
| 0.3 | **Connaissance packagée en skills** | C | Dossiers `SKILL.md` (`.agents/skills/`, `.claude/skills/`) avec `name` et `description` | 0 aucun · 1 des prompts épars · 2 des skills nommés et décrits · 3 les skills sont chargés par des agents ou commandes identifiables, aucun doublon de contenu entre skills et constitution |
| 0.4 | **Moteurs agents détectés** (informatif, hors note) | C | Dossiers de moteurs présents, suivis ou ignorés par git, contenu générique ou spécifique au projet, copies de travail périmées | Rapporté tel quel : la portabilité est un choix d'outillage, pas un niveau de maturité du cycle |
| 0.5 | **Harnessability du code** | H | Typage activé (`tsconfig` `strict`, `mypy`/`pyright` configurés, équivalents), formatter et linter configurés, frontières de modules (packages, workspaces) | 0 rien · 1 linter seul · 2 typage et linter configurés · 3 typage strict exécuté en CI et frontières explicites |
| 0.6 | **Amorçage de l'environnement** | H | `Makefile`, `justfile`, `scripts/`, `.env.example`, `devcontainer.json`, section d'installation du README | 0 rien · 1 un README narratif · 2 une commande d'amorçage documentée · 3 la CI invoque le même script ou la même cible, y compris dans une image de conteneur |
| 0.8 | **Aucun secret dans le dépôt** (bloquant) | H | Fichiers suivis par git sans clé d'API, mot de passe, jeton ou secret de session ; `.env*` ignorés ; scanner de secrets configuré | 0 un secret réel suivi par git · 1 des valeurs de démonstration en dur dans la configuration (compose, CI) sans scanner · 2 rien de suivi, `.env.example` seul porte les noms · 3 idem, et un scanner bloque en CI ou en hook |
| 0.7 | **Périmètre de délégation** | W | Un texte qui dit ce que les agents ne font pas (fusion, intention, architecture, zones critiques) | 0 rien · 2 écrit dans la constitution ou `CONTRIBUTING.md` · 3 les instructions d'agents s'arrêtent explicitement aux gates |

## Phase 1 · Define — gate humain d'intention

Une idée devient un contrat lisible par quelqu'un qui n'ouvrira jamais le code.

| # | Critère | Axe | Preuves attendues | 0 → 3 |
|---|---|---|---|---|
| 1.1 | **Templates d'issue** (bloquant) | W | `.github/ISSUE_TEMPLATE/*.yml` ou `.gitlab/issue_templates/` | 0 aucun · 1 un template libre · 2 des champs problème, comportement attendu, critères d'acceptation · 3 les 20 dernières issues suivent la structure à 70 % ou plus |
| 1.2 | **Deux audiences** | W | Une partie haute en langage métier (problème, impact, critères observables) et une partie technique repliée | 0 tout mélangé · 2 la séparation est dans le template · 3 un échantillon d'issues la respecte |
| 1.3 | **Critères d'acceptation observables** | W | Formulés « quand X, alors Y », vérifiables sans lire le code | 0 absents · 1 présents mais techniques · 2 présents et comportementaux dans le template · 3 présents dans 70 % ou plus des issues fermées récentes |
| 1.4 | **Qualification outillée** | W | Une commande ou un skill qui réécrit une issue brute dans le contrat, et un état « qualifiée » (label) ; aifier rend `qualify` | 0 rien · 2 la commande existe · 3 l'état est posé sur les issues récentes |
| 1.5 | **Arrêt humain sur l'intention** | W | L'issue qualifiée attend une validation humaine avant plan ou build | 0 l'agent enchaîne · 2 l'arrêt est écrit · 3 l'état du workflow (label) matérialise l'attente |

## Phase 2 · Plan — gate humain d'architecture

Plusieurs approches, un humain choisit, avant tout code.

| # | Critère | Axe | Preuves attendues | 0 → 3 |
|---|---|---|---|---|
| 2.1 | **Décisions d'architecture consignées** | C | `docs/adr/`, `docs/decisions/`, format ADR ou équivalent | 0 aucune · 1 une page d'architecture narrative · 2 des ADR datés · 3 au moins un ADR depuis moins de 90 jours et un template d'ADR |
| 2.2 | **Approches alternatives** | W | Une commande ou un skill qui produit deux ou trois approches distinctes avec compromis et recommandation ; aifier rend `plan` | 0 rien · 1 des plans dans `docs/plans/` sans alternatives · 2 la commande existe et exige des approches qui divergent en stratégie · 3 des issues ou plans récents montrent l'arbitrage |
| 2.3 | **Arrêt au gate** (bloquant) | W | Le planificateur ne construit jamais ; un humain choisit (commentaire, label, champ « approche retenue ») ; `build` exige ce choix | 0 l'agent choisit et construit · 2 l'arrêt est écrit dans les instructions · 3 la trace de l'arbitrage humain est visible sur les issues récentes |
| 2.4 | **Règles apprises consultées au plan** | C | Le planificateur charge le catalogue de règles apprises | 0 pas de catalogue · 2 le catalogue est référencé par le planificateur · 3 un plan récent cite une règle |
| 2.5 | **Ancrage dans le code** | C | Les claims du plan sont tagués vérifiés (`fichier:ligne`) ou inférés | 0 rien · 2 la convention est écrite · 3 appliquée dans un plan récent |

## Phase 3 · Build

Une tranche à la fois, sous conventions écrites.

| # | Critère | Axe | Preuves attendues | 0 → 3 |
|---|---|---|---|---|
| 3.1 | **Branches et base protégée** | W | Convention de branche écrite, protection des branches qui reçoivent les PR de l'échantillon (`gh api repos/:owner/:repo/branches/<branche>/protection`) | 0 commits directs sur la base · 1 convention orale · 2 convention écrite · 3 protection active sur ces branches : ni push direct, ni push force, administrateurs non exemptés |
| 3.2 | **Commits conventionnels** | W | `commitlint`, hook, ou ratio sur les 100 derniers commits | 0 < 30 % · 1 < 70 % · 2 ≥ 70 % · 3 ≥ 90 % ou vérifié par hook ou CI |
| 3.3 | **Conventions de code écrites** | C | Guides de style par langage, configuration de linter et formatter, `CODEOWNERS` | 0 rien · 1 linter seul · 2 guide écrit et config · 3 guide chargé par les agents de build |
| 3.4 | **Catalogue de règles apprises chargé au build** | C | Agents ou skills de build qui chargent le catalogue | 0 pas de catalogue · 2 chargé · 3 chargé et le catalogue a bougé depuis moins de 90 jours |
| 3.5 | **Les tests font partie du changement** | G | Ratio des 20 dernières PR fusionnées qui touchent des fichiers de test | 0 < 20 % · 1 < 50 % · 2 ≥ 50 % · 3 ≥ 70 % et la règle est écrite |
| 3.6 | **Une tranche par PR** | W | Taille médiane des 20 dernières PR fusionnées (fichiers changés), issues liées par référence API **ou** mot-clé dans le corps (la forge ne résout pas `Closes #N` hors branche par défaut) | 0 PR fourre-tout sans issue · 1 PR liées mais larges · 2 médiane sous 20 fichiers et issue liée · 3 idem avec `Closes #N` ou équivalent systématique |

## Phase 4 · Verify

Les gates existent, tournent, et laissent une preuve.

| # | Critère | Axe | Preuves attendues | 0 → 3 |
|---|---|---|---|---|
| 4.1 | **Gates déclarés** (bloquant) | G | Commandes de lint, typage, tests, build découvrables (`package.json` scripts, `pyproject.toml`, `Makefile`, `justfile`) | 0 aucune · 1 certaines · 2 les quatre familles présentes dans chaque sous-projet · 3 les quatre regroupées sous une commande unique documentée |
| 4.2 | **Gates exécutés en CI** | G | `.github/workflows/`, `.gitlab-ci.yml`, `cloudbuild.yaml` qui lancent les mêmes commandes | 0 pas de CI · 1 CI partielle · 2 les quatre familles en CI · 3 checks requis avant fusion, dont les noms correspondent aux checks réellement rapportés sur une PR récente |
| 4.3 | **Parité locale / CI** | G | La CI appelle les mêmes commandes que la doc locale ; un préflight d'environnement existe | 0 commandes différentes · 2 mêmes commandes · 3 préflight écrit et imposé avant tout verdict |
| 4.4 | **Couverture mesurée** | G | Rapport de couverture en CI, seuil ou tendance | 0 aucune · 1 seuils configurés mais aucune étape de CI ne mesure · 2 mesurée en CI · 3 seuil bloquant |
| 4.5 | **Discipline de preuve** | G | Les instructions d'agents exigent la sortie capturée des commandes et un verdict `BLOCKED` quand un check ne peut pas tourner ; le template de PR a une section de validation | 0 rien · 1 une section « tests » libre · 2 la règle est écrite et le template l'exige · 3 les PR récentes contiennent la sortie des commandes |
| 4.6 | **Tests de comportement** | G | Règle écrite contre les tests couplés à l'implémentation (mocks qui vérifient des appels, fixtures qui recalculent le résultat) | 0 rien · 2 règle écrite · 3 reprise dans la checklist de revue |

## Phase 5 · Review

Plusieurs regards, un verdict, et la revue nourrit les règles.

| # | Critère | Axe | Preuves attendues | 0 → 3 |
|---|---|---|---|---|
| 5.1 | **Revue requise avant fusion** (bloquant) | W | Protection de branche : au moins une approbation requise, `CODEOWNERS` | 0 fusion libre · 1 convention · 2 protection active · 3 propriétaires de code désignés par zone |
| 5.2 | **Checklist de revue écrite** | C | Sections architecture, qualité, sécurité, couverture, qualité des tests ; gabarit de rapport | 0 rien · 1 liste informelle · 2 checklist complète · 3 chargée par les agents de revue |
| 5.3 | **Revue automatisée** | G | Commande ou skill de revue qui poste des constats sur la PR ; plusieurs angles en parallèle (code, architecture, sécurité, QA) | 0 rien · 1 un bot de lint · 2 une revue agent sur demande · 3 plusieurs angles consolidés, constats visibles sur des PR récentes |
| 5.4 | **Health gate de PR** | G | Aucune approbation possible avec conflits ou checks en échec | 0 rien · 2 règle écrite · 3 imposée par la protection de branche ou la revue automatisée |
| 5.5 | **L'auteur ne s'approuve pas** | W | La PR n'est jamais marquée prête par celui qui l'a produite, humain ou agent lancé par l'auteur | 0 auto-approbation · 2 écrit · 3 l'échantillon montre l'état « ok » posé par un tiers indépendant |
| 5.6 | **La revue propose des règles** | W | Le processus de revue inclut « ce constat doit-il devenir une règle apprise ? » | 0 rien · 2 écrit · 3 une règle récente provient d'une revue |

## Phase 6 · Compound-1 — capitalisation avant livraison

| # | Critère | Axe | Preuves attendues | 0 → 3 |
|---|---|---|---|---|
| 6.1 | **Catalogue de règles apprises** (bloquant) | C | Un fichier canonique de règles numérotées : sévérité, règle, exemple fautif, exemple correct, méthode de détection | 0 rien · 1 des notes dispersées (`docs/solutions/`, wiki) · 2 le catalogue au format complet · 3 chaque règle de code a une détection exécutable (les règles de processus peuvent rester en prose) |
| 6.2 | **Commande de capture** | W | Une commande qui extrait les leçons, dédoublonne contre le catalogue et persiste | 0 rien · 2 la commande existe · 3 le catalogue a reçu une règle depuis moins de 90 jours |
| 6.3 | **Réinjection** | C | Le catalogue est chargé par les agents de plan, build et revue | 0 non chargé · 2 chargé par au moins un · 3 chargé par les trois |
| 6.4 | **Qualité des règles** | C | Chaque règle est un motif répétable, pas un ticket fermé ni une règle de lint | 0 non applicable · 2 critère d'admission écrit · 3 échantillon conforme |
| 6.5 | **Une séance propre ne produit rien** (informatif, hors note) | W | Il est écrit qu'une absence de leçon est un résultat valide | Rapporté tel quel |

## Phase 7 · Ship — gate humain d'acceptation

| # | Critère | Axe | Preuves attendues | 0 → 3 |
|---|---|---|---|---|
| 7.1 | **Seul un humain fusionne** (bloquant) | W | Instructions d'agents sans `merge` ; protection de branche ; pas d'auto-merge | 0 un agent fusionne · 2 écrit · 3 protection active et aucun bot dans les auteurs de fusion récents |
| 7.2 | **Checklist de mise en production** | W | `RELEASE.md`, section de `CONTRIBUTING.md`, template de release | 0 rien · 1 tribale · 2 écrite · 3 suivie dans les dernières releases (tags, notes) |
| 7.3 | **Rollback écrit à froid** | W | Procédure de retour arrière documentée avant le déploiement, par type de changement (code, schéma, config) | 0 rien · 2 écrite · 3 testée ou référencée dans les PR à risque |
| 7.4 | **Déploiement progressif** | H | Feature flags, canary, pourcentage de trafic dans la config de déploiement | 0 tout ou rien · 1 cadre de flags sans aucun flag déclaré · 2 mécanisme déclaré et utilisé · 3 utilisé sur une livraison récente |
| 7.5 | **Journal des changements** | C | `CHANGELOG.md` ou release notes générées, à jour du dernier tag | 0 rien · 1 périmé · 2 à jour · 3 généré depuis les commits ou PR |

## Phase 8 · Ops

Souvent hors du dépôt. `assess` note ce qui est visible et marque le reste non évalué.

| # | Critère | Axe | Preuves attendues | 0 → 3 |
|---|---|---|---|---|
| 8.1 | **Observabilité configurée** | H | Logs structurés, métriques, traces dans la config applicative ; tableaux de bord référencés | 0 `print` · 1 logs seuls · 2 logs structurés et métriques · 3 tableaux de bord et alertes documentés |
| 8.2 | **Runbooks** | C | `docs/runbooks/`, `docs/troubleshooting/`, procédures d'astreinte | 0 rien · 1 une page · 2 par incident type · 3 mis à jour depuis moins de 90 jours |
| 8.3 | **Période d'observation** | W | Il est écrit qu'une livraison est observée 7 à 14 jours avant retrait du flag ou clôture | 0 rien · 2 écrit · 3 trace sur une livraison récente |
| 8.4 | **Erreurs jamais avalées** | G | Règle écrite contre les exceptions silencieuses ; détection par lint ou règle apprise | 0 rien · 2 règle écrite · 3 détection exécutable |

## Phase 9 · Compound-2 — capitalisation depuis la production

| # | Critère | Axe | Preuves attendues | 0 → 3 |
|---|---|---|---|---|
| 9.1 | **Postmortems** | C | Template de postmortem, dossier d'incidents, sans blâme | 0 rien · 1 des tickets d'incident · 2 template et dossier · 3 un postmortem depuis moins de 90 jours |
| 9.2 | **De l'incident à la règle** | W | La commande de capture accepte un mode incident et demande pourquoi les gates pré-release n'ont pas vu le problème | 0 rien · 2 le mode existe · 3 une règle du catalogue cite un incident |
| 9.3 | **Retour au Plan** | C | Les règles issues de production sont visibles au planificateur | 0 rien · 2 même catalogue que Compound-1 · 3 preuve d'un plan qui cite une règle d'incident |

## Phase 10 · Deprecation

| # | Critère | Axe | Preuves attendues | 0 → 3 |
|---|---|---|---|---|
| 10.1 | **Politique de dépréciation** | C | Versionnage d'API, en-têtes ou avertissements de dépréciation, délai annoncé | 0 suppression sèche · 1 au cas par cas · 2 politique écrite · 3 appliquée sur un retrait récent |
| 10.2 | **Retrait des flags et du code mort** | W | Issues ou label de nettoyage, date de retrait dans la définition des flags | 0 flags éternels · 2 suivi écrit · 3 retraits visibles dans l'historique récent |
| 10.3 | **Hygiène des dépendances** | H | `dependabot.yml`, `renovate.json`, audit de dépendances en CI | 0 rien · 1 audit manuel · 2 outil configuré · 3 PR de mise à jour fusionnées récemment |

---

## Lecture par axe

Le rapport donne aussi la moyenne des critères par axe. Elle sert à nommer le chantier dominant :

| Axe faible | Lecture | Commande aifier |
|---|---|---|
| C contexte | Les agents ne savent pas où ils sont : constitution absente, périmée ou monolithique | `init` puis `context` |
| W workflow | Les gates n'ont pas de support : pas d'états, pas de templates, fusion libre | `init` (labels, templates, workflow) |
| G gates de vérification | Rien ne prouve que ça marche | `gates` |
| H harnessability | Le code lui-même résiste : pas de typage, pas de frontières, pas d'observabilité | hors aifier ; recommandations dans le rapport |

## Verdict global

Le profil importe plus qu'une note unique. `assess` tire tout de même un verdict en quatre niveaux,
fondé sur les phases et non sur la moyenne :

| Verdict | Condition |
|---|---|
| **Non préparé** | Un critère bloquant à 0 dans les phases 0, 1 ou 4 (0.8 à 0 suffit) |
| **Prêt pour le Setup** | Aucun bloquant à 0 ; phases 0, 1, 4 au moins émergentes |
| **Cycle outillé** | Phases 0 à 6 au moins outillées (≥ 2) et critère 7.1 ≥ 2 |
| **Cycle gouverné** | Phases 0 à 7 outillées, dont au moins quatre gouvernées (≥ 2,8), et phase 9 ≥ 2 |

Les phases 8 et 10, et le reste de la phase 7, ne conditionnent pas le verdict « outillé » : leur
matière vit souvent hors du dépôt, dans la chaîne de déploiement. Elles figurent dans le profil et dans
les écarts.

## Écarts priorisés

Chaque critère noté sous 2 devient un écart. L'ordre de priorité :

1. critères **bloquants** à 0 ou 1, dans l'ordre des phases ;
2. critères des phases 0 à 2 (l'amont conditionne tout) ;
3. critères des phases 4 et 5 (sans preuve, le reste est de la confiance) ;
4. le reste, dans l'ordre des phases.

Chaque écart est rendu avec : la preuve manquante, la note cible réaliste (souvent 2, pas 3), et la
commande aifier ou l'action humaine qui le comble.

## Risques

Certains constats ne font descendre aucun critère sous 2 et minent pourtant plusieurs critères à la
fois. Ils ont leur section, avant le détail : branche recevant les fusions sans protection, checks
requis dont le nom ne correspond à aucun check rapporté, push force autorisé ou administrateurs
exemptés, label de disponibilité posé par l'agent de l'auteur, couverture configurée jamais
exécutée. Un risque cite sa preuve, les critères touchés et l'action.

## Format du rapport

```
# assess · <dépôt> · <date>

Verdict : <niveau>              Sources : git, forge (gh) | git seul
Branches recevant les fusions : <noms>     Fenêtre 90 jours depuis : <date>
Raison du verdict : <une ligne citant phases et critères décisifs>

| Phase | Note | Niveau | Bloquants |
|---|---|---|---|
| 0 Setup | 2,4 | outillé | ok |
| 1 Define | 1,0 | émergent | 1.1 à 1 |
| ...

Axes : C 2,1 · W 1,4 · G 2,6 · H 2,0

## Écarts priorisés
1. [1.1 bloquant] Templates d'issue absents — preuve : .github/ISSUE_TEMPLATE/ vide — cible 2 — `init`
2. ...

## Risques
- <constat> — preuve — critères touchés — action

## Détail par critère
<critère, note, preuve constatée (chemin ou commande et sortie), non évalué si applicable>
```

Le détail cite la preuve pour chaque note, dans l'esprit de la discipline de preuve que la grille
évalue elle-même. Un critère sans preuve citée n'a pas de note.

## Calibration

La grille se vérifie sur deux dépôts témoins avant d'être tenue pour juste. Les résultats restent
hors du dépôt aifier ; seules les attentes figurent ici.

| Témoin | Profil | Verdict attendu | Si le verdict diffère |
|---|---|---|---|
| Projet avancé | constitution en carte, guides par zone, skills et catalogue de règles vivants, gates en CI avec preuve, workflow à labels, revues multi-angles | **Cycle outillé**, proche de gouverné ; phases 8, 9 et 10 en retrait | la grille ou les sondes sont trop sévères |
| Projet classique | CI de tests et linter présents, un fichier de contexte monolithique, pas de template d'issue, pas de catalogue, fusion sans revue requise | **Prêt pour le Setup** au mieux, avec 1.1 et 6.1 en écarts bloquants | la grille note la présence et non la tenue |

Un écart entre attendu et obtenu est un constat sur la grille, à corriger dans la grille, jamais en
ajustant une note à la main.

## Ce que la grille ne mesure pas

- la qualité du code ou de l'architecture en soi : seulement leur **harnessability** ;
- la vélocité, le coût par fonctionnalité ou le taux de reprise : ce sont des métriques d'issue du
  cycle, à instrumenter ailleurs ;
- la pertinence du contexte en profondeur (rot, charge par session, étages) : c'est le rôle de
  `context`, dont `assess` ne prend qu'un échantillon en phase 0.
