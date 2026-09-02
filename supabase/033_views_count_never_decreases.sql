-- ============================================================
-- QOTA — GARDE-FOU : views_count NE DOIT JAMAIS DÉCROÎTRE
-- Sécurité défensive, indépendante de la RPC increment_entity_views
-- (qui n'incrémente déjà que de +1) : ce trigger bloque physiquement
-- toute tentative de faire baisser le compteur, quelle qu'en soit la
-- source (RPC, édition Admin, futur bug client) — sans bloquer les
-- mises à jour légitimes qui ne touchent pas cette colonne.
-- ============================================================

create or replace function public.trg_prevent_views_count_decrease()
returns trigger
language plpgsql
as $$
begin
    if new.views_count < old.views_count then
        new.views_count := old.views_count;
    end if;
    return new;
end;
$$;

drop trigger if exists on_entities_prevent_views_decrease on entities;
create trigger on_entities_prevent_views_decrease
    before update on entities
    for each row execute function public.trg_prevent_views_count_decrease();
