-- ============================================================
-- QOTA — CORRECTIF STORIES : AVATAR/NOM DE L'AUTEUR INVISIBLES
-- ============================================================
-- Cause : StoriesRepository embarquait `profiles(...)` dans sa requête
-- sur `stories`. Cet embed PostgREST respecte les RLS de `profiles`
-- (lecture limitée à soi-même) — l'avatar/nom des AUTRES utilisateurs
-- ressortait donc systématiquement `null`.
-- Correctif : une vue dédiée, comme entity_cards_view/user_items_view,
-- exposant uniquement les champs déjà publics ailleurs dans l'app
-- (prénom/nom/avatar) — créée par une migration (rôle postgres), elle
-- contourne la RLS de `profiles`, exactement comme les vues existantes.
-- ============================================================

create or replace view stories_view as
select
    s.id,
    s.user_id,
    s.media_url,
    s.media_type,
    s.duration_seconds,
    s.created_at,
    p.first_name,
    p.last_name,
    p.avatar_url
from stories s
join profiles p on p.id = s.user_id;
