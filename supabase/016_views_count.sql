-- ============================================================
-- QOTA — COMPTEUR DE VUES (§ complète le §25 avec une métrique
-- demandée par le propriétaire du projet, absente du texte initial)
-- ============================================================
-- Sécurité : le client ne peut JAMAIS modifier views_count
-- directement (pas de policy UPDATE sur cette colonne) — seule la
-- fonction increment_entity_views(), security definer, y est
-- autorisée. Évite qu'un utilisateur gonfle artificiellement ses
-- propres vues en modifiant la table depuis le client.
-- ============================================================

alter table entities
    add column if not exists views_count bigint not null default 0;

create or replace function public.increment_entity_views(p_entity_id uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
    update entities
    set views_count = views_count + 1
    where id = p_entity_id;
end;
$$;

grant execute on function public.increment_entity_views(uuid) to authenticated, anon;

-- user_items_view (008) étendue avec views_count — ajout en fin de
-- liste de colonnes uniquement (contrainte Postgres sur CREATE OR
-- REPLACE VIEW, déjà rencontrée avec entity_cards_view en 009).
create or replace view user_items_view as
select
    e.id,
    e.name,
    e.description,
    e.image_url,
    e.owner_id,
    trim(p.first_name || ' ' || p.last_name) as owner_name,
    e.created_at,
    coalesce(r.average_score, 0) as average_score,
    coalesce(r.ratings_count, 0) as ratings_count,
    coalesce(cm.comments_count, 0) as comments_count,
    e.views_count
from entities e
join profiles p on p.id = e.owner_id
left join entity_rating_summary r on r.entity_id = e.id
left join (
    select entity_id, count(*) as comments_count
    from comments
    where deleted_at is null
    group by entity_id
) cm on cm.entity_id = e.id
where e.kind = 'user_item' and e.status = 'active'
order by e.created_at desc;

-- entity_cards_view (003/009) étendue également, pour cohérence
-- future si les Services/Figures affichent aussi un compteur de vues.
create or replace view entity_cards_view as
select
    e.id,
    e.kind,
    e.name,
    e.description,
    e.image_url,
    e.category_id,
    e.figure_type_id,
    ft.name_fr as figure_type_name_fr,
    ft.name_ar as figure_type_name_ar,
    e.state_id,
    e.city_id,
    e.zone_id,
    c.name_fr as city_name_fr,
    c.name_ar as city_name_ar,
    z.name_fr as zone_name_fr,
    z.name_ar as zone_name_ar,
    coalesce(r.average_score, 0) as average_score,
    coalesce(r.ratings_count, 0) as ratings_count,
    coalesce(cm.comments_count, 0) as comments_count,
    e.views_count
from entities e
left join cities c on c.id = e.city_id
left join zones z on z.id = e.zone_id
left join figure_types ft on ft.id = e.figure_type_id
left join entity_rating_summary r on r.entity_id = e.id
left join (
    select entity_id, count(*) as comments_count
    from comments
    where deleted_at is null
    group by entity_id
) cm on cm.entity_id = e.id
where e.status = 'active';
