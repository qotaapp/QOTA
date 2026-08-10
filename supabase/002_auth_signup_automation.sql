-- ============================================================
-- QOTA — MIGRATION : AUTOMATISATION DE LA CRÉATION DE COMPTE (§6)
-- "Lors de la création du compte : créer le compte Auth, créer le
--  profil, créer automatiquement le Wallet Qota Coin, créer le
--  compte de stockage, initialiser les paramètres nécessaires."
-- À exécuter après qota_schema.sql.
-- ============================================================

-- Le Flutter envoie first_name / last_name / age dans les
-- `data` (raw_user_meta_data) de auth.signUp(). Ce trigger les récupère
-- pour créer automatiquement la ligne profiles + le wallet associé,
-- sans dépendre du client (règle §8 : le compteur est côté backend).

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
    insert into public.profiles (id, first_name, last_name, age)
    values (
        new.id,
        coalesce(new.raw_user_meta_data->>'first_name', ''),
        coalesce(new.raw_user_meta_data->>'last_name', ''),
        nullif(new.raw_user_meta_data->>'age', '')::int
    );

    insert into public.wallets (user_id, balance)
    values (new.id, 0);

    insert into public.user_roles (user_id, role)
    values (new.id, 'user');

    return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_auth_user();

-- ============================================================
-- Compte de stockage (§6) : sur Supabase, le stockage est un bucket
-- partagé avec politique RLS par dossier {user_id}/..., pas un bucket
-- par utilisateur. On crée le bucket une seule fois (idempotent).
-- ============================================================

insert into storage.buckets (id, name, public)
values ('user-content', 'user-content', true)
on conflict (id) do nothing;

-- Politique : chaque utilisateur ne peut écrire que dans son propre dossier.
create policy "Users can upload to their own folder"
on storage.objects for insert
to authenticated
with check (
    bucket_id = 'user-content'
    and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Anyone can view user-content (public app)"
on storage.objects for select
to public
using (bucket_id = 'user-content');
