-- ============================================================
-- QOTA — RECHERCHE (§12)
-- "La recherche doit permettre notamment de rechercher : services,
--  lieux, catégories, contenus pertinents, résultats proches."
-- ============================================================

-- Recherche unifiée sur les entités : nom, description, ET le nom de
-- la ville/zone (couvre la recherche "par lieu", ex: chercher "Zarroug"
-- remonte les Services situées dans cette zone). Classée par pertinence
-- texte (pg_trgm), avec un boost de proximité si la position est connue.
create or replace function public.search_entities(
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
    relevance real
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
            case when e.description ilike '%' || p_query || '%' then 0.3 else 0 end
        ) as relevance
    from entities e
    left join cities c on c.id = e.city_id
    left join zones z on z.id = e.zone_id
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
      )
    order by relevance desc, r.ratings_count desc nulls last
    limit p_limit;
$$;

grant execute on function public.search_entities(text, double precision, double precision, int) to authenticated, anon;

-- Recherche de catégories (§12 : "catégories" dans les résultats).
create or replace function public.search_categories(p_query text, p_limit int default 10)
returns setof categories
language sql
stable
security definer set search_path = public
as $$
    select * from categories
    where active = true
      and (name_fr ilike '%' || p_query || '%' or name_ar ilike '%' || p_query || '%')
    order by order_index
    limit p_limit;
$$;

grant execute on function public.search_categories(text, int) to authenticated, anon;
