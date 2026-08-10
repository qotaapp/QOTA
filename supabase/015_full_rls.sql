-- ============================================================
-- QOTA — RLS COMPLÈTE (dernière étape de sécurité)
-- Principe : tout est refusé par défaut dès que RLS est activée ;
-- on n'ouvre que le strict nécessaire. Les opérations sensibles
-- (wallet, notifications, transferts) passent EXCLUSIVEMENT par des
-- fonctions security definer déjà écrites — donc AUCUNE policy
-- d'écriture directe n'est ajoutée pour elles ici (c'est volontaire).
-- ============================================================

-- ---------------- PROFILES ----------------
-- Les champs publics (nom, avatar) sont exposés via les vues dédiées
-- (comments_with_likes, user_items_view...), qui s'exécutent avec les
-- privilèges de leur créateur et ne sont donc pas bloquées par cette
-- policy. La table brute, elle, reste privée (âge, compteur de nom...).
alter table profiles enable row level security;

create policy "Users read own profile" on profiles
    for select using (id = auth.uid() or is_super_admin());

create policy "Users update own profile" on profiles
    for update using (id = auth.uid());
-- Pas de policy insert : la création passe uniquement par le trigger
-- handle_new_auth_user (security definer, §002).

-- ---------------- USER_ROLES ----------------
alter table user_roles enable row level security;

create policy "Users read own roles" on user_roles
    for select using (user_id = auth.uid() or is_super_admin());

create policy "Admin manage roles" on user_roles
    for insert with check (is_super_admin());
create policy "Admin update roles" on user_roles
    for update using (is_super_admin());
create policy "Admin delete roles" on user_roles
    for delete using (is_super_admin());
-- Le rôle 'user' initial est inséré par le trigger de signup (bypass RLS).

-- ---------------- ENTITIES (Services / User Items / Figures) ----------------
alter table entities enable row level security;

create policy "Public read active entities" on entities
    for select using (
        status = 'active' or created_by = auth.uid() or owner_id = auth.uid() or is_super_admin()
    );

create policy "Users create entities" on entities
    for insert with check (created_by = auth.uid());

create policy "Owners update own entities" on entities
    for update using (created_by = auth.uid() or is_super_admin());
-- owner_id n'est modifié que par decide_ownership_request (security definer) —
-- cette policy autorise la mise à jour des AUTRES champs (nom, image...) par
-- le créateur, mais l'app ne propose jamais de modifier owner_id depuis le client.

create policy "Admin delete entities" on entities
    for delete using (is_super_admin());

-- ---------------- RATINGS ----------------
-- §37 : l'identité de l'évaluateur n'est jamais publique. Seul le
-- Super Admin (historique administratif) et l'auteur lui-même
-- peuvent lire une ligne de rating brute. Les moyennes publiques
-- passent par entity_rating_summary (vue, bypass RLS en lecture).
alter table ratings enable row level security;

create policy "Users read own ratings" on ratings
    for select using (user_id = auth.uid() or is_super_admin());

create policy "Users create own ratings" on ratings
    for insert with check (user_id = auth.uid());

create policy "Users update own ratings" on ratings
    for update using (user_id = auth.uid());

create policy "Users or admin delete ratings" on ratings
    for delete using (user_id = auth.uid() or is_super_admin());

-- ---------------- COMMENTS ----------------
-- §31 : l'auteur d'un commentaire est public -> lecture ouverte aux
-- utilisateurs connectés. Suppression EXCLUSIVEMENT via la fonction
-- delete_comment (§34, security definer) : aucune policy delete/update
-- n'est ajoutée ici, ce qui bloque toute suppression directe côté client.
alter table comments enable row level security;

create policy "Authenticated read comments" on comments
    for select to authenticated using (true);

create policy "Users create own comments" on comments
    for insert with check (user_id = auth.uid());

-- ---------------- COMMENT_REPLIES ----------------
alter table comment_replies enable row level security;

create policy "Authenticated read replies" on comment_replies
    for select to authenticated using (true);

create policy "Users create own replies" on comment_replies
    for insert with check (user_id = auth.uid());

-- ---------------- LIKES (commentaires / réponses) ----------------
-- §32 : toggle géré directement par le client (insert/delete simples).
alter table comment_likes enable row level security;

create policy "Authenticated read comment likes" on comment_likes
    for select to authenticated using (true);
create policy "Users like comments" on comment_likes
    for insert with check (user_id = auth.uid());
create policy "Users unlike own comment like" on comment_likes
    for delete using (user_id = auth.uid());

alter table reply_likes enable row level security;

create policy "Authenticated read reply likes" on reply_likes
    for select to authenticated using (true);
create policy "Users like replies" on reply_likes
    for insert with check (user_id = auth.uid());
create policy "Users unlike own reply like" on reply_likes
    for delete using (user_id = auth.uid());

-- ---------------- WALLETS ----------------
-- Lecture seule côté client. TOUTE écriture (achat, transfert, dépense)
-- passe par les fonctions security definer déjà écrites (§007, §011) —
-- volontairement AUCUNE policy insert/update/delete ici : un utilisateur
-- ne peut jamais modifier directement son solde.
alter table wallets enable row level security;

create policy "Users read own wallet" on wallets
    for select using (user_id = auth.uid() or is_super_admin());

-- ---------------- WALLET_TRANSACTIONS ----------------
alter table wallet_transactions enable row level security;

create policy "Users read own wallet transactions" on wallet_transactions
    for select using (wallet_user_id = auth.uid() or is_super_admin());
-- Écriture uniquement via les fonctions RPC (security definer).

-- ---------------- NOTIFICATIONS ----------------
alter table notifications enable row level security;

create policy "Users read own notifications" on notifications
    for select using (user_id = auth.uid());

create policy "Users mark own notifications read" on notifications
    for update using (user_id = auth.uid());
-- Création uniquement via notify_user() (security definer, §010).

-- ---------------- AUDIT / OWNERSHIP TRANSFER LOG ----------------
-- Historique interne — jamais exposé au client, sauf au Super Admin.
alter table ownership_transfer_log enable row level security;
create policy "Admin read ownership transfer log" on ownership_transfer_log
    for select using (is_super_admin());

alter table audit_log enable row level security;
create policy "Admin read audit log" on audit_log
    for select using (is_super_admin());

-- ---------------- MONETIZATION PRICES ----------------
alter table monetization_prices enable row level security;

create policy "Authenticated read prices" on monetization_prices
    for select to authenticated using (true);
create policy "Admin manage prices" on monetization_prices
    for insert with check (is_super_admin());
create policy "Admin update prices" on monetization_prices
    for update using (is_super_admin());
