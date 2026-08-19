-- ============================================================
-- QOTA — PROFIL AUTOMATIQUE DEPUIS GOOGLE / FACEBOOK (§6)
-- ============================================================
-- handle_new_auth_user() (§002) ne lisait que first_name/last_name/
-- age — les champs envoyés par le formulaire d'inscription e-mail.
-- Un compte créé via Google/Facebook (signInWithOAuth) n'envoie
-- jamais ces champs : Supabase y place plutôt full_name / name /
-- given_name / family_name / avatar_url / picture (selon le
-- provider) dans raw_user_meta_data. Sans ce correctif, un compte
-- Google/Facebook se serait retrouvé avec un nom vide.
--
-- 'age' reste nullable (déjà le cas dans le schéma) : Google/
-- Facebook ne le fournissent jamais, l'utilisateur pourra le
-- compléter plus tard depuis son profil si le besoin s'en fait sentir.
-- ============================================================

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
    v_meta jsonb := new.raw_user_meta_data;
    v_full_name text;
    v_first_name text;
    v_last_name text;
    v_space_pos int;
begin
    -- Priorité au formulaire d'inscription e-mail (first_name/last_name).
    v_first_name := v_meta->>'first_name';
    v_last_name := v_meta->>'last_name';

    if v_first_name is null or v_first_name = '' then
        -- Sinon, champs normalisés que Supabase remplit pour Google
        -- (given_name/family_name) ou, à défaut, on découpe full_name/name
        -- (rempli par Google ET Facebook) sur le premier espace.
        v_first_name := v_meta->>'given_name';
        v_last_name := v_meta->>'family_name';

        if v_first_name is null or v_first_name = '' then
            v_full_name := coalesce(v_meta->>'full_name', v_meta->>'name');
            if v_full_name is not null and v_full_name <> '' then
                v_space_pos := position(' ' in v_full_name);
                if v_space_pos > 0 then
                    v_first_name := substring(v_full_name from 1 for v_space_pos - 1);
                    v_last_name := substring(v_full_name from v_space_pos + 1);
                else
                    v_first_name := v_full_name;
                end if;
            end if;
        end if;
    end if;

    insert into public.profiles (id, first_name, last_name, age, avatar_url)
    values (
        new.id,
        coalesce(v_first_name, ''),
        coalesce(v_last_name, ''),
        nullif(v_meta->>'age', '')::int,
        coalesce(v_meta->>'avatar_url', v_meta->>'picture')
    );

    insert into public.wallets (user_id, balance)
    values (new.id, 0);

    insert into public.user_roles (user_id, role)
    values (new.id, 'user');

    return new;
end;
$$;
-- (trigger on_auth_user_created déjà créé en §002, inchangé)
