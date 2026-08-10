-- ============================================================
-- QOTA — WALLET QOTA COIN : ACHAT + TRANSFERT QR (§3)
-- "Utiliser Qota Coin / acheter des Qota Coin auprès de
--  l'administration Qota / transférer des Qota Coin à un autre
--  utilisateur via QR Code."
--
-- Sécurité : un utilisateur ne peut JAMAIS créditer lui-même son
-- wallet directement (ce serait une faille triviale). L'achat passe
-- par une demande validée par l'administration Qota (Super Admin) —
-- cohérent avec "auprès de l'administration Qota". Le transfert P2P
-- est atomique et vérifie le solde côté serveur.
-- ============================================================

create type coin_purchase_status as enum ('pending', 'approved', 'rejected');

create table coin_purchase_requests (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid not null references profiles(id) on delete cascade,
    amount numeric(12,2) not null check (amount > 0),
    payment_reference text, -- référence du paiement externe (à intégrer avec un vrai gateway plus tard)
    status coin_purchase_status not null default 'pending',
    decided_by uuid references profiles(id),
    decided_at timestamptz,
    created_at timestamptz not null default now()
);

-- ============================================================
-- 1. DEMANDE D'ACHAT (créée par l'utilisateur, ne crédite rien seule)
-- ============================================================

create or replace function public.request_coin_purchase(
    p_amount numeric,
    p_payment_reference text default null
)
returns uuid
language plpgsql
security definer set search_path = public
as $$
declare
    v_user_id uuid := auth.uid();
    v_request_id uuid;
begin
    if p_amount <= 0 then
        raise exception 'Montant invalide';
    end if;

    insert into coin_purchase_requests (user_id, amount, payment_reference)
    values (v_user_id, p_amount, p_payment_reference)
    returning id into v_request_id;

    return v_request_id;
end;
$$;

grant execute on function public.request_coin_purchase(numeric, text) to authenticated;

-- ============================================================
-- 2. VALIDATION (réservée au Super Admin — utilisée par le futur
--    Dashboard). Crédite le wallet seulement à ce moment-là.
-- ============================================================

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
    set status = 'approved', decided_by = v_caller, decided_at = now()
    where id = p_request_id;

    update wallets set balance = balance + v_request.amount, updated_at = now()
    where user_id = v_request.user_id;

    insert into wallet_transactions (wallet_user_id, type, amount, reference)
    values (v_request.user_id, 'purchase', v_request.amount, p_request_id::text);
end;
$$;

grant execute on function public.approve_coin_purchase(uuid) to authenticated;

-- ============================================================
-- 3. TRANSFERT P2P VIA QR CODE — atomique, vérifie le solde (§3)
-- ============================================================

create or replace function public.transfer_qota_coin(
    p_recipient_id uuid,
    p_amount numeric
)
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare
    v_sender_id uuid := auth.uid();
    v_sender_balance numeric(12,2);
begin
    if p_amount <= 0 then
        raise exception 'Montant invalide';
    end if;

    if p_recipient_id = v_sender_id then
        raise exception 'Impossible de se transférer des Qota Coin à soi-même';
    end if;

    if not exists (select 1 from profiles where id = p_recipient_id) then
        raise exception 'Destinataire introuvable';
    end if;

    select balance into v_sender_balance from wallets where user_id = v_sender_id for update;

    if v_sender_balance < p_amount then
        return jsonb_build_object('status', 'insufficient_funds', 'balance', v_sender_balance);
    end if;

    update wallets set balance = balance - p_amount, updated_at = now() where user_id = v_sender_id;
    update wallets set balance = balance + p_amount, updated_at = now() where user_id = p_recipient_id;

    insert into wallet_transactions (wallet_user_id, type, amount, related_user_id)
    values (v_sender_id, 'transfer_out', -p_amount, p_recipient_id);

    insert into wallet_transactions (wallet_user_id, type, amount, related_user_id)
    values (p_recipient_id, 'transfer_in', p_amount, v_sender_id);
    -- Le trigger on_coin_received (010) notifie automatiquement le destinataire.

    return jsonb_build_object('status', 'success');
end;
$$;

grant execute on function public.transfer_qota_coin(uuid, numeric) to authenticated;
