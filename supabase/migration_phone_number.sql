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

-- IMPORTANT : entity_cards_view doit être recréée pour exposer
-- e.phone_number. Remplace le SELECT ci-dessous par la définition
-- exacte de ta vue existante en y ajoutant simplement la colonne
-- `e.phone_number` (ou l'alias équivalent selon ta structure).
--
-- Exemple générique (à adapter à ta vue réelle) :
--
-- create or replace view entity_cards_view as
-- select
--   e.id,
--   e.kind,
--   e.name,
--   e.description,
--   e.image_url,
--   e.phone_number,   -- <-- ligne ajoutée
--   ...
-- from entities e
-- ...
-- where e.status = 'active';
