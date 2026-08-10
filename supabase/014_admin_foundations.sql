-- ============================================================
-- QOTA — FONDATIONS DASHBOARD SUPER ADMIN
-- ============================================================

-- Helper réutilisable dans toutes les policies RLS de gestion.
create or replace function public.is_super_admin()
returns boolean
language sql
stable
security definer set search_path = public
as $$
    select exists(
        select 1 from user_roles
        where user_id = auth.uid() and role = 'super_admin'
    );
$$;

create or replace function public.is_moderator_or_admin()
returns boolean
language sql
stable
security definer set search_path = public
as $$
    select exists(
        select 1 from user_roles
        where user_id = auth.uid() and role in ('moderator', 'super_admin')
    );
$$;

-- ============================================================
-- ÉTATS / VILLES / ZONES / CATÉGORIES / TYPES DE FIGURES (§14-17, §35)
-- Lecture publique du contenu actif ; écriture réservée au Super Admin.
-- ============================================================

alter table states enable row level security;
alter table cities enable row level security;
alter table zones enable row level security;
alter table categories enable row level security;
alter table figure_types enable row level security;

create policy "Public read active states" on states for select using (active = true or is_super_admin());
create policy "Admin manage states" on states for insert with check (is_super_admin());
create policy "Admin update states" on states for update using (is_super_admin());
create policy "Admin delete states" on states for delete using (is_super_admin());

create policy "Public read active cities" on cities for select using (active = true or is_super_admin());
create policy "Admin manage cities" on cities for insert with check (is_super_admin());
create policy "Admin update cities" on cities for update using (is_super_admin());
create policy "Admin delete cities" on cities for delete using (is_super_admin());

create policy "Public read active zones" on zones for select using (active = true or is_super_admin());
create policy "Admin manage zones" on zones for insert with check (is_super_admin());
create policy "Admin update zones" on zones for update using (is_super_admin());
create policy "Admin delete zones" on zones for delete using (is_super_admin());

create policy "Public read active categories" on categories for select using (active = true or is_super_admin());
create policy "Admin manage categories" on categories for insert with check (is_super_admin());
create policy "Admin update categories" on categories for update using (is_super_admin());
create policy "Admin delete categories" on categories for delete using (is_super_admin());

create policy "Public read active figure_types" on figure_types for select using (active = true or is_super_admin());
create policy "Admin manage figure_types" on figure_types for insert with check (is_super_admin());
create policy "Admin update figure_types" on figure_types for update using (is_super_admin());
create policy "Admin delete figure_types" on figure_types for delete using (is_super_admin());

-- ============================================================
-- OWNERSHIP REQUESTS — visibilité + décision (§20, §22)
-- ============================================================

alter table ownership_requests enable row level security;

create policy "See own or admin ownership requests" on ownership_requests
    for select using (requester_id = auth.uid() or is_super_admin());

create policy "Users create ownership requests" on ownership_requests
    for insert with check (requester_id = auth.uid());

-- La décision (approve/reject) passe exclusivement par la RPC ci-dessous,
-- qui gère aussi le transfert effectif de owner_id + l'audit (§22).
create or replace function public.decide_ownership_request(
    p_request_id uuid,
    p_approve boolean
)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
    v_caller uuid := auth.uid();
    v_request record;
    v_previous_owner uuid;
begin
    if not is_super_admin() then
        raise exception 'Action réservée au Super Admin';
    end if;

    select * into v_request from ownership_requests where id = p_request_id and status = 'pending';
    if v_request is null then
        raise exception 'Demande introuvable ou déjà traitée';
    end if;

    update ownership_requests
    set status = case when p_approve then 'approved' else 'rejected' end,
        decided_by = v_caller, decided_at = now()
    where id = p_request_id;

    if p_approve then
        select owner_id into v_previous_owner from entities where id = v_request.entity_id;

        update entities set owner_id = v_request.requester_id, updated_at = now()
        where id = v_request.entity_id;

        insert into ownership_transfer_log (entity_id, previous_owner_id, new_owner_id, ownership_request_id, performed_by)
        values (v_request.entity_id, v_previous_owner, v_request.requester_id, p_request_id, v_caller);
    end if;
    -- Le trigger on_ownership_request_decided (010) notifie le demandeur.
end;
$$;

grant execute on function public.decide_ownership_request(uuid, boolean) to authenticated;

-- ============================================================
-- COIN PURCHASE REQUESTS — visibilité (§011 gère déjà la décision)
-- ============================================================

alter table coin_purchase_requests enable row level security;

create policy "See own or admin coin purchase requests" on coin_purchase_requests
    for select using (user_id = auth.uid() or is_super_admin());

create policy "Users create coin purchase requests" on coin_purchase_requests
    for insert with check (user_id = auth.uid());
