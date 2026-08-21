-- ============================================================
-- QOTA — VUES : le propriétaire compte aussi (toutes publications)
-- ============================================================
-- §023/§025 excluaient le propriétaire de son propre compteur de
-- vues (d'abord partout, puis seulement pour User Item). Nouvelle
-- demande : plus aucune exclusion, quel que soit le type de
-- publication (User Item, Service, Figure Publique, Admin Listing) —
-- seule règle qui reste : une vue ne compte qu'UNE FOIS par
-- utilisateur (déduplication via entity_views, inchangée).
-- ============================================================

create or replace function public.increment_entity_views(p_entity_id uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
    v_viewer uuid := auth.uid();
    v_rows_inserted int;
begin
    if v_viewer is null then
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
