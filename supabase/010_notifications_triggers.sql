-- ============================================================
-- QOTA — NOTIFICATIONS (§38, complété en cohérence avec le reste
-- du cahier des charges)
-- ============================================================
-- Règle de confidentialité respectée (§37) :
-- - Commentaire / Réponse / Like -> identité déjà publique -> incluse.
-- - Nouvelle évaluation -> évaluateur anonyme -> PAS de nom transmis.
-- ============================================================

create or replace function public.notify_user(
    p_user_id uuid,
    p_type text,
    p_payload jsonb
)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
    if p_user_id is null then
        return;
    end if;
    insert into notifications (user_id, type, payload)
    values (p_user_id, p_type, p_payload);
end;
$$;

-- ============================================================
-- 1. NOUVEAU COMMENTAIRE -> propriétaire de l'entité (§31)
-- ============================================================

create or replace function public.trg_notify_new_comment()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
    v_entity record;
    v_author_name text;
begin
    select * into v_entity from entities where id = new.entity_id;
    select trim(first_name || ' ' || last_name) into v_author_name
    from profiles where id = new.user_id;

    if v_entity.owner_id is not null and v_entity.owner_id <> new.user_id then
        perform notify_user(
            v_entity.owner_id,
            'new_comment',
            jsonb_build_object(
                'entity_id', v_entity.id,
                'entity_name', v_entity.name,
                'comment_id', new.id,
                'author_name', v_author_name
            )
        );
    end if;
    return new;
end;
$$;

drop trigger if exists on_comment_created on comments;
create trigger on_comment_created
    after insert on comments
    for each row execute function public.trg_notify_new_comment();

-- ============================================================
-- 2. NOUVELLE RÉPONSE -> auteur du commentaire (§33)
-- ============================================================

create or replace function public.trg_notify_new_reply()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
    v_comment record;
    v_author_name text;
begin
    select * into v_comment from comments where id = new.comment_id;
    select trim(first_name || ' ' || last_name) into v_author_name
    from profiles where id = new.user_id;

    if v_comment.user_id <> new.user_id then
        perform notify_user(
            v_comment.user_id,
            'new_reply',
            jsonb_build_object(
                'comment_id', v_comment.id,
                'entity_id', v_comment.entity_id,
                'reply_id', new.id,
                'author_name', v_author_name
            )
        );
    end if;
    return new;
end;
$$;

drop trigger if exists on_reply_created on comment_replies;
create trigger on_reply_created
    after insert on comment_replies
    for each row execute function public.trg_notify_new_reply();

-- ============================================================
-- 3. LIKE SUR COMMENTAIRE / RÉPONSE -> auteur concerné (§32)
-- ============================================================

create or replace function public.trg_notify_comment_liked()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
    v_comment record;
    v_liker_name text;
begin
    select * into v_comment from comments where id = new.comment_id;
    select trim(first_name || ' ' || last_name) into v_liker_name
    from profiles where id = new.user_id;

    if v_comment.user_id <> new.user_id then
        perform notify_user(
            v_comment.user_id,
            'comment_liked',
            jsonb_build_object(
                'comment_id', v_comment.id,
                'entity_id', v_comment.entity_id,
                'liker_name', v_liker_name
            )
        );
    end if;
    return new;
end;
$$;

drop trigger if exists on_comment_liked on comment_likes;
create trigger on_comment_liked
    after insert on comment_likes
    for each row execute function public.trg_notify_comment_liked();

create or replace function public.trg_notify_reply_liked()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
    v_reply record;
    v_liker_name text;
begin
    select * into v_reply from comment_replies where id = new.reply_id;
    select trim(first_name || ' ' || last_name) into v_liker_name
    from profiles where id = new.user_id;

    if v_reply.user_id <> new.user_id then
        perform notify_user(
            v_reply.user_id,
            'reply_liked',
            jsonb_build_object(
                'reply_id', v_reply.id,
                'comment_id', v_reply.comment_id,
                'liker_name', v_liker_name
            )
        );
    end if;
    return new;
end;
$$;

drop trigger if exists on_reply_liked on reply_likes;
create trigger on_reply_liked
    after insert on reply_likes
    for each row execute function public.trg_notify_reply_liked();

-- ============================================================
-- 4. NOUVELLE ÉVALUATION -> propriétaire, SANS le nom (§27, §37)
-- ============================================================

create or replace function public.trg_notify_new_rating()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
    v_entity record;
begin
    select * into v_entity from entities where id = new.entity_id;

    if v_entity.owner_id is not null and v_entity.owner_id <> new.user_id then
        perform notify_user(
            v_entity.owner_id,
            'new_rating',
            jsonb_build_object(
                'entity_id', v_entity.id,
                'entity_name', v_entity.name,
                'score', new.score
                -- Volontairement AUCUN identifiant de l'évaluateur (§37).
            )
        );
    end if;
    return new;
end;
$$;

drop trigger if exists on_rating_created on ratings;
create trigger on_rating_created
    after insert on ratings
    for each row execute function public.trg_notify_new_rating();

-- ============================================================
-- 5. DEMANDE DE PROPRIÉTÉ TRANCHÉE -> demandeur (§20, §22)
-- ============================================================

create or replace function public.trg_notify_ownership_decision()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
    v_entity_name text;
begin
    if new.status <> old.status and new.status in ('approved', 'rejected') then
        select name into v_entity_name from entities where id = new.entity_id;
        perform notify_user(
            new.requester_id,
            'ownership_request_decided',
            jsonb_build_object(
                'entity_id', new.entity_id,
                'entity_name', v_entity_name,
                'status', new.status
            )
        );
    end if;
    return new;
end;
$$;

drop trigger if exists on_ownership_request_decided on ownership_requests;
create trigger on_ownership_request_decided
    after update on ownership_requests
    for each row execute function public.trg_notify_ownership_decision();

-- ============================================================
-- 6. RÉCEPTION DE QOTA COIN -> destinataire (§3)
-- ============================================================

create or replace function public.trg_notify_coin_received()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
    v_sender_name text;
begin
    if new.type = 'transfer_in' then
        select trim(first_name || ' ' || last_name) into v_sender_name
        from profiles where id = new.related_user_id;

        perform notify_user(
            new.wallet_user_id,
            'coin_received',
            jsonb_build_object(
                'amount', new.amount,
                'sender_name', v_sender_name
            )
        );
    end if;
    return new;
end;
$$;

drop trigger if exists on_coin_received on wallet_transactions;
create trigger on_coin_received
    after insert on wallet_transactions
    for each row execute function public.trg_notify_coin_received();
