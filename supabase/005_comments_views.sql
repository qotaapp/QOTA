-- ============================================================
-- QOTA — VUES COMMENTAIRES / RÉPONSES (§31-33)
-- Le nom de l'auteur est PUBLIC pour les commentaires/réponses
-- (contrairement aux évaluateurs, cf. §37). liked_by_me utilise
-- auth.uid() : les vues Postgres s'exécutent par défaut en mode
-- "invoker", donc auth.uid() correspond bien à l'utilisateur courant.
-- ============================================================

create or replace view comments_with_likes as
select
    c.id,
    c.entity_id,
    c.user_id,
    trim(p.first_name || ' ' || p.last_name) as author_name,
    c.text,
    c.image_url,
    c.created_at,
    coalesce(l.likes_count, 0) as likes_count,
    exists(
        select 1 from comment_likes cl
        where cl.comment_id = c.id and cl.user_id = auth.uid()
    ) as liked_by_me
from comments c
join profiles p on p.id = c.user_id
left join (
    select comment_id, count(*) as likes_count
    from comment_likes
    group by comment_id
) l on l.comment_id = c.id
where c.deleted_at is null
order by c.created_at desc;

create or replace view replies_with_likes as
select
    r.id,
    r.comment_id,
    r.user_id,
    trim(p.first_name || ' ' || p.last_name) as author_name,
    r.text,
    r.created_at,
    coalesce(l.likes_count, 0) as likes_count,
    exists(
        select 1 from reply_likes rl
        where rl.reply_id = r.id and rl.user_id = auth.uid()
    ) as liked_by_me
from comment_replies r
join profiles p on p.id = r.user_id
left join (
    select reply_id, count(*) as likes_count
    from reply_likes
    group by reply_id
) l on l.reply_id = r.id
where r.deleted_at is null
order by r.created_at asc;
