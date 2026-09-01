-- ============================================================
-- QOTA — "BONS PLANS" (offres/promotions), accessibles depuis
-- l'icône ajoutée à côté de la recherche sur l'écran d'accueil.
-- ============================================================
-- Contenu éditorial géré par le Super Admin (pas de contribution
-- utilisateur, contrairement aux Services/Figures) — même logique
-- que figure_types/content_types mais ici l'entrée elle-même EST le
-- contenu final (pas juste un "type").
-- ============================================================

create table if not exists bon_plans (
    id uuid primary key default uuid_generate_v4(),
    title text not null,
    description text,
    image_url text not null,
    link_url text,
    active boolean not null default true,
    order_index int not null default 0,
    created_at timestamptz not null default now(),
    created_by uuid references profiles(id)
);

create index if not exists idx_bon_plans_active on bon_plans(active, order_index);

alter table bon_plans enable row level security;

create policy "Public read active bon_plans" on bon_plans
    for select using (active = true or is_super_admin());
create policy "Admin manage bon_plans" on bon_plans
    for insert with check (is_super_admin());
create policy "Admin update bon_plans" on bon_plans
    for update using (is_super_admin());
create policy "Admin delete bon_plans" on bon_plans
    for delete using (is_super_admin());
