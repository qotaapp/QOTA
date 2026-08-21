-- Ajout de views_count à entity_cards_view (utilisée par Services,
-- Figures Publiques, et les sections admin) — en fin de liste de
-- colonnes uniquement (contrainte CREATE OR REPLACE VIEW).
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
    e.admin_listing_type_id,
    alt.name_fr as admin_listing_type_name_fr,
    alt.name_ar as admin_listing_type_name_ar,
    e.views_count
from entities e
left join cities c on c.id = e.city_id
left join zones z on z.id = e.zone_id
left join figure_types ft on ft.id = e.figure_type_id
left join admin_listing_types alt on alt.id = e.admin_listing_type_id
left join entity_rating_summary r on r.entity_id = e.id
left join (
    select entity_id, count(*) as comments_count
    from comments
    where deleted_at is null
    group by entity_id
) cm on cm.entity_id = e.id
where e.status = 'active';
