-- ============================================================
-- QOTA — CORRECTION DU COMPTEUR DE VUES (complète §016)
-- ============================================================
-- Problème : increment_entity_views() incrémentait +1 à CHAQUE
-- appel, sans aucune déduplication. Un utilisateur pouvait gonfler
-- artificiellement le compteur d'une publication (y compris la
-- sienne) simplement en rouvrant l'image plusieurs fois.
--
-- Correction : une "vue" ne compte désormais qu'UNE SEULE FOIS par
-- utilisateur et par publication (vues uniques, pas des clics), et
-- le propriétaire de la publication n'incrémente jamais son propre
-- compteur en la consultant. views_count reste un compteur
-- dénormalisé (rapide à lire), mais sa valeur est maintenant fiable.
-- ============================================================

create table if not exists entity_views (
    entity_id uuid not null references entities(id) on delete cascade,
    viewer_id uuid not null references profiles(id) on delete cascade,
    viewed_at timestamptz not null default now(),
    primary key (entity_id, viewer_id)
);

-- Aucune policy : ni le client ni personne ne lit/écrit cette table
-- directement, uniquement via increment_entity_views() (security
-- definer) ci-dessous. RLS activée = refus par défaut.
alter table entity_views enable row level security;

create or replace function public.increment_entity_views(p_entity_id uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
    v_viewer uuid := auth.uid();
    v_owner uuid;
    v_created_by uuid;
    v_rows_inserted int;
begin
    -- Visiteur anonyme (non connecté) : rien à dédupliquer de façon
    -- fiable, on ignore simplement plutôt que de fausser le compteur.
    if v_viewer is null then
        return;
    end if;

    select owner_id, created_by into v_owner, v_created_by
    from entities where id = p_entity_id;

    -- Le propriétaire qui consulte sa propre publication n'incrémente
    -- jamais son propre compteur de vues.
    if v_viewer = v_owner or v_viewer = v_created_by then
        return;
    end if;

    insert into entity_views (entity_id, viewer_id)
    values (p_entity_id, v_viewer)
    on conflict (entity_id, viewer_id) do nothing;

    get diagnostics v_rows_inserted = row_count;

    if v_rows_inserted > 0 then
        update entities
        set views_count = views_count + 1
        where id = p_entity_id;
    end if;
end;
$$;

grant execute on function public.increment_entity_views(uuid) to authenticated, anon;
