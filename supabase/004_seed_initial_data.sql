-- ============================================================
-- QOTA — SEED INITIAL : 24 GOUVERNORATS DE TUNISIE (§14)
-- "Elle doit afficher initialement les 24 gouvernorats de Tunisie.
--  Le système doit être dynamique. Ne pas hardcoder les 24 États
--  dans Flutter." -> ils sont insérés ici en donnée, gérables
-- ensuite par le Super Admin (ajout/modif/désactivation).
-- ============================================================

insert into states (name_fr, name_ar, order_index) values
    ('Tunis', 'تونس', 1),
    ('Ariana', 'أريانة', 2),
    ('Ben Arous', 'بن عروس', 3),
    ('Manouba', 'منوبة', 4),
    ('Nabeul', 'نابل', 5),
    ('Zaghouan', 'زغوان', 6),
    ('Bizerte', 'بنزرت', 7),
    ('Béja', 'باجة', 8),
    ('Jendouba', 'جندوبة', 9),
    ('Le Kef', 'الكاف', 10),
    ('Siliana', 'سليانة', 11),
    ('Kairouan', 'القيروان', 12),
    ('Kasserine', 'القصرين', 13),
    ('Sidi Bouzid', 'سيدي بوزيد', 14),
    ('Sousse', 'سوسة', 15),
    ('Monastir', 'المنستير', 16),
    ('Mahdia', 'المهدية', 17),
    ('Sfax', 'صفاقس', 18),
    ('Gafsa', 'قفصة', 19),
    ('Tozeur', 'توزر', 20),
    ('Kébili', 'قبلي', 21),
    ('Gabès', 'قابس', 22),
    ('Médenine', 'مدنين', 23),
    ('Tataouine', 'تطاوين', 24)
on conflict do nothing;

-- Exemple de villes/zones pour Gafsa, comme illustré au §15.
-- (À reproduire pour les autres gouvernorats depuis le Dashboard Super Admin.)
do $$
declare
    v_gafsa_id uuid;
    v_gafsa_ville_id uuid;
begin
    select id into v_gafsa_id from states where name_fr = 'Gafsa' limit 1;

    insert into cities (state_id, name_fr, name_ar, order_index)
    values (v_gafsa_id, 'Gafsa', 'قفصة', 1)
    returning id into v_gafsa_ville_id;

    insert into zones (city_id, name_fr, name_ar, order_index) values
        (v_gafsa_ville_id, 'Zarroug', 'الزروق', 1),
        (v_gafsa_ville_id, 'Centre Ville', 'وسط المدينة', 2),
        (v_gafsa_ville_id, 'Cité Ennour', 'حي النور', 3),
        (v_gafsa_ville_id, 'Mwalla', 'مولة', 4);
end $$;

-- Catégories initiales (§16), gérables ensuite par le Super Admin.
insert into categories (name_fr, name_ar, icon, order_index) values
    ('Service administratif', 'خدمة إدارية', 'admin_panel_settings', 1),
    ('Restaurants et Cafés', 'مطاعم ومقاهي', 'restaurant', 2),
    ('Boutiques et Magasins', 'محلات ومتاجر', 'storefront', 3),
    ('Delivery', 'توصيل', 'delivery_dining', 4)
on conflict do nothing;
