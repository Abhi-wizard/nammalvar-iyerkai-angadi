-- ============================================================================
-- Nammalvar Iyerkai Angadi - Hardened Supabase Database Schema
-- Migration: 00001_initial_schema.sql
-- ============================================================================

-- 1. EXTENSIONS & TYPES
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('admin', 'seller');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE product_status AS ENUM ('active', 'inactive', 'archived');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE unit_type AS ENUM ('kg', 'g', 'litre', 'ml', 'piece', 'packet', 'bottle', 'box');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE payment_method AS ENUM ('cash', 'upi', 'other');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE sale_status AS ENUM ('completed', 'cancelled');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE stock_movement_type AS ENUM ('opening_stock', 'purchase', 'sale', 'sale_cancel', 'adjustment');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. TABLES

-- Profiles table (Linked to Supabase Auth)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    role user_role NOT NULL DEFAULT 'seller',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Categories & Subcategories table
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    parent_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    display_order INT DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Products table
CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    category_id UUID NOT NULL REFERENCES public.categories(id) ON DELETE RESTRICT,
    subcategory_id UUID REFERENCES public.categories(id) ON DELETE RESTRICT,
    brand TEXT,
    unit unit_type NOT NULL DEFAULT 'piece',
    selling_price NUMERIC(12, 2) NOT NULL CHECK (selling_price >= 0),
    cost_price NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (cost_price >= 0),
    current_stock NUMERIC(12, 3) NOT NULL DEFAULT 0 CHECK (current_stock >= 0),
    minimum_stock NUMERIC(12, 3) NOT NULL DEFAULT 5 CHECK (minimum_stock >= 0),
    status product_status NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_products_name UNIQUE (name)
);

-- Sales table
CREATE TABLE IF NOT EXISTS public.sales (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sale_number BIGSERIAL UNIQUE,
    seller_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    sale_date TIMESTAMPTZ NOT NULL DEFAULT now(),
    total_amount NUMERIC(12, 2) NOT NULL CHECK (total_amount >= 0),
    total_cost_amount NUMERIC(12, 2) NOT NULL DEFAULT 0,
    payment_method payment_method NOT NULL DEFAULT 'cash',
    status sale_status NOT NULL DEFAULT 'completed',
    cancelled_by UUID REFERENCES public.profiles(id) ON DELETE RESTRICT,
    cancelled_at TIMESTAMPTZ,
    cancellation_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Sale Items (Immutable Snapshots)
CREATE TABLE IF NOT EXISTS public.sale_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sale_id UUID NOT NULL REFERENCES public.sales(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
    product_name_snapshot TEXT NOT NULL,
    unit_snapshot unit_type NOT NULL,
    quantity NUMERIC(12, 3) NOT NULL CHECK (quantity > 0),
    rate_snapshot NUMERIC(12, 2) NOT NULL CHECK (rate_snapshot >= 0),
    cost_price_snapshot NUMERIC(12, 2) NOT NULL DEFAULT 0,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Stock Movements (Audit Ledger)
CREATE TABLE IF NOT EXISTS public.stock_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
    movement_type stock_movement_type NOT NULL,
    quantity NUMERIC(12, 3) NOT NULL,
    balance_after NUMERIC(12, 3) NOT NULL,
    reference_id UUID,
    reason TEXT,
    performed_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Price History
CREATE TABLE IF NOT EXISTS public.price_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    old_selling_price NUMERIC(12, 2) NOT NULL,
    new_selling_price NUMERIC(12, 2) NOT NULL,
    old_cost_price NUMERIC(12, 2),
    new_cost_price NUMERIC(12, 2),
    changed_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Suppliers
CREATE TABLE IF NOT EXISTS public.suppliers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    address TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Purchases (Inward stock)
CREATE TABLE IF NOT EXISTS public.purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supplier_id UUID REFERENCES public.suppliers(id) ON DELETE SET NULL,
    invoice_number TEXT,
    purchase_date DATE NOT NULL DEFAULT CURRENT_DATE,
    total_amount NUMERIC(12, 2) NOT NULL DEFAULT 0,
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Purchase Items
CREATE TABLE IF NOT EXISTS public.purchase_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    purchase_id UUID NOT NULL REFERENCES public.purchases(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
    quantity NUMERIC(12, 3) NOT NULL CHECK (quantity > 0),
    cost_price NUMERIC(12, 2) NOT NULL CHECK (cost_price >= 0),
    amount NUMERIC(12, 2) NOT NULL CHECK (amount >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Expenses
CREATE TABLE IF NOT EXISTS public.expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category TEXT NOT NULL,
    description TEXT,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Activity / Audit Logs
CREATE TABLE IF NOT EXISTS public.activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    action TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id UUID,
    details JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. INDEXES FOR HIGH-SPEED QUERIES
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_subcategory ON public.products(subcategory_id);
CREATE INDEX IF NOT EXISTS idx_products_status ON public.products(status);
CREATE INDEX IF NOT EXISTS idx_sales_seller ON public.sales(seller_id);
CREATE INDEX IF NOT EXISTS idx_sales_date ON public.sales(sale_date);
CREATE INDEX IF NOT EXISTS idx_sales_status ON public.sales(status);
CREATE INDEX IF NOT EXISTS idx_sale_items_sale ON public.sale_items(sale_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_product ON public.sale_items(product_id);
CREATE INDEX IF NOT EXISTS idx_stock_movements_product ON public.stock_movements(product_id);
CREATE INDEX IF NOT EXISTS idx_stock_movements_created ON public.stock_movements(created_at);

-- 4. HELPER FUNCTIONS
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'admin' AND is_active = true
    );
$$;

-- 5. ATOMIC CONCURRENCY-SAFE STORED PROCEDURES (RPCs)

-- Process Sale (Pessimistic Row Locking FOR UPDATE + Server-side auth.uid() enforcement)
CREATE OR REPLACE FUNCTION public.process_sale(
    p_payment_method payment_method,
    p_items JSONB
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_seller_id UUID;
    v_seller_profile RECORD;
    v_sale_id UUID;
    v_total_amount NUMERIC(12, 2) := 0;
    v_total_cost NUMERIC(12, 2) := 0;
    v_item JSONB;
    v_product_id UUID;
    v_qty NUMERIC(12, 3);
    v_rate NUMERIC(12, 2);
    v_product RECORD;
    v_item_amount NUMERIC(12, 2);
    v_new_stock NUMERIC(12, 3);
    v_sale_num BIGINT;
BEGIN
    -- 1. Derive authenticated seller identity strictly from Supabase Auth
    v_seller_id := auth.uid();
    IF v_seller_id IS NULL THEN
        RAISE EXCEPTION 'Unauthorized: User must be authenticated to record a sale.';
    END IF;

    SELECT * INTO v_seller_profile
    FROM public.profiles
    WHERE id = v_seller_id AND is_active = true;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Forbidden: Active profile not found for authenticated user.';
    END IF;

    -- 2. Validate items
    IF jsonb_array_length(p_items) = 0 THEN
        RAISE EXCEPTION 'Sale must contain at least one item.';
    END IF;

    -- 3. Create Sale Header
    INSERT INTO public.sales (seller_id, total_amount, total_cost_amount, payment_method, status)
    VALUES (v_seller_id, 0, 0, p_payment_method, 'completed')
    RETURNING id, sale_number INTO v_sale_id, v_sale_num;

    -- 4. Process each item atomically with row locking
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_product_id := (v_item->>'product_id')::UUID;
        v_qty := (v_item->>'quantity')::NUMERIC;
        v_rate := (v_item->>'rate')::NUMERIC;

        IF v_qty <= 0 THEN
            RAISE EXCEPTION 'Item quantity must be greater than zero.';
        END IF;

        -- Lock the product row for update to eliminate race conditions
        SELECT * INTO v_product
        FROM public.products
        WHERE id = v_product_id
        FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Product % does not exist.', v_product_id;
        END IF;

        IF v_product.status <> 'active' THEN
            RAISE EXCEPTION 'Product "%" is not active for sale.', v_product.name;
        END IF;

        IF v_product.current_stock < v_qty THEN
            RAISE EXCEPTION 'Insufficient stock for "%". Requested: %, Available: %',
                v_product.name, v_qty, v_product.current_stock;
        END IF;

        v_new_stock := v_product.current_stock - v_qty;
        v_item_amount := ROUND(v_qty * v_rate, 2);
        v_total_amount := v_total_amount + v_item_amount;
        v_total_cost := v_total_cost + ROUND(v_qty * v_product.cost_price, 2);

        -- Update product current stock
        UPDATE public.products
        SET current_stock = v_new_stock, updated_at = now()
        WHERE id = v_product_id;

        -- Record immutable Sale Item
        INSERT INTO public.sale_items (
            sale_id, product_id, product_name_snapshot, unit_snapshot,
            quantity, rate_snapshot, cost_price_snapshot, amount
        ) VALUES (
            v_sale_id, v_product_id, v_product.name, v_product.unit,
            v_qty, v_rate, v_product.cost_price, v_item_amount
        );

        -- Record Stock Movement Ledger
        INSERT INTO public.stock_movements (
            product_id, movement_type, quantity, balance_after,
            reference_id, reason, performed_by
        ) VALUES (
            v_product_id, 'sale', -v_qty, v_new_stock,
            v_sale_id, 'Sale #' || v_sale_num, v_seller_id
        );
    END LOOP;

    -- 5. Update final totals in sale header
    UPDATE public.sales
    SET total_amount = v_total_amount, total_cost_amount = v_total_cost
    WHERE id = v_sale_id;

    -- 6. Log activity
    INSERT INTO public.activity_logs (user_id, action, entity_type, entity_id, details)
    VALUES (v_seller_id, 'CREATE_SALE', 'sale', v_sale_id, jsonb_build_object('sale_number', v_sale_num, 'total', v_total_amount));

    RETURN v_sale_id;
END;
$$;

-- Cancel Sale (Restores stock atomically + Server-side Admin Authorization)
CREATE OR REPLACE FUNCTION public.cancel_sale(
    p_sale_id UUID,
    p_reason TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_admin_id UUID;
    v_sale RECORD;
    v_item RECORD;
    v_new_stock NUMERIC(12, 3);
BEGIN
    v_admin_id := auth.uid();
    IF v_admin_id IS NULL THEN
        RAISE EXCEPTION 'Unauthorized: User must be authenticated.';
    END IF;

    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Forbidden: Only admin users can cancel sales.';
    END IF;

    IF p_reason IS NULL OR trim(p_reason) = '' THEN
        RAISE EXCEPTION 'Mandatory cancellation reason required.';
    END IF;

    SELECT * INTO v_sale FROM public.sales WHERE id = p_sale_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Sale not found.';
    END IF;

    IF v_sale.status = 'cancelled' THEN
        RAISE EXCEPTION 'Sale is already cancelled.';
    END IF;

    -- Iterate through items and restore stock
    FOR v_item IN SELECT * FROM public.sale_items WHERE sale_id = p_sale_id
    LOOP
        UPDATE public.products
        SET current_stock = current_stock + v_item.quantity, updated_at = now()
        WHERE id = v_item.product_id
        RETURNING current_stock INTO v_new_stock;

        -- Record Stock Movement Ledger
        INSERT INTO public.stock_movements (
            product_id, movement_type, quantity, balance_after,
            reference_id, reason, performed_by
        ) VALUES (
            v_item.product_id, 'sale_cancel', v_item.quantity, v_new_stock,
            p_sale_id, 'Cancellation of Sale #' || v_sale.sale_number || ': ' || p_reason,
            v_admin_id
        );
    END LOOP;

    -- Update Sale Header to cancelled
    UPDATE public.sales
    SET status = 'cancelled',
        cancelled_by = v_admin_id,
        cancelled_at = now(),
        cancellation_reason = p_reason
    WHERE id = p_sale_id;

    -- Log activity
    INSERT INTO public.activity_logs (user_id, action, entity_type, entity_id, details)
    VALUES (v_admin_id, 'CANCEL_SALE', 'sale', p_sale_id, jsonb_build_object('sale_number', v_sale.sale_number, 'reason', p_reason));

    RETURN true;
END;
$$;

-- Receive Stock (Inward purchase / manual addition + Admin Authorization)
CREATE OR REPLACE FUNCTION public.receive_stock(
    p_product_id UUID,
    p_quantity NUMERIC(12, 3),
    p_cost_price NUMERIC(12, 2),
    p_supplier_id UUID,
    p_invoice_number TEXT,
    p_notes TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_admin_id UUID;
    v_purchase_id UUID;
    v_item_amount NUMERIC(12, 2);
    v_new_stock NUMERIC(12, 3);
BEGIN
    v_admin_id := auth.uid();
    IF v_admin_id IS NULL THEN
        RAISE EXCEPTION 'Unauthorized: User must be authenticated.';
    END IF;

    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Forbidden: Only admin users can receive stock.';
    END IF;

    IF p_quantity <= 0 THEN
        RAISE EXCEPTION 'Quantity must be greater than zero.';
    END IF;

    v_item_amount := ROUND(p_quantity * p_cost_price, 2);

    -- Create Purchase record
    INSERT INTO public.purchases (supplier_id, invoice_number, total_amount, created_by)
    VALUES (p_supplier_id, p_invoice_number, v_item_amount, v_admin_id)
    RETURNING id INTO v_purchase_id;

    INSERT INTO public.purchase_items (purchase_id, product_id, quantity, cost_price, amount)
    VALUES (v_purchase_id, p_product_id, p_quantity, p_cost_price, v_item_amount);

    -- Update stock & cost price
    UPDATE public.products
    SET current_stock = current_stock + p_quantity,
        cost_price = CASE WHEN p_cost_price > 0 THEN p_cost_price ELSE cost_price END,
        updated_at = now()
    WHERE id = p_product_id
    RETURNING current_stock INTO v_new_stock;

    -- Record stock movement
    INSERT INTO public.stock_movements (
        product_id, movement_type, quantity, balance_after,
        reference_id, reason, performed_by
    ) VALUES (
        p_product_id, 'purchase', p_quantity, v_new_stock,
        v_purchase_id, COALESCE(p_notes, 'Stock Received / Purchase Invoice: ' || COALESCE(p_invoice_number, 'N/A')),
        v_admin_id
    );

    RETURN v_purchase_id;
END;
$$;

-- Adjust Stock (Physical correction + Admin Authorization)
CREATE OR REPLACE FUNCTION public.adjust_stock(
    p_product_id UUID,
    p_adjustment_delta NUMERIC(12, 3),
    p_reason TEXT
)
RETURNS NUMERIC(12, 3)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_admin_id UUID;
    v_current_stock NUMERIC(12, 3);
    v_new_stock NUMERIC(12, 3);
BEGIN
    v_admin_id := auth.uid();
    IF v_admin_id IS NULL THEN
        RAISE EXCEPTION 'Unauthorized: User must be authenticated.';
    END IF;

    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Forbidden: Only admin users can adjust stock.';
    END IF;

    IF p_reason IS NULL OR trim(p_reason) = '' THEN
        RAISE EXCEPTION 'Mandatory adjustment reason required.';
    END IF;

    SELECT current_stock INTO v_current_stock
    FROM public.products
    WHERE id = p_product_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Product not found.';
    END IF;

    v_new_stock := v_current_stock + p_adjustment_delta;

    IF v_new_stock < 0 THEN
        RAISE EXCEPTION 'Adjustment would result in negative stock (%). Current: %, Delta: %',
            v_new_stock, v_current_stock, p_adjustment_delta;
    END IF;

    UPDATE public.products
    SET current_stock = v_new_stock, updated_at = now()
    WHERE id = p_product_id;

    INSERT INTO public.stock_movements (
        product_id, movement_type, quantity, balance_after,
        reason, performed_by
    ) VALUES (
        p_product_id, 'adjustment', p_adjustment_delta, v_new_stock,
        p_reason, v_admin_id
    );

    RETURN v_new_stock;
END;
$$;

-- Price Change Trigger Function
CREATE OR REPLACE FUNCTION public.track_product_price_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF (OLD.selling_price <> NEW.selling_price) OR (OLD.cost_price <> NEW.cost_price) THEN
        INSERT INTO public.price_history (
            product_id, old_selling_price, new_selling_price,
            old_cost_price, new_cost_price, changed_by, changed_at
        ) VALUES (
            NEW.id, OLD.selling_price, NEW.selling_price,
            OLD.cost_price, NEW.cost_price,
            COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid),
            now()
        );
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_track_price_change ON public.products;
CREATE TRIGGER trg_track_price_change
BEFORE UPDATE ON public.products
FOR EACH ROW
EXECUTE FUNCTION public.track_product_price_change();

-- 6. ROW LEVEL SECURITY (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sale_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.price_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchase_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;

-- Policies for profiles
CREATE POLICY "Profiles read by authenticated users" ON public.profiles
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Profiles update by admin or self" ON public.profiles
    FOR UPDATE TO authenticated USING (auth.uid() = id OR public.is_admin());

CREATE POLICY "Profiles insert by admin" ON public.profiles
    FOR INSERT TO authenticated WITH CHECK (public.is_admin() OR auth.uid() = id);

-- Policies for categories
CREATE POLICY "Categories read by all authenticated" ON public.categories
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Categories modified by admin" ON public.categories
    FOR ALL TO authenticated USING (public.is_admin());

-- Policies for products
CREATE POLICY "Products read by all authenticated" ON public.products
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Products modified by admin" ON public.products
    FOR ALL TO authenticated USING (public.is_admin());

-- Policies for sales
CREATE POLICY "Sales read by admin or own seller" ON public.sales
    FOR SELECT TO authenticated USING (public.is_admin() OR seller_id = auth.uid());

CREATE POLICY "Sales created via authenticated RPC" ON public.sales
    FOR INSERT TO authenticated WITH CHECK (seller_id = auth.uid() OR public.is_admin());

CREATE POLICY "Sales update by admin only" ON public.sales
    FOR UPDATE TO authenticated USING (public.is_admin());

-- Policies for sale_items
CREATE POLICY "Sale items read by admin or item seller" ON public.sale_items
    FOR SELECT TO authenticated USING (
        public.is_admin() OR EXISTS (
            SELECT 1 FROM public.sales WHERE id = sale_items.sale_id AND seller_id = auth.uid()
        )
    );

-- Policies for stock movements
CREATE POLICY "Stock movements read by authenticated" ON public.stock_movements
    FOR SELECT TO authenticated USING (true);

-- Policies for price history, suppliers, purchases, expenses, activity logs
CREATE POLICY "Price history read by admin" ON public.price_history
    FOR SELECT TO authenticated USING (public.is_admin());

CREATE POLICY "Suppliers managed by admin" ON public.suppliers
    FOR ALL TO authenticated USING (public.is_admin());

CREATE POLICY "Purchases managed by admin" ON public.purchases
    FOR ALL TO authenticated USING (public.is_admin());

CREATE POLICY "Purchase items managed by admin" ON public.purchase_items
    FOR ALL TO authenticated USING (public.is_admin());

CREATE POLICY "Expenses managed by admin" ON public.expenses
    FOR ALL TO authenticated USING (public.is_admin());

CREATE POLICY "Activity logs read by admin" ON public.activity_logs
    FOR SELECT TO authenticated USING (public.is_admin());

-- 7. ENABLE REALTIME PUBLICATION
ALTER PUBLICATION supabase_realtime ADD TABLE public.products;
ALTER PUBLICATION supabase_realtime ADD TABLE public.sales;
ALTER PUBLICATION supabase_realtime ADD TABLE public.categories;
ALTER PUBLICATION supabase_realtime ADD TABLE public.stock_movements;
ALTER PUBLICATION supabase_realtime ADD TABLE public.expenses;
