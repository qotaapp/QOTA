# Qota

Plateforme universelle d'évaluation — services, lieux, figures publiques,
et contenus personnels (User Items). Flutter (Android/iOS/Web) + Supabase.

## Structure du projet

```
lib/
  core/            thème, routing, constantes
  features/
    auth/          connexion, création de compte, social login
    home/          Feed algorithmique (§9-10)
    evaluer/       État → Ville → Zone → Catégorie → Services (§13-22, §25-26)
    rating/        Rating Sheet (§27-30)
    comments/      commentaires, réponses, likes (§31-34)
    profile/       profil, User Items (§7, §23-24)
    figures/       Figures Publiques (§35-37)
    notifications/ notifications (§38)
    wallet/        Qota Coin — achat, transfert QR (§3)
    search/        recherche (§12)
    admin/         Dashboard Super Admin
supabase/          migrations SQL, à exécuter DANS L'ORDRE (001 → 015)
.github/workflows/ pipeline CI/CD
render.yaml        déploiement Web (staging + production)
NATIVE_SETUP.md    permissions Android/iOS requises
```

## Mise en route

### 1. Base de données Supabase

Exécuter les migrations SQL **dans l'ordre numérique** via le SQL Editor
de Supabase (ou `supabase db push` si la CLI est configurée) :

```
qota_schema.sql   (schéma de base — tables principales)
supabase/002_auth_signup_automation.sql
supabase/003_entity_cards_view.sql
supabase/004_seed_initial_data.sql
supabase/005_comments_views.sql
supabase/006_delete_comment_rpc.sql
supabase/007_name_change_monetization.sql
supabase/008_user_items_view.sql
supabase/009_public_figures.sql
supabase/010_notifications_triggers.sql
supabase/011_wallet_purchase_transfer.sql
supabase/012_feed_algorithm.sql
supabase/013_search.sql
supabase/014_admin_foundations.sql
supabase/015_full_rls.sql   ← sécurité, à ne surtout pas sauter
```

Chaque fichier est idempotent-friendly (`if not exists`, `on conflict do
nothing`) mais dépend du précédent — ne pas changer l'ordre.

### 2. Créer le premier Super Admin

Après inscription d'un premier compte via l'app, l'élever manuellement :

```sql
insert into user_roles (user_id, role)
values ('<uuid-du-compte>', 'super_admin');
```

### 3. Lancer l'app en local

```bash
flutter pub get
flutter gen-l10n
flutter run \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=xxxx
```

Voir `NATIVE_SETUP.md` pour les permissions Android/iOS (caméra, position).

## CI/CD

- **GitHub Actions** (`.github/workflows/ci_cd.yml`) : à chaque push/PR —
  analyse statique, formatage, tests, build Web + Android. Secrets requis
  dans GitHub (Settings > Secrets) : `SUPABASE_URL`, `SUPABASE_ANON_KEY`.
- **Render** (`render.yaml`) : deux services statiques Flutter Web,
  connectés au dépôt GitHub — `develop` → staging, `main` → production.
  Déploiement automatique à chaque push sur ces branches.
- **Cloudflare** : à placer devant les deux domaines Render (CNAME) pour
  le CDN, le cache statique, et la protection DDoS/WAF. Activer "Always
  Use HTTPS" et le mode SSL "Full (strict)". Aucune config déclarative
  n'est versionnée ici (gérée depuis le Dashboard Cloudflare), mais tout
  header de sécurité additionnel (CSP, HSTS) peut être ajouté via une
  Cloudflare Page Rule ou un Worker si besoin d'aller plus loin.

## Sécurité

Row Level Security est active sur **toutes** les tables (`015_full_rls.sql`).
Principes clés :
- Le solde des wallets ne peut **jamais** être modifié directement par un
  client — uniquement via des fonctions `security definer` (achat validé
  par le Super Admin, transfert P2P atomique).
- L'identité d'un évaluateur (`ratings.user_id`) n'est lisible que par
  son auteur et le Super Admin — jamais par le public (§37).
- La suppression de commentaire applique la règle §34 côté serveur
  (fonction `delete_comment`), impossible à contourner depuis le client.
