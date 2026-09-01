-- ============================================================
-- QOTA — DEMANDES D'ACHAT QOTA COIN : REFUS + COMMUNICATION
-- ============================================================
-- Le code Flutter (AdminCoinPurchasesScreen) appelle déjà
-- reject_coin_purchase() et send_coin_purchase_message(), mais ces
-- fonctions n'existaient pas encore côté base — seule
-- approve_coin_purchase() (§011) avait été créée. Complète le
-- parcours : le Super Admin peut désormais aussi refuser une
-- demande, et échanger un message avec le demandeur (ex. pour
-- convenir de la méthode de paiement) AVANT de valider ou refuser —
-- envoyé comme notification (notify_user, §010), sans changer le
-- statut de la demande.
-- ============================================================

-- ---------------- 1. REFUS ----------------

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
        select 1 from user_roles
        where user_id = v_caller and role = 'super_admin'
    ) into v_is_admin;

    if not v_is_admin then
        raise exception 'Action réservée au Super Admin';
    end if;

    select * into v_request from coin_purchase_requests
    where id = p_request_id and status = 'pending';

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

-- ---------------- 2. VALIDATION : notifie désormais le demandeur ----------------
-- Reprend EXACTEMENT approve_coin_purchase (§011) ; seul l'ajout du
-- perform notify_user(...) final change.

create or replace function public.approve_coin_purchase(p_request_id uuid)
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
        select 1 from user_roles
        where user_id = v_caller and role = 'super_admin'
    ) into v_is_admin;

    if not v_is_admin then
        raise exception 'Action réservée au Super Admin';
    end if;

    select * into v_request from coin_purchase_requests
    where id = p_request_id and status = 'pending';

    if v_request is null then
        raise exception 'Demande introuvable ou déjà traitée';
    end if;

    update coin_purchase_requests
    set status = 'approved', decided_by = v_caller, decided_at = now()
    where id = p_request_id;

    update wallets set balance = balance + v_request.amount, updated_at = now()
    where user_id = v_request.user_id;

    insert into wallet_transactions (wallet_user_id, type, amount, reference)
    values (v_request.user_id, 'purchase', v_request.amount, p_request_id::text);

    perform notify_user(
        v_request.user_id,
        'coin_purchase_approved',
        jsonb_build_object('request_id', p_request_id, 'amount', v_request.amount)
    );
end;
$$;

grant execute on function public.approve_coin_purchase(uuid) to authenticated;

-- ---------------- 3. COMMUNICATION (méthode de paiement, etc.) ----------------

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
        select 1 from user_roles
        where user_id = v_caller and role = 'super_admin'
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
