-- ============================================================
-- QOTA — CATÉGORIES PROPRES À CHAQUE VILLE
-- ============================================================
-- Jusqu'ici les catégories étaient globales : la même liste partout.
-- Chaque Ville a maintenant SES PROPRES catégories, gérables
-- individuellement par le Super Admin. Le seed ci-dessous préserve
-- le comportement actuel (toutes les catégories restent visibles
-- dans toutes les villes existantes) — rien ne disparaît tant que le
-- Super Admin ne personnalise pas explicitement une ville.
-- ============================================================

create table if not exists category_cities (
    category_id uuid not null references categories(id) on delete cascade,
    city_id uuid not null references cities(id) on delete cascade,
    primary key (category_id, city_id)
);

alter table category_cities enable row level security;

create policy "Public read category_cities" on category_cities
    for select using (true);
create policy "Admin manage category_cities" on category_cities
    for insert with check (is_super_admin());
create policy "Admin delete category_cities" on category_cities
    for delete using (is_super_admin());

-- Seed rétro-compatible : associe toutes les catégories existantes à
-- toutes les villes existantes (comportement identique à avant).
insert into category_cities (category_id, city_id)
select c.id, ci.id from categories c cross join cities ci
on conflict do nothing;
