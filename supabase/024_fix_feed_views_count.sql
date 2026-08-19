-- ============================================================
-- QOTA — CORRECTIF : views_count MANQUANT DANS LE FEED (Home)
-- ============================================================
-- Bug : get_feed() ne renvoyait jamais views_count. Résultat, sur la
-- page Home, le compteur de vues d'un User Item affichait TOUJOURS 0,
-- quel que soit le nombre réel de vues enregistrées (le compteur
-- lui-même, corrigé en §023, était pourtant correct en base — il
-- n'était simplement jamais transmis au Feed).
--
-- Ajout de views_count en fin de liste de colonnes uniquement
-- (contrainte RETURNS TABLE, même règle qu'une vue, cf. §016/§017).
-- ============================================================

create or replace function public.get_feed(
    p_user_lat double precision default null,
    p_user_lng double precision default null,
    p_limit int default 20,
    p_offset int default 0
)
returns table (
    id uuid,
    kind entity_kind,
    name text,
    description text,
    image_url text,
    city_name_fr text,
    zone_name_fr text,
    owner_name text, -- rempli uniquement pour les User Items (§23), jamais pour les Services (§18)
    average_score numeric,
    ratings_count bigint,
    comments_count bigint,
    created_at timestamptz,
    score double precision,
    owner_id uuid,
    owner_avatar_url text,
    views_count bigint
)
language sql
stable
security definer set search_path = public
as $$
    -- Poids de l'algorithme — constantes ajustables (§10 : "permettre
    -- l'évolution future"). Toute évolution future peut soit modifier
    -- ces poids, soit remplacer entièrement cette fonction.
    with weights as (
        select
            0.30::double precision as w_freshness,
            0.30::double precision as w_engagement,
            0.25::double precision as w_proximity,
            0.15::double precision as w_promotion
    ),
    base as (
        select
            e.id, e.kind, e.name, e.description, e.image_url,
            e.owner_id, e.created_at, e.latitude, e.longitude,
            e.is_promoted, e.promoted_until, e.views_count,
            c.name_fr as city_name_fr,
            z.name_fr as zone_name_fr,
            coalesce(r.average_score, 0) as average_score,
            coalesce(r.ratings_count, 0) as ratings_count,
            coalesce(cm.comments_count, 0) as comments_count
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
          and e.kind in ('service', 'user_item') -- Figures publiques exclues du Feed (§35, hors périmètre)
    ),
    scored as (
        select
            b.*,
            -- Fraîcheur : décroît avec l'âge, jamais nulle.
            1.0 / (1.0 + extract(epoch from (now() - b.created_at)) / 86400.0) as freshness_score,
            -- Engagement : échelle logarithmique pour éviter qu'un seul
            -- item très populaire écrase tout le reste du Feed.
            ln(1 + b.ratings_count + b.comments_count) as engagement_raw,
            -- Proximité : distance haversine en km si coordonnées connues
            -- des deux côtés, sinon score neutre (0.5) pour ne pas
            -- pénaliser les entités sans localisation précise.
            case
                when p_user_lat is not null and p_user_lng is not null
                     and b.latitude is not null and b.longitude is not null
                then 1.0 / (1.0 + (
                    6371 * acos(
                        least(1.0, greatest(-1.0,
                            cos(radians(p_user_lat)) * cos(radians(b.latitude)) *
                            cos(radians(b.longitude) - radians(p_user_lng)) +
                            sin(radians(p_user_lat)) * sin(radians(b.latitude))
                        ))
                    )
                ))
                else 0.5
            end as proximity_score,
            case
                when b.is_promoted and (b.promoted_until is null or b.promoted_until > now())
                then 1.0 else 0.0
            end as promotion_score
        from base b
    ),
    normalized as (
        select
            s.*,
            -- Normalisation min-max de l'engagement sur le lot courant.
            case
                when max(engagement_raw) over () = min(engagement_raw) over ()
                then 0.5
                else (engagement_raw - min(engagement_raw) over ())
                     / nullif(max(engagement_raw) over () - min(engagement_raw) over (), 0)
            end as engagement_score
        from scored s
    )
    select
        n.id, n.kind, n.name, n.description, n.image_url,
        n.city_name_fr, n.zone_name_fr,
        case when n.kind = 'user_item' then trim(p.first_name || ' ' || p.last_name) else null end as owner_name,
        n.average_score, n.ratings_count, n.comments_count, n.created_at,
        (
            select
                w.w_freshness * n.freshness_score +
                w.w_engagement * n.engagement_score +
                w.w_proximity * n.proximity_score +
                w.w_promotion * n.promotion_score
            from weights w
        ) as score,
        case when n.kind = 'user_item' then n.owner_id else null end as owner_id,
        case when n.kind = 'user_item' then p.avatar_url else null end as owner_avatar_url,
        n.views_count
    from normalized n
    left join profiles p on p.id = n.owner_id and n.kind = 'user_item'
    order by score desc, n.created_at desc
    limit p_limit offset p_offset;
$$;

grant execute on function public.get_feed(double precision, double precision, int, int) to authenticated, anon;
