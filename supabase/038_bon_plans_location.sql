-- ============================================================
-- QOTA — LOCALISATION DES BONS PLANS (ville / zone, optionnelles)
-- ============================================================
-- Le Super Admin précise, à la création d'un Bon Plan, la Ville (et
-- éventuellement la Zone) concernée — comme pour une Service.
-- Les deux restent NULLABLES : un Bon Plan sans localisation est
-- considéré national/global et s'affiche partout, quelle que soit
-- la position détectée du visiteur.
-- ============================================================

alter table bon_plans
    add column if not exists city_id uuid references cities(id),
    add column if not exists zone_id uuid references zones(id);

create index if not exists idx_bon_plans_city on bon_plans(city_id);
create index if not exists idx_bon_plans_zone on bon_plans(zone_id);
