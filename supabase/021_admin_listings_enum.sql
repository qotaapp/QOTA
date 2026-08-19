-- ============================================================
-- QOTA — SECTIONS ADMIN (1/2) : nouvelle valeur d'enum
-- ============================================================
-- IMPORTANT : PostgreSQL interdit d'utiliser une nouvelle valeur
-- d'enum dans la MÊME transaction que celle qui l'a créée.
-- Exécutez ce fichier SEUL, en premier ("Run" dans le SQL Editor),
-- puis seulement ensuite 022_admin_listings.sql. Les exécuter en une
-- seule fois provoquerait une erreur Postgres.
-- ============================================================

alter type entity_kind add value if not exists 'admin_listing';
