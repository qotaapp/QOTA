-- ============================================================
-- QOTA — VUE POUR LES CARTES SERVICE (§25)
-- Regroupe en une seule requête : nom, localisation, image,
-- moyenne des évaluations, nombre d'évaluations, nombre de commentaires.
-- Ne remonte JAMAIS created_by/owner_id (règle §18/§37).
-- ============================================================

create or replace view entity_cards_view as
select
    e.id,
    e.kind,
    e.name,
    e.description,
    e.image_url,
    e.category_id,
    e.state_id,
    e.city_id,
    e.zone_id,
    c.name_fr as city_name_fr,
    c.name_ar as city_name_ar,
    z.name_fr as zone_name_fr,
    z.name_ar as zone_name_ar,
    coalesce(r.average_score, 0) as average_score,
    coalesce(r.ratings_count, 0) as ratings_count,
    coalesce(cm.comments_count, 0) as comments_count
from entities e
left join cities c on c.id = e.city_id
left join zones z on z.id = e.zone_id
left join entity_rating_summary r on r.entity_id = e.id
left join (
    select entity_id, count(*) as comments_count
    from comments
    where deleted_at is null
    group by entity_id
) cm on cm.entity_id = e.id
where e.status = 'active';

-- Cette vue est celle que le client Flutter interroge pour les listes
-- de Services (§25-26) — jamais la table `entities` directement,
-- afin de ne jamais exposer created_by/owner_id côté public.
