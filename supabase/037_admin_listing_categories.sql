-- ============================================================
-- QOTA — CATÉGORIES DANS LES SECTIONS ADMIN (Vente en ligne, etc.)
-- ============================================================
-- admin_listing_types (022) découpe le menu Évaluer en 3 sections
-- ("Chaînes et programmes" / "Vente en ligne" / "Autres"), mais
-- chaque section était jusqu'ici une liste plate de publications.
-- On ajoute un niveau de catégories À L'INTÉRIEUR d'une section —
-- demandé pour "Vente en ligne" en premier, réutilisable ensuite
-- pour les 2 autres sections sans nouvelle migration de structure.
--
-- Seul le Super Admin peut créer/modifier/désactiver/supprimer une
-- catégorie (demande explicite) — contrairement aux publications
-- elles-mêmes, ouvertes à tout utilisateur (§033).
-- ============================================================

create table admin_listing_categories (
    id uuid primary key default uuid_generate_v4(),
    admin_listing_type_id uuid not null references admin_listing_types(id) on delete cascade,
    name_fr text not null,
    name_ar text not null,
    order_index int not null default 0,
    active boolean not null default true,
    created_at timestamptz not null default now()
);

create index idx_admin_listing_categories_type on admin_listing_categories(admin_listing_type_id);

alter table admin_listing_categories enable row level security;

create policy "Public read active admin_listing_categories" on admin_listing_categories
    for select using (active = true or is_super_admin());
create policy "Admin insert admin_listing_categories" on admin_listing_categories
    for insert with check (is_super_admin());
create policy "Admin update admin_listing_categories" on admin_listing_categories
    for update using (is_super_admin());
create policy "Admin delete admin_listing_categories" on admin_listing_categories
    for delete using (is_super_admin());

alter table entities
    add column if not exists admin_listing_category_id uuid references admin_listing_categories(id);

create index if not exists idx_entities_admin_listing_category
    on entities(admin_listing_category_id);

-- ---------------- entity_cards_view : reprend EXACTEMENT la
-- définition actuelle (vérifiée via pg_get_viewdef côté prod),
-- colonnes ajoutées en fin de liste uniquement, rien retiré.
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
where e.status = 'active';
