-- ============================================================
-- QOTA — CORRECTION RECHERCHE : ENTRER DANS LE PROFIL D'UN
-- UTILISATEUR TROUVÉ (complète §013_search.sql)
-- ============================================================
-- Problème : chercher un utilisateur remonte son User Item (le nom
-- correspond), mais taper dessus ouvrait ServiceDetailsScreen (fiche
-- Service générique) au lieu du profil de la personne — aucun moyen
-- d'"entrer" dans son profil depuis la recherche.
--
-- Correction :
--   1) search_entities retourne désormais owner_id, MAIS uniquement
--      pour kind='user_item' (règle §286 de 001_schema.sql : owner_id/
--      created_by ne sont jamais exposés pour les autres kinds).
--   2) La recherche matche aussi le prénom/nom du propriétaire d'un
--      User Item (pas seulement le nom de l'item lui-même), pour
--      vraiment "trouver un utilisateur" par son nom.
-- ============================================================

-- Le type de retour change (ajout de owner_id) : CREATE OR REPLACE
-- refuse ça pour une fonction définie avec OUT/TABLE params, il faut
-- d'abord supprimer l'ancienne version.
drop function if exists public.search_entities(text, double precision, double precision, int);

create function public.search_entities(
    p_query text,
    p_user_lat double precision default null,
    p_user_lng double precision default null,
    p_limit int default 30
)
returns table (
    id uuid,
    kind entity_kind,
    name text,
    description text,
    image_url text,
    city_name_fr text,
    zone_name_fr text,
    average_score numeric,
    ratings_count bigint,
    comments_count bigint,
    relevance real,
    owner_id uuid
)
language sql
stable
security definer set search_path = public
as $$
    select
        e.id, e.kind, e.name, e.description, e.image_url,
        c.name_fr as city_name_fr,
        z.name_fr as zone_name_fr,
        coalesce(r.average_score, 0) as average_score,
        coalesce(r.ratings_count, 0) as ratings_count,
        coalesce(cm.comments_count, 0) as comments_count,
        greatest(
            similarity(e.name, p_query),
            similarity(coalesce(c.name_fr, ''), p_query),
            similarity(coalesce(z.name_fr, ''), p_query),
            case when e.kind = 'user_item' then
                greatest(
                    similarity(coalesce(p.first_name, ''), p_query),
                    similarity(coalesce(p.last_name, ''), p_query)
                )
            else 0 end,
            case when e.description ilike '%' || p_query || '%' then 0.3 else 0 end
        ) as relevance,
        -- Jamais exposé en dehors de 'user_item' (§286, 001_schema.sql).
        case when e.kind = 'user_item' then e.owner_id else null end as owner_id
    from entities e
    left join cities c on c.id = e.city_id
    left join zones z on z.id = e.zone_id
    left join profiles p on e.kind = 'user_item' and p.id = e.owner_id
    left join entity_rating_summary r on r.entity_id = e.id
    left join (
        select entity_id, count(*) as comments_count
        from comments where deleted_at is null
        group by entity_id
    ) cm on cm.entity_id = e.id
    where e.status = 'active'
      and e.kind in ('service', 'user_item', 'public_figure')
      and (
          e.name ilike '%' || p_query || '%'
          or e.description ilike '%' || p_query || '%'
          or c.name_fr ilike '%' || p_query || '%'
          or z.name_fr ilike '%' || p_query || '%'
          or similarity(e.name, p_query) > 0.2
          or (e.kind = 'user_item' and (
              p.first_name ilike '%' || p_query || '%'
              or p.last_name ilike '%' || p_query || '%'
              or (p.first_name || ' ' || p.last_name) ilike '%' || p_query || '%'
          ))
      )
    order by relevance desc, r.ratings_count desc nulls last
    limit p_limit;
$$;

grant execute on function public.search_entities(text, double precision, double precision, int) to authenticated, anon;
