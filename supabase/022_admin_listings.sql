-- ============================================================
-- QOTA — SECTIONS "CHAÎNES ET PROGRAMMES" / "VENTE EN LIGNE" /
-- "AUTRES" (menu Évaluer), ALIMENTÉES PAR LE SUPER ADMIN (2/2)
-- ============================================================
-- À exécuter APRÈS 021_admin_listings_enum.sql (jamais dans la même
-- transaction que la création de la valeur d'enum 'admin_listing').
--
-- Ces 3 boutons du menu Évaluer pointaient vers un simple écran
-- "Bientôt disponible" (ComingSoonScreen). Ils deviennent ici de
-- vraies sections, sur le même principe que les Figures Publiques
-- (§35) : un type détermine la section, une entities de kind
-- 'admin_listing' est le contenu. Contrairement aux Services et
-- Figures (ajoutables par n'importe quel utilisateur), SEUL le
-- Super Admin (ou un modérateur avec la permission
-- 'moderate_content', §018) peut y publier — exactement la demande.
--
-- Le jeu de types est géré dynamiquement (comme figure_types) plutôt
-- que ces 3 noms codés en dur : le Super Admin pourra en ajouter
-- d'autres plus tard sans nouvelle intervention technique, tout en
-- gardant "Chaînes et programmes" / "Vente en ligne" / "Autres" comme
-- point de départ exact demandé ici.
-- ============================================================

create table admin_listing_types (
    id uuid primary key default uuid_generate_v4(),
    slug text not null unique, -- identifiant stable utilisé par le code Flutter (jamais l'UUID)
    name_fr text not null,
    name_ar text not null,
    icon text,
    order_index int not null default 0,
    active boolean not null default true,
    created_at timestamptz not null default now()
);

alter table admin_listing_types enable row level security;

create policy "Public read active admin_listing_types" on admin_listing_types
    for select using (active = true or is_super_admin());
create policy "Admin manage admin_listing_types" on admin_listing_types
    for insert with check (is_super_admin());
create policy "Admin update admin_listing_types" on admin_listing_types
    for update using (is_super_admin());
create policy "Admin delete admin_listing_types" on admin_listing_types
    for delete using (is_super_admin());

insert into admin_listing_types (slug, name_fr, name_ar, icon, order_index) values
    ('channels_programs', 'Chaînes et programmes', 'قنوات وبرامج', 'live_tv', 1),
    ('online_sales', 'Vente en ligne', 'بيع عبر الإنترنت', 'shopping_cart', 2),
    ('other', 'Autres', 'أخرى', 'inventory_2', 3)
on conflict (slug) do nothing;

alter table entities
    add column if not exists admin_listing_type_id uuid references admin_listing_types(id);

create index if not exists idx_entities_admin_listing_type
    on entities(admin_listing_type_id);

-- ---------------- entity_cards_view : colonnes ajoutées en fin de
-- liste uniquement (contrainte CREATE OR REPLACE VIEW, cf. §016/§009).
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
    alt.name_ar as admin_listing_type_name_ar
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

-- ---------------- RLS entities : restreindre la création des
-- 'admin_listing' au Super Admin / modérateur 'moderate_content'.
-- Services, User Items et Figures Publiques restent INCHANGÉS
-- (créables par n'importe quel utilisateur, comme avant).
drop policy if exists "Users create entities" on entities;
create policy "Users create entities" on entities
    for insert with check (
        created_by = auth.uid()
        and (
            kind <> 'admin_listing'
            or is_super_admin()
            or has_permission('moderate_content')
        )
    );
