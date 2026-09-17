-- Ajout du numéro de téléphone
-- profiles.phone_number : PRIVÉ (non exposé par public_profiles_view)
-- entities.phone_number : PUBLIC pour les Services (exposé par entity_cards_view)

alter table profiles
  add column if not exists phone_number text;

alter table entities
  add column if not exists phone_number text;

-- Validation format E.164 (ex: +21612345678) — filet de sécurité
-- redondant avec la validation côté client (Dart).
alter table profiles
  add constraint phone_number_format
  check (phone_number is null or phone_number ~ '^\+[1-9]\d{6,14}$');

alter table entities
  add constraint phone_number_format
  check (phone_number is null or phone_number ~ '^\+[1-9]\d{6,14}$');

-- ============================================================
-- entity_cards_view : reprend exactement la définition de
-- 037_admin_listing_categories.sql (la plus récente des 2 versions
-- fournies), avec e.phone_number ajouté en fin de liste.
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
    coalesce(r.average_score, 0) as average_score,
    coalesce(r.ratings_count, 0) as ratings_count,
    coalesce(cm.comments_count, 0) as comments_count,
    e.admin_listing_type_id,
    alt.name_fr as admin_listing_type_name_fr,
    alt.name_ar as admin_listing_type_name_ar,
    e.views_count,
    e.admin_listing_category_id,
    alc.name_fr as admin_listing_category_name_fr,
    alc.name_ar as admin_listing_category_name_ar,
    e.phone_number
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
where e.status = 'active';

-- ============================================================
-- Autoriser le Super Admin / modérateur avec la permission
-- 'moderate_content' à modifier phone_number (et le reste) sur une
-- Service qu'il ne possède pas. Policy ADDITIONNELLE — ne touche pas
-- à ta policy existante "Owners update own entities" (ou équivalent) :
-- PostgreSQL combine plusieurs policies USING avec OR par défaut.
-- is_super_admin() et has_permission('moderate_content') sont les
-- mêmes fonctions déjà utilisées dans 030/037 (sans argument, elles
-- s'appuient sur auth.uid() en interne).
-- ============================================================
drop policy if exists "Admins update entities" on entities;
create policy "Admins update entities" on entities
    for update
    using (is_super_admin() or has_permission('moderate_content'))
    with check (is_super_admin() or has_permission('moderate_content'));

-- ============================================================
-- IMPORTANT — reste à faire, fichier non fourni :
-- la fonction get_feed() (012_feed_algorithm.sql) doit elle aussi
-- renvoyer phone_number dans son RETURNS TABLE / SELECT, sinon
-- FeedItem.phoneNumber restera toujours null sur la carte du Feed
-- (le Feed ne passe pas par entity_cards_view, mais par cette RPC).
-- Envoie ce fichier si tu veux le diff exact.
-- ============================================================
