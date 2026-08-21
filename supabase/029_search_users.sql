-- ============================================================
-- QOTA — RECHERCHE D'UTILISATEURS (§12, extension)
-- Permet de retrouver d'autres utilisateurs par prénom/nom depuis
-- la barre de recherche. Fonction security definer : contourne la
-- RLS de `profiles` ("Users read own profile") de façon contrôlée,
-- en ne renvoyant QUE les champs déjà publics ailleurs dans l'app
-- (prénom, nom, avatar — les mêmes que public_profiles_view), et
-- jamais l'âge ni le compteur de changement de nom.
-- ============================================================

create or replace function public.search_users(
    p_query text,
    p_limit int default 15
)
returns table (
    id uuid,
    first_name text,
    last_name text,
    avatar_url text,
    relevance real
)
language sql
stable
security definer set search_path = public
as $$
    select
        p.id,
        p.first_name,
        p.last_name,
        p.avatar_url,
        greatest(
            similarity(p.first_name, p_query),
            similarity(p.last_name, p_query),
            similarity(p.first_name || ' ' || p.last_name, p_query)
        ) as relevance
    from profiles p
    where p.id <> coalesce(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
      and (
          p.first_name ilike '%' || p_query || '%'
          or p.last_name ilike '%' || p_query || '%'
          or (p.first_name || ' ' || p.last_name) ilike '%' || p_query || '%'
          or similarity(p.first_name || ' ' || p.last_name, p_query) > 0.2
      )
    order by relevance desc, p.first_name asc
    limit p_limit;
$$;

grant execute on function public.search_users(text, int) to authenticated, anon;
