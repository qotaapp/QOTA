-- ============================================================
-- QOTA — CHANGEMENT DE NOM (§8)
-- "L'utilisateur peut modifier son nom une seule fois gratuitement.
--  Une deuxième tentative de changement de nom doit entrer dans le
--  système de monétisation. Le compteur doit être conservé côté
--  backend et ne doit pas dépendre du téléphone ou de l'app locale."
--
-- Implémentation : le 1er changement (name_change_count = 0) est
-- gratuit. À partir du 2ème, le coût est débité du Wallet Qota Coin.
-- Si le solde est insuffisant, la fonction renvoie un statut dédié
-- que le client traduit en écran d'achat de Qota Coin.
-- ============================================================

create table if not exists monetization_prices (
    key text primary key,
    price numeric(12,2) not null
);

insert into monetization_prices (key, price)
values ('name_change', 20)
on conflict (key) do nothing;

create or replace function public.change_user_name(
    p_first_name text,
    p_last_name text
)
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare
    v_user_id uuid := auth.uid();
    v_count int;
    v_price numeric(12,2);
    v_balance numeric(12,2);
begin
    if v_user_id is null then
        raise exception 'Non authentifié';
    end if;

    select name_change_count into v_count from profiles where id = v_user_id for update;

    if v_count = 0 then
        -- §8 : premier changement gratuit.
        update profiles
        set first_name = p_first_name, last_name = p_last_name,
            name_change_count = name_change_count + 1, updated_at = now()
        where id = v_user_id;

        return jsonb_build_object('status', 'success', 'charged', false);
    end if;

    -- Changements suivants : entrent dans le système de monétisation.
    select price into v_price from monetization_prices where key = 'name_change';
    select balance into v_balance from wallets where user_id = v_user_id for update;

    if v_balance < v_price then
        return jsonb_build_object(
            'status', 'insufficient_funds',
            'price', v_price,
            'balance', v_balance
        );
    end if;

    update wallets set balance = balance - v_price, updated_at = now() where user_id = v_user_id;

    insert into wallet_transactions (wallet_user_id, type, amount, reference)
    values (v_user_id, 'spend', -v_price, 'name_change');

    update profiles
    set first_name = p_first_name, last_name = p_last_name,
        name_change_count = name_change_count + 1, updated_at = now()
    where id = v_user_id;

    insert into audit_log (actor_id, action, target_type, target_id)
    values (v_user_id, 'name_change_paid', 'profiles', v_user_id);

    return jsonb_build_object('status', 'success', 'charged', true, 'price', v_price);
end;
$$;

grant execute on function public.change_user_name(text, text) to authenticated;
