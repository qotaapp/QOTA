-- ============================================================
-- QOTA — ACHATS QOTA COIN : REFUS + COMMUNICATION AVEC LE DEMANDEUR
-- ============================================================
-- La demande, l'approbation et le crédit du wallet existaient déjà
-- (§011). Il manquait : le refus (symétrique de l'approbation), et
-- un moyen pour le Super Admin de communiquer avec le demandeur
-- (convenir de la méthode de paiement) avant de décider — via le
-- système de notifications déjà en place (§010), pas un nouveau
-- système de chat.
-- ============================================================

create or replace function public.reject_coin_purchase(
    p_request_id uuid,
    p_note text default null
)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
    v_caller uuid := auth.uid();
    v_is_admin boolean;
    v_request record;
begin
    select exists(
        select 1 from user_roles where user_id = v_caller and role = 'super_admin'
    ) into v_is_admin;

    if not v_is_admin then
        raise exception 'Action réservée au Super Admin';
    end if;

    select * into v_request from coin_purchase_requests where id = p_request_id and status = 'pending';
    if v_request is null then
        raise exception 'Demande introuvable ou déjà traitée';
    end if;

    update coin_purchase_requests
    set status = 'rejected', decided_by = v_caller, decided_at = now()
    where id = p_request_id;

    perform notify_user(
        v_request.user_id,
        'coin_purchase_rejected',
        jsonb_build_object(
            'request_id', p_request_id,
            'amount', v_request.amount,
            'note', p_note
        )
    );
end;
$$;

grant execute on function public.reject_coin_purchase(uuid, text) to authenticated;

-- Message libre du Super Admin vers le demandeur (négociation de la
-- méthode de paiement) — n'importe quel nombre de fois, ne change
-- jamais le statut de la demande. La réponse du demandeur se fait
-- hors app (téléphone, etc.) : voir la limite indiquée à l'utilisateur.
create or replace function public.send_coin_purchase_message(
    p_request_id uuid,
    p_message text
)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
    v_caller uuid := auth.uid();
    v_is_admin boolean;
    v_request record;
begin
    select exists(
        select 1 from user_roles where user_id = v_caller and role = 'super_admin'
    ) into v_is_admin;

    if not v_is_admin then
        raise exception 'Action réservée au Super Admin';
    end if;

    select * into v_request from coin_purchase_requests where id = p_request_id;
    if v_request is null then
        raise exception 'Demande introuvable';
    end if;

    perform notify_user(
        v_request.user_id,
        'coin_purchase_message',
        jsonb_build_object(
            'request_id', p_request_id,
            'amount', v_request.amount,
            'message', p_message
        )
    );
end;
$$;

grant execute on function public.send_coin_purchase_message(uuid, text) to authenticated;
