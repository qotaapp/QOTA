-- ============================================================
-- QOTA — MESSAGE À 2 CHOIX (Super Admin -> demandeur) SUR UNE
-- DEMANDE D'ACHAT QOTA COIN
-- ============================================================
-- Le Super Admin écrit un message ET le texte de 2 boutons-réponse
-- (ex: "Payé via D17" / "Pas encore payé") ; le demandeur doit
-- choisir l'un des deux. Le choix est visible par le Super Admin
-- directement à côté de la demande dans Achats Qota Coin — pas
-- besoin d'un fil de discussion complet pour ça.
-- ============================================================

alter table coin_purchase_requests
    add column if not exists pending_message jsonb,
    add column if not exists user_response text;

-- Remplace send_coin_purchase_message(uuid, text) par une version à
-- 4 arguments (message + 2 options). L'ancienne signature est
-- retirée : le code Flutter n'appelle plus que la nouvelle.
drop function if exists public.send_coin_purchase_message(uuid, text);

create or replace function public.send_coin_purchase_message(
    p_request_id uuid,
    p_message text,
    p_option_a text,
    p_option_b text
)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
    v_caller uuid := auth.uid();
    v_is_admin boolean;
    v_request record;
    v_payload jsonb;
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

    v_payload := jsonb_build_object(
        'message', p_message,
        'option_a', p_option_a,
        'option_b', p_option_b
    );

    update coin_purchase_requests
    set pending_message = v_payload, user_response = null
    where id = p_request_id;

    perform notify_user(
        v_request.user_id,
        'coin_purchase_message',
        jsonb_build_object(
            'request_id', p_request_id,
            'amount', v_request.amount,
            'message', p_message,
            'option_a', p_option_a,
            'option_b', p_option_b
        )
    );
end;
$$;

grant execute on function
    public.send_coin_purchase_message(uuid, text, text, text) to authenticated;

-- Le demandeur choisit l'une des 2 options envoyées par le Super
-- Admin. Visible ensuite dans Achats Qota Coin (user_response).
create or replace function public.respond_coin_purchase_message(
    p_request_id uuid,
    p_chosen text
)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
    v_caller uuid := auth.uid();
    v_request record;
begin
    select * into v_request from coin_purchase_requests
    where id = p_request_id;

    if v_request is null or v_request.user_id <> v_caller then
        raise exception 'Demande introuvable';
    end if;

    if v_request.pending_message is null then
        raise exception 'Aucun message en attente de réponse';
    end if;

    if p_chosen <> (v_request.pending_message ->> 'option_a')
       and p_chosen <> (v_request.pending_message ->> 'option_b') then
        raise exception 'Réponse invalide';
    end if;

    update coin_purchase_requests
    set user_response = p_chosen
    where id = p_request_id;
end;
$$;

grant execute on function
    public.respond_coin_purchase_message(uuid, text) to authenticated;
