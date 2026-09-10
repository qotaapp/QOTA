-- ============================================================
-- QOTA — L'AVIS ÉCRIT LORS D'UNE ÉVALUATION EST AUSSI PUBLIÉ DANS
-- LES COMMENTAIRES
-- ============================================================
-- `comment_id` retient le commentaire lié à cette évaluation. Comme
-- une évaluation est upsert (une seule par user/entité, §28), sans
-- ce lien, modifier sa note republierait un nouveau commentaire à
-- chaque fois au lieu de mettre à jour celui déjà publié.
-- ============================================================

alter table ratings
    add column if not exists comment_id uuid references comments(id) on delete set null;
