-- ============================================================
-- QOTA — VUE USER ITEMS (§7, §23)
-- Contrairement à entity_cards_view (Services), ici le propriétaire
-- EST exposé publiquement, comme l'exige le cahier des charges.
-- ============================================================

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
    coalesce(cm.comments_count, 0) as comments_count
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
