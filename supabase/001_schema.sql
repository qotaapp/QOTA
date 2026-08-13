-- ============================================================
-- QOTA — SCHÉMA DE BASE DE DONNÉES (Supabase / Postgres)
-- Étape 1 du projet — Fondation de toute l'application
-- ============================================================
-- Principes respectés :
-- - Aucune donnée métier (États, Villes, Catégories) n'est codée en dur.
-- - Un seul système de Rating générique relié à une Entity.
-- - Séparation stricte Rating (étoiles) vs Commentaire (social).
-- - Propriété des Services non affichée publiquement mais tracée en backend.
-- - Anonymat des évaluateurs vis-à-vis du public uniquement (jamais vis-à-vis de Qota).
-- ============================================================

create extension if not exists "uuid-ossp";
create extension if not exists postgis; -- pour les coordonnées GPS et la proximité

-- ============================================================
-- 1. PROFILS UTILISATEURS
-- ============================================================

create table profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    first_name text not null,
    last_name text not null,
    age int,
    avatar_url text,
    -- Règle §8 : 1 changement de nom gratuit, compteur côté backend uniquement
    name_change_count int not null default 0,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create type app_role as enum ('user', 'moderator', 'super_admin');

create table user_roles (
    user_id uuid not null references profiles(id) on delete cascade,
    role app_role not null default 'user',
    granted_by uuid references profiles(id),
    granted_at timestamptz not null default now(),
    primary key (user_id, role)
);

-- ============================================================
-- 2. STRUCTURE GÉOGRAPHIQUE DYNAMIQUE (§14, §15, §17)
-- États -> Villes -> Zones, entièrement gérés par le Super Admin.
-- ============================================================

create table states (
    id uuid primary key default uuid_generate_v4(),
    name_fr text not null,
    name_ar text not null,
    order_index int not null default 0,
    active boolean not null default true,
    created_at timestamptz not null default now()
);

create table cities (
    id uuid primary key default uuid_generate_v4(),
    state_id uuid not null references states(id) on delete cascade,
    name_fr text not null,
    name_ar text not null,
    order_index int not null default 0,
    active boolean not null default true
);

create table zones (
    id uuid primary key default uuid_generate_v4(),
    city_id uuid not null references cities(id) on delete cascade,
    name_fr text not null,
    name_ar text not null,
    order_index int not null default 0,
    active boolean not null default true
);

-- ============================================================
-- 3. CATÉGORIES DYNAMIQUES (§16, §17)
-- Le Super Admin crée / modifie / réordonne sans toucher au code.
-- parent_category_id permet des sous-catégories futures.
-- ============================================================

create table categories (
    id uuid primary key default uuid_generate_v4(),
    parent_category_id uuid references categories(id),
    name_fr text not null,
    name_ar text not null,
    icon text, -- nom/identifiant de l'icône
    order_index int not null default 0,
    active boolean not null default true,
    created_at timestamptz not null default now()
);

-- ============================================================
-- 4. ENTITÉS (Services, User Items, Figures Publiques) — §18, §23, §35
-- Une seule table "entities" sert de support unique au Rating,
-- aux commentaires et aux likes (règle §27 : un seul système générique).
-- ============================================================

create type entity_kind as enum ('service', 'user_item', 'public_figure');
create type entity_status as enum ('active', 'pending_review', 'rejected');

create table entities (
    id uuid primary key default uuid_generate_v4(),
    kind entity_kind not null,

    name text not null,
    description text,
    image_url text not null, -- §19 / §23 : image obligatoire à la création

    -- Localisation (utilisée par Services, optionnelle pour User Items)
    state_id uuid references states(id),
    city_id uuid references cities(id),
    zone_id uuid references zones(id),
    category_id uuid references categories(id), -- utile pour Services et Figures publiques
    latitude double precision,
    longitude double precision,

    -- Propriété (§18, §22)
    created_by uuid not null references profiles(id),
    owner_id uuid references profiles(id), -- propriétaire reconnu (peut différer de created_by après transfert)
    -- IMPORTANT : owner_id / created_by ne doivent JAMAIS être exposés publiquement
    -- pour kind = 'service' ou 'public_figure'. Exposés uniquement pour 'user_item'.

    status entity_status not null default 'active',

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index idx_entities_kind on entities(kind);
create index idx_entities_location on entities(state_id, city_id, zone_id);
create index idx_entities_category on entities(category_id);

-- Détection de doublon (§19-20) : recherche par similarité de nom + proximité GPS.
create extension if not exists pg_trgm;
create index idx_entities_name_trgm on entities using gin (name gin_trgm_ops);

-- ============================================================
-- 5. DEMANDES DE PROPRIÉTÉ (Ownership Request) — §20, §22
-- ============================================================

create type ownership_request_status as enum ('pending', 'approved', 'rejected');

create table ownership_requests (
    id uuid primary key default uuid_generate_v4(),
    entity_id uuid not null references entities(id) on delete cascade,
    requester_id uuid not null references profiles(id),
    status ownership_request_status not null default 'pending',
    message text,
    decided_by uuid references profiles(id),
    decided_at timestamptz,
    created_at timestamptz not null default now()
);

-- Audit obligatoire du transfert de propriété (§22)
create table ownership_transfer_log (
    id uuid primary key default uuid_generate_v4(),
    entity_id uuid not null references entities(id),
    previous_owner_id uuid references profiles(id),
    new_owner_id uuid not null references profiles(id),
    ownership_request_id uuid references ownership_requests(id),
    performed_by uuid not null references profiles(id), -- Super Admin
    created_at timestamptz not null default now()
);

-- ============================================================
-- 6. RATING — système générique unique (§27, §28, §29, §30)
-- ============================================================

create table ratings (
    id uuid primary key default uuid_generate_v4(),
    entity_id uuid not null references entities(id) on delete cascade,
    user_id uuid not null references profiles(id) on delete cascade,
    score smallint not null check (score between 1 and 5),
    comment_text text,       -- optionnel, propre au Rating (différent des commentaires §31)
    image_url text,          -- optionnelle, une seule image max
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (user_id, entity_id) -- §28 : une seule évaluation active par utilisateur/entité
);

create index idx_ratings_entity on ratings(entity_id);

-- Vue publique agrégée (§25 : moyenne + nombre d'évaluations, jamais les noms)
create view entity_rating_summary as
select
    entity_id,
    round(avg(score)::numeric, 1) as average_score,
    count(*) as ratings_count
from ratings
group by entity_id;

-- ============================================================
-- 7. COMMENTAIRES, RÉPONSES, LIKES — §31, §32, §33, §34
-- ============================================================

create table comments (
    id uuid primary key default uuid_generate_v4(),
    entity_id uuid not null references entities(id) on delete cascade,
    user_id uuid not null references profiles(id) on delete cascade,
    text text not null,
    image_url text, -- autorisée uniquement sur le commentaire principal, pas sur les réponses
    deleted_at timestamptz,
    deleted_by uuid references profiles(id),
    created_at timestamptz not null default now()
);

create index idx_comments_entity on comments(entity_id);

create table comment_replies (
    id uuid primary key default uuid_generate_v4(),
    comment_id uuid not null references comments(id) on delete cascade,
    user_id uuid not null references profiles(id) on delete cascade,
    text text not null, -- §33 : jamais d'image sur une réponse
    deleted_at timestamptz,
    deleted_by uuid references profiles(id),
    created_at timestamptz not null default now()
);

create table comment_likes (
    comment_id uuid not null references comments(id) on delete cascade,
    user_id uuid not null references profiles(id) on delete cascade,
    created_at timestamptz not null default now(),
    primary key (comment_id, user_id) -- §32 : un seul like par utilisateur, toggle
);

create table reply_likes (
    reply_id uuid not null references comment_replies(id) on delete cascade,
    user_id uuid not null references profiles(id) on delete cascade,
    created_at timestamptz not null default now(),
    primary key (reply_id, user_id)
);

-- ============================================================
-- 8. QOTA COIN — Wallet & transactions (§3, §6)
-- ============================================================

create table wallets (
    user_id uuid primary key references profiles(id) on delete cascade,
    balance numeric(12,2) not null default 0,
    updated_at timestamptz not null default now()
);

create type wallet_tx_type as enum ('purchase', 'transfer_in', 'transfer_out', 'spend', 'refund');

create table wallet_transactions (
    id uuid primary key default uuid_generate_v4(),
    wallet_user_id uuid not null references wallets(user_id),
    type wallet_tx_type not null,
    amount numeric(12,2) not null,
    related_user_id uuid references profiles(id), -- pour les transferts P2P via QR code
    reference text, -- ex: id de la fonctionnalité achetée, id du changement de nom, etc.
    created_at timestamptz not null default now()
);

-- ============================================================
-- 9. NOTIFICATIONS (§38 — début de section, à compléter à l'étape suivante)
-- ============================================================

create table notifications (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid not null references profiles(id) on delete cascade,
    type text not null,
    payload jsonb not null default '{}',
    read_at timestamptz,
    created_at timestamptz not null default now()
);

create index idx_notifications_user on notifications(user_id, read_at);

-- ============================================================
-- 10. AUDIT GÉNÉRAL (sécurité, modération, historique — §18, §22, §37)
-- ============================================================

create table audit_log (
    id uuid primary key default uuid_generate_v4(),
    actor_id uuid references profiles(id),
    action text not null,
    target_type text not null,
    target_id uuid,
    metadata jsonb,
    created_at timestamptz not null default now()
);

-- ============================================================
-- NOTES POUR LA SUITE (Row Level Security à activer sur Supabase) :
-- - profiles : lecture publique des champs publics uniquement (nom, avatar).
-- - entities : created_by/owner_id jamais retournés au client pour kind != 'user_item'.
-- - ratings : le nom de l'utilisateur ne doit JAMAIS être joint côté client (§37) ;
--   seul le Super Admin (via un rôle service/admin) peut lire user_id.
-- - comments / replies : user_id peut être exposé (auteur visible, §31/§33).
-- - wallets / wallet_transactions : lecture strictement limitée au propriétaire.
-- Ces policies RLS seront écrites en détail à l'étape "Auth & sécurité".
-- ============================================================
