-- ============================================================================
-- Nammalvar Iyerkai Angadi - Initial Catalog Seed (Idempotent)
-- Migration: 00002_seed_data.sql
-- ============================================================================

DO $$
DECLARE
    v_cat_rice UUID;
    v_cat_mercury UUID;
    v_cat_soaps UUID;
    v_cat_haircare UUID;
    v_cat_cleaning UUID;
BEGIN
    -- 1. Main Categories (Idempotent via ON CONFLICT on unique name)
    INSERT INTO public.categories (name, display_order)
    VALUES ('Rice & Cereals', 1)
    ON CONFLICT (name) DO UPDATE SET display_order = 1
    RETURNING id INTO v_cat_rice;

    INSERT INTO public.categories (name, display_order)
    VALUES ('Mercury Naturals', 2)
    ON CONFLICT (name) DO UPDATE SET display_order = 2
    RETURNING id INTO v_cat_mercury;

    -- 2. Sub Categories under Mercury Naturals
    INSERT INTO public.categories (name, parent_id, display_order)
    VALUES ('Soaps', v_cat_mercury, 1)
    ON CONFLICT (name) DO UPDATE SET parent_id = v_cat_mercury, display_order = 1
    RETURNING id INTO v_cat_soaps;

    INSERT INTO public.categories (name, parent_id, display_order)
    VALUES ('Hair Care', v_cat_mercury, 2)
    ON CONFLICT (name) DO UPDATE SET parent_id = v_cat_mercury, display_order = 2
    RETURNING id INTO v_cat_haircare;

    INSERT INTO public.categories (name, parent_id, display_order)
    VALUES ('Cleaning Products', v_cat_mercury, 3)
    ON CONFLICT (name) DO UPDATE SET parent_id = v_cat_mercury, display_order = 3
    RETURNING id INTO v_cat_cleaning;

    -- 3. Initial Products: Rice & Cereals (Idempotent via ON CONFLICT (name) DO NOTHING)
    INSERT INTO public.products (name, category_id, subcategory_id, brand, unit, selling_price, cost_price, current_stock, minimum_stock, status)
    VALUES
    ('Thuyamali Rice', v_cat_rice, NULL, 'Traditional', 'kg', 120.00, 95.00, 200.000, 25.000, 'active'),
    ('Karuppukavani Rice', v_cat_rice, NULL, 'Traditional', 'kg', 180.00, 140.00, 100.000, 15.000, 'active'),
    ('Siraga Samba – Semi Polished', v_cat_rice, NULL, 'Traditional', 'kg', 160.00, 125.00, 150.000, 20.000, 'active'),
    ('Siraga Samba – Unpolished', v_cat_rice, NULL, 'Traditional', 'kg', 170.00, 130.00, 120.000, 20.000, 'active'),
    ('Mapillai Samba', v_cat_rice, NULL, 'Traditional', 'kg', 140.00, 110.00, 150.000, 20.000, 'active'),
    ('Karunguruvai Rice', v_cat_rice, NULL, 'Traditional', 'kg', 150.00, 115.00, 100.000, 15.000, 'active'),
    ('Angur Sanna', v_cat_rice, NULL, 'Traditional', 'kg', 110.00, 85.00, 100.000, 15.000, 'active'),
    ('Mysore Malli Rice', v_cat_rice, NULL, 'Traditional', 'kg', 130.00, 100.00, 100.000, 15.000, 'active'),
    ('Thuvaram Paruppu', v_cat_rice, NULL, 'Traditional', 'kg', 190.00, 155.00, 80.000, 10.000, 'active')
    ON CONFLICT (name) DO NOTHING;

    -- 4. Initial Products: Mercury Naturals - Soaps (Idempotent)
    INSERT INTO public.products (name, category_id, subcategory_id, brand, unit, selling_price, cost_price, current_stock, minimum_stock, status)
    VALUES
    ('Vetiver Soap', v_cat_mercury, v_cat_soaps, 'Mercury Naturals', 'piece', 80.00, 55.00, 100.000, 10.000, 'active'),
    ('Charcoal Soap', v_cat_mercury, v_cat_soaps, 'Mercury Naturals', 'piece', 80.00, 55.00, 75.000, 10.000, 'active'),
    ('Veepilai Manjal Soap', v_cat_mercury, v_cat_soaps, 'Mercury Naturals', 'piece', 80.00, 55.00, 60.000, 10.000, 'active'),
    ('Kasthuri Manjal Soap', v_cat_mercury, v_cat_soaps, 'Mercury Naturals', 'piece', 80.00, 55.00, 60.000, 10.000, 'active'),
    ('Multani Mitti Soap', v_cat_mercury, v_cat_soaps, 'Mercury Naturals', 'piece', 80.00, 55.00, 50.000, 10.000, 'active'),
    ('Kuppaimeni Soap', v_cat_mercury, v_cat_soaps, 'Mercury Naturals', 'piece', 80.00, 55.00, 70.000, 10.000, 'active'),
    ('Aloevera Soap', v_cat_mercury, v_cat_soaps, 'Mercury Naturals', 'piece', 80.00, 55.00, 80.000, 10.000, 'active'),
    ('Red Wine Soap', v_cat_mercury, v_cat_soaps, 'Mercury Naturals', 'piece', 95.00, 65.00, 40.000, 10.000, 'active'),
    ('Sandal Soap', v_cat_mercury, v_cat_soaps, 'Mercury Naturals', 'piece', 85.00, 60.00, 90.000, 10.000, 'active'),
    ('Goat Milk Soap', v_cat_mercury, v_cat_soaps, 'Mercury Naturals', 'piece', 90.00, 60.00, 50.000, 10.000, 'active')
    ON CONFLICT (name) DO NOTHING;

    -- 5. Initial Products: Mercury Naturals - Hair Care (Idempotent)
    INSERT INTO public.products (name, category_id, subcategory_id, brand, unit, selling_price, cost_price, current_stock, minimum_stock, status)
    VALUES
    ('Mulugi Hair Oil', v_cat_mercury, v_cat_haircare, 'Mercury Naturals', 'bottle', 180.00, 130.00, 40.000, 8.000, 'active'),
    ('Karum Siraga Hair Oil', v_cat_mercury, v_cat_haircare, 'Mercury Naturals', 'bottle', 190.00, 135.00, 35.000, 8.000, 'active'),
    ('Hair Dye', v_cat_mercury, v_cat_haircare, 'Mercury Naturals', 'packet', 120.00, 85.00, 50.000, 10.000, 'active'),
    ('Sembaruthi Shampoo', v_cat_mercury, v_cat_haircare, 'Mercury Naturals', 'bottle', 150.00, 105.00, 50.000, 10.000, 'active'),
    ('Aloevera Shampoo', v_cat_mercury, v_cat_haircare, 'Mercury Naturals', 'bottle', 150.00, 105.00, 45.000, 10.000, 'active'),
    ('Karusilakanni Shampoo', v_cat_mercury, v_cat_haircare, 'Mercury Naturals', 'bottle', 160.00, 110.00, 40.000, 10.000, 'active'),
    ('Sikakai Shampoo', v_cat_mercury, v_cat_haircare, 'Mercury Naturals', 'bottle', 150.00, 105.00, 50.000, 10.000, 'active')
    ON CONFLICT (name) DO NOTHING;

    -- 6. Initial Products: Mercury Naturals - Cleaning Products (Idempotent)
    INSERT INTO public.products (name, category_id, subcategory_id, brand, unit, selling_price, cost_price, current_stock, minimum_stock, status)
    VALUES
    ('Dishwashing Liquid', v_cat_mercury, v_cat_cleaning, 'Mercury Naturals', 'bottle', 90.00, 60.00, 60.000, 12.000, 'active'),
    ('Cloth Washing Liquid', v_cat_mercury, v_cat_cleaning, 'Mercury Naturals', 'bottle', 110.00, 75.00, 50.000, 12.000, 'active')
    ON CONFLICT (name) DO NOTHING;

END $$;
