
## Mise à jour 2026-10-07, suite

- Grille `assess` rédigée : `method/assess-grid.md` (échelle 0-3, deux axes transverses H et C,
  phases 0 à 10, pondération, format de rapport, sondes, calibration RAISE ≈ 2,4 Augmenté).
- Projet témoin non aifié : `~/Projects/smart-chatbot` (loveOSS/smart-chatbot, FastAPI + Streamlit).
  Attendu : Assisté, 1,0 à 1,5.
- Plan de test du process complet, dans cet ordre : installation d'aifier dans smart-chatbot,
  `assess` (avant), `init`, `assess` (après) ; puis `assess` sur RAISE pour vérifier la calibration.
  Ordre important : assess avant init donne la mesure de départ.
