-- ============================================================
-- QOTA — "CHAÎNES ET PROGRAMMES" / "VENTE EN LIGNE" / "AUTRES" :
-- OUVERTURE À TOUS LES UTILISATEURS (remplace la restriction 022)
-- ============================================================
-- Ces 3 sections étaient réservées au Super Admin/modérateurs
-- (§022), avec publication immédiate. Elles suivent maintenant
-- exactement le même principe que les Figures Publiques (§35) :
-- n'importe quel utilisateur peut publier, l'entrée entre en
-- 'pending_review' et n'apparaît nulle part (Home, listes,
-- recherche) tant que le Super Admin (ou un modérateur avec la
-- permission 'moderate_content') ne l'a pas approuvée depuis le
-- Dashboard > Modération des publications (déjà agnostique du
-- kind, aucun changement nécessaire côté modération).
-- ============================================================

drop policy if exists "Users create entities" on entities;
create policy "Users create entities" on entities
    for insert with check (created_by = auth.uid());
