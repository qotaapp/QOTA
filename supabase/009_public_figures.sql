-- ============================================================
-- QOTA — FIGURES PUBLIQUES (§35-37)
-- "Les personnes ordinaires ne peuvent PAS être évaluées comme
--  personnes. Seules les personnes qui fournissent un service ou ont
--  une activité publique pertinente peuvent être ajoutées. Le Super
--  Admin décide des types disponibles et peut en ajouter de nouveaux."
-- ============================================================

create table figure_types (
    id uuid primary key default uuid_generate_v4(),
    name_fr text not null,
    name_ar text not null,
    order_index int not null default 0,
    active boolean not null default true,
    created_at timestamptz not null default now()
);

-- Une Figure Publique est une `entities` de kind='public_figure' ;
-- figure_type_id précise son type (politicien, acteur, etc.).
alter table entities
    add column if not exists figure_type_id uuid references figure_types(id);

create index if not exists idx_entities_figure_type on entities(figure_type_id);

-- Types initiaux (§35), extensibles depuis le Dashboard Super Admin.
insert into figure_types (name_fr, name_ar, order_index) values
    ('Politicien', 'سياسي', 1),
    ('Acteur', 'ممثل', 2),
    ('Chanteur', 'مغني', 3),
    ('Sportif', 'رياضي', 4),
    ('Cuisinier', 'طاهي', 5),
    ('Agent d''accueil', 'موظف استقبال', 6),
    ('Employé d''administration publique', 'موظف إدارة عمومية', 7)
on conflict do nothing;

-- entity_cards_view (003) étendue pour inclure le type de figure.
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
    coalesce(cm.comments_count, 0) as comments_count
from entities e
left join cities c on c.id = e.city_id
left join zones z on z.id = e.zone_id
left join figure_types ft on ft.id = e.figure_type_id
left join entity_rating_summary r on r.entity_id = e.id
left join (
    select entity_id, count(*) as comments_count
    from comments
    where deleted_at is null
    group by entity_id
) cm on cm.entity_id = e.id
where e.status = 'active';

-- Rappel §37 : cette vue ne remonte JAMAIS created_by/owner_id — le nom
-- des évaluateurs n'est visible que par le Super Admin via un accès
-- direct à la table `ratings` (rôle service, hors de cette vue publique).
