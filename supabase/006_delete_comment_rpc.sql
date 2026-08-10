-- ============================================================
-- QOTA — SUPPRESSION DE COMMENTAIRE (§34)
-- Règle :
-- - User Item : le propriétaire du User Item peut supprimer
--   N'IMPORTE QUEL commentaire publié dessus.
-- - Service : le propriétaire de la Service N'A PAS ce droit.
--   Seuls l'auteur du commentaire, un Moderator ou le Super Admin
--   peuvent supprimer.
-- Cette règle est appliquée ICI, côté serveur, pour ne pas dépendre
-- du client Flutter (sécurité).
-- ============================================================

create or replace function public.delete_comment(p_comment_id uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
    v_comment record;
    v_entity record;
    v_caller uuid := auth.uid();
    v_is_moderator boolean;
begin
    select * into v_comment from comments where id = p_comment_id and deleted_at is null;
    if v_comment is null then
        raise exception 'Commentaire introuvable';
    end if;

    select * into v_entity from entities where id = v_comment.entity_id;

    select exists(
        select 1 from user_roles
        where user_id = v_caller and role in ('moderator', 'super_admin')
    ) into v_is_moderator;

    if v_caller = v_comment.user_id then
        -- L'auteur peut toujours supprimer son propre commentaire.
        null;
    elsif v_is_moderator then
        -- Moderator / Super Admin peuvent toujours supprimer.
        null;
    elsif v_entity.kind = 'user_item' and v_entity.owner_id = v_caller then
        -- Propriétaire du User Item : droit étendu (§34).
        null;
    else
        raise exception 'Action non autorisée';
    end if;

    update comments
    set deleted_at = now(), deleted_by = v_caller
    where id = p_comment_id;
end;
$$;

grant execute on function public.delete_comment(uuid) to authenticated;
