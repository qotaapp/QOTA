-- ============================================================
-- QOTA — STORIES (photo/vidéo éphémères, max 40s, disparaissent
-- après 24h) — affichées sous la barre "Qu'allons-nous évaluer ?"
-- ============================================================
-- La disparition après 24h est gérée uniquement CÔTÉ REQUÊTE
-- (created_at >= now() - interval '24 hours'), pas par suppression :
-- aucune tâche planifiée nécessaire, les lignes restent en base.
-- ============================================================

create table if not exists stories (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid not null references profiles(id) on delete cascade,
    media_url text not null,
    media_type text not null check (media_type in ('image', 'video')),
    duration_seconds int,
    created_at timestamptz not null default now()
);

create index if not exists idx_stories_created on stories(created_at desc);
create index if not exists idx_stories_user on stories(user_id, created_at desc);

alter table stories enable row level security;

-- Lecture publique (même logique que le Feed) — le filtre des 24h
-- est appliqué côté client dans la requête, pas ici.
create policy "Public read stories" on stories
    for select using (true);

create policy "Users create own stories" on stories
    for insert with check (user_id = auth.uid());

create policy "Users delete own stories" on stories
    for delete using (user_id = auth.uid());
