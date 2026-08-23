-- ============================================================
-- QOTA — CATÉGORIES PROPRES À CHAQUE ZONE (remplace category_cities)
-- ============================================================
-- L'édition des catégories par Ville (§029, migration 031) est
-- remplacée par une granularité plus fine : par ZONE. Le Super
-- Admin gère désormais les catégories directement depuis l'écran
-- Zones, plus depuis l'écran Villes.
--
-- Le seed préserve tout ce qui a déjà été configuré via
-- category_cities : chaque lien (catégorie, ville) devient un lien
-- (catégorie, zone) pour CHAQUE zone de cette ville. Rien ne
-- disparaît pour les villes déjà personnalisées ; pour les autres,
-- le seed de la migration 031 (toutes catégories × toutes villes)
-- se traduit en toutes catégories × toutes zones.
-- ============================================================

create table if not exists category_zones (
    category_id uuid not null references categories(id) on delete cascade,
    zone_id uuid not null references zones(id) on delete cascade,
    primary key (category_id, zone_id)
);

alter table category_zones enable row level security;

create policy "Public read category_zones" on category_zones
    for select using (true);
create policy "Admin manage category_zones" on category_zones
    for insert with check (is_super_admin());
create policy "Admin delete category_zones" on category_zones
    for delete using (is_super_admin());

-- Migration des données existantes : (catégorie, ville) -> (catégorie, zone)
-- pour toutes les zones de cette ville.
insert into category_zones (category_id, zone_id)
select cc.category_id, z.id
from category_cities cc
join zones z on z.city_id = cc.city_id
on conflict do nothing;

-- L'édition par Ville est retirée de l'app (remplacée par la Zone) :
-- on supprime la table devenue inutile et ses policies.
drop policy if exists "Public read category_cities" on category_cities;
drop policy if exists "Admin manage category_cities" on category_cities;
drop policy if exists "Admin delete category_cities" on category_cities;
drop table if exists category_cities;
