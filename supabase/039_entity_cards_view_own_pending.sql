-- ============================================================
-- QOTA — LE CRÉATEUR VOIT (ET PEUT ÉVALUER/COMMENTER) SA PROPRE
-- PUBLICATION EN ATTENTE D'APPROBATION
-- ============================================================
-- entity_cards_view filtrait `where e.status = 'active'` SANS AUCUNE
-- exception pour le créateur — contrairement à ce que prévoyait déjà
-- le code Flutter (bannière "En attente d'approbation... Vous pouvez
-- déjà l'évaluer et la commenter" dans ServiceDetailsScreen). En
-- pratique, getEntityById() ne retrouvait jamais l'entité tant
-- qu'elle n'était pas approuvée — même pour son propre créateur —
-- et affichait "Service introuvable".
--
-- Les policies RLS sur `ratings` et `comments` n'ont, elles, jamais
-- bloqué ce cas (elles vérifient seulement `user_id = auth.uid()`,
-- sans condition de statut) : le seul verrou était donc bien cette
-- vue. Reprend EXACTEMENT la définition actuellement en base
-- (colonnes admin_listing_category_* incluses) — seule la clause
-- `where` finale change.
--
-- Effet de bord attendu (et cohérent avec la règle "visible
-- UNIQUEMENT par le créateur") : sa propre publication en attente
-- apparaîtra aussi mélangée dans ses listes de navigation habituelles
-- (catégorie, etc.), pas seulement sur sa fiche détail — jamais pour
-- personne d'autre.
-- ============================================================

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
    coalesce(r.average_score, 0::numeric) as average_score,
    coalesce(r.ratings_count, 0::bigint) as ratings_count,
    coalesce(cm.comments_count, 0::bigint) as comments_count,
    e.admin_listing_type_id,
    alt.name_fr as admin_listing_type_name_fr,
    alt.name_ar as admin_listing_type_name_ar,
    e.views_count,
    e.admin_listing_category_id,
    alc.name_fr as admin_listing_category_name_fr,
    alc.name_ar as admin_listing_category_name_ar
from entities e
left join cities c on c.id = e.city_id
left join zones z on z.id = e.zone_id
left join figure_types ft on ft.id = e.figure_type_id
left join admin_listing_types alt on alt.id = e.admin_listing_type_id
left join admin_listing_categories alc on alc.id = e.admin_listing_category_id
left join entity_rating_summary r on r.entity_id = e.id
left join (
    select entity_id, count(*) as comments_count
    from comments
    where deleted_at is null
    group by entity_id
) cm on cm.entity_id = e.id
where e.status = 'active'::entity_status or e.created_by = auth.uid();
