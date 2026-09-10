-- ============================================================
-- QOTA — FIX : POLICY UPDATE MANQUANTE SUR `comments`
-- Jusqu'ici, un commentaire n'était jamais modifié après création —
-- seules les policies SELECT et INSERT existaient (§015). La
-- fonctionnalité "avis lié au Rating" (rating_repository.dart,
-- submitRating) met à jour le commentaire existant via son
-- comment_id lors d'une modification de note — ce qui nécessite une
-- policy UPDATE, absente jusqu'ici, d'où l'échec silencieux.
-- ============================================================

create policy "Users update own comments" on comments
    for update
    using (user_id = auth.uid())
    with check (user_id = auth.uid());
