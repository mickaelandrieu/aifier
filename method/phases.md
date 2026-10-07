# Les onze phases du SDLC augmenté

Référence : https://www.sfeir.com/concepts/sdlc-augmente/ (et les concepts liés : context-engineering,
harness-engineering, cdlc, issue-based-development, context-flywheel). Cette page fixe le vocabulaire
qu'emploient toutes les commandes aifier. Elle ne réinvente rien : elle numérote.

| N° | Phase | Temps | Ce qui s'y passe | Nature |
|---|---|---|---|---|
| 0 | Setup | Amont | Cadrer le cycle : constitution des agents, gates déclarés, workflow, bases de connaissance | — |
| 1 | Define | Amont | Une idée devient un contrat : problème, impact, critères d'acceptation observables | **Gate humain** (intention) |
| 2 | Plan | Amont | Deux ou trois approches d'architecture distinctes, arbitrées par un humain avant le code | **Gate humain** (architecture) |
| 3 | Build | Cœur | Construire une tranche à la fois, sous les règles apprises | — |
| 4 | Verify | Cœur | Exécuter lint, typage, tests, build, avec preuve capturée | — |
| 5 | Review | Cœur | Consolider plusieurs revues parallèles en un verdict | — |
| 6 | Compound-1 | Capitalisation | Leçons statiques avant livraison, réinjectées au Plan suivant | **Capitalisation** |
| 7 | Ship | Aval | Checklist de mise en production, rollback écrit à froid, déploiement progressif 5 → 100 % | **Gate humain** (acceptation) |
| 8 | Ops | Aval | Observer le système en production, 7 à 14 jours | — |
| 9 | Compound-2 | Capitalisation | Leçons runtime issues de la production, réinjectées au Plan suivant | **Capitalisation** |
| 10 | Deprecation | Aval | Retirer le code par un retrait annoncé, derrière un flag | — |

## Les trois gates humains

Un gate est un point où un agent **doit s'arrêter** et où un humain décide. Deux défauts à surveiller
quand on outille un projet : le **gate manquant** (un agent qui décide seul de l'intention, de
l'architecture ou de la fusion) et l'**approbation superflue** (une signature humaine entre deux gates,
là où les agents devraient porter la responsabilité).

| Gate | Phase | Tenu par | Question tranchée |
|---|---|---|---|
| Intention | 1 Define | PO, auteur de l'issue | Le contrat reflète-t-il le besoin réel ? |
| Architecture | 2 Plan | lead, architecte | Quelle approche construit-on ? |
| Acceptation | 7 Ship | reviewer, mainteneur | Fusionne-t-on et livre-t-on ? |

## Les deux capitalisations

Les deux alimentent le même catalogue de règles apprises, rechargé par tous les agents et consulté
au Plan du cycle suivant. « Un bug vu deux fois n'est pas un bug, c'est un trou dans le système. »

- **Compound-1** (phase 6) : leçons tirées du travail et des revues qui viennent d'être faits.
- **Compound-2** (phase 9) : leçons tirées d'un incident, d'un postmortem, d'un signal d'observabilité.

## Les axes transversaux

Trois concepts traversent les phases et servent de grille de lecture à `assess` et `context` :

- **Harness engineering** : guides (feedforward : AGENTS.md, conventions, templates) et sensors
  (feedback : tests, linters, typage, revue automatisée) ; la **harnessability** d'une base de code
  tient à son typage, à ses frontières de modules et à sa structure.
- **Context engineering et CDLC** : le contexte est une dépendance logicielle, à étages (chaud toujours
  chargé, intermédiaire à la demande, froid consulté au besoin), avec un cycle Generate → Evaluate →
  Distribute → Observe. Une spec périmée est plus nuisible qu'une spec absente.
- **Issue-based development** : on signale un écart, l'agent analyse le système, un humain arbitre
  le plan, la revue précède la livraison, la leçon est consignée.

## Repères chiffrés publiés

À prendre comme ordres de grandeur, pas comme seuils : environ 80 % de l'effort humain sur la
spécification et la revue ; environ 30 % d'itérations de correction en moins après dix cycles ;
bascule d'équipe vers la dixième itération.
