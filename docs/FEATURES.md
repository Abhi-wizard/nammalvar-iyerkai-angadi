# Feature Reference & Implementation Matrix — Nammalvar

This document provides a factual, source-verified inventory of all features implemented in **Nammalvar Iyerkai Angadi**, mapping each capability directly to its frontend widgets, state management providers, and backend services.

---

## 1. Feature Status Summary

| Category | Feature Description | Status | Primary Code Files |
|---|---|---|---|
| **Authentication** | Supabase Auth email/password login & persistent session | **Implemented** | [`login_screen.dart`](file:///c:/Users/ABHIMANYU/Desktop/nammalvar-iyerkai-angadi/lib/features/auth/presentation/login_screen.dart), [`auth_repository.dart`](file:///c:/Users/ABHIMANYU/Desktop/nammalvar-iyerkai-angadi/lib/features/auth/data/auth_repository.dart) |
| **Authentication** | Automatic role resolution (`admin` vs `seller`) | **Implemented** | [`profile_model.dart`](file:///c:/Users/ABHIMANYU/Desktop/nammalvar-iyerkai-angadi/lib/features/auth/domain/profile_model.dart), [`auth_providers.dart`](file:///c:/Users/ABHIMANYU/Desktop/nammalvar-iyerkai-angadi/lib/features/auth/presentation/auth_providers.dart) |
| **Navigation** | Role-gated Navigation Shell (8 tabs for Admin, 5 for Seller) | **Implemented** | [`main_navigation_shell.dart`](file:///c:/Users/ABHIMANYU/Desktop/nammalvar-iyerkai-angadi/lib/features/dashboard/presentation/main_navigation_shell.dart) |
| **Point of Sale (POS)** | Live product catalog search & category chips | **Implemented** | [`new_sale_screen.dart`](file:///c:/Users/ABHIMANYU/Desktop/nammalvar-iyerkai-angadi/lib/features/sales/presentation/new_sale_screen.dart) |
| **Point of Sale (POS)** | Shopping cart with quantity steppers & rate overrides | **Implemented** | [`cart_provider.dart`](file:///c:/Users/ABHIMANYU/Desktop/nammalvar-iyerkai-angadi/lib/features/sales/presentation/cart_provider.dart), [`cart_item_model.dart`](file:///c:/Users/ABHIMANYU/Desktop/nammalvar-iyerkai-angadi/lib/features/sales/domain/cart_item_model.dart) |
| **Point of Sale (POS)** | Review & checkout modal with payment methods (Cash, UPI, Other) | **Implemented** | [`new_sale_screen.dart`](file:///c:/Users/ABHIMANYU/Desktop/nammalvar-iyerkai-angadi/lib/features/sales/presentation/new_sale_screen.dart) |
| **Point of Sale (POS)** | Concurrency-safe atomic sale checkout via PostgreSQL RPC | **Implemented** | [`sales_repository.dart`](file:///c:/Users/ABHIMANYU/Desktop/nammalvar-iyerkai-angadi/lib/features/sales/data/sales_repository.dart), `process_sale` RPC |
| **Catalog Management** | Product listing with realtime stock level badges | **Implemented** | [`products_screen.dart`](file:///c:/Users/ABHIMANYU/Desktop/nammalvar-iyerkai-angadi/lib/features/products/presentation/products_screen.dart), [`product_repository.dart`](file:///c:/Users/ABHIMANYU/Desktop/nammalvar-iyerkai-angadi/lib/features/products/data/product_repository.dart) |
| **Catalog Management** | Admin product creation & price editing | **Implemented** | [`products_screen.dart`](file:///c:/Users/ABHIMANYU/Desktop/nammalvar-iyerkai-angadi/lib/features/products/presentation/products_screen.dart) |
| **Catalog Management** | Price history tracking via PostgreSQL audit trigger | **Implemented** | `00001_initial_schema.sql` (`track_product_price_change`) |
| **Inventory Management**| Inward stock receiving with supplier & invoice tracking | **Implemented** | [`stock_screen.dart`](file:///c:/Users/ABHIMANYU/Desktop/nammalvar-iyerkai-angadi/lib/features/stock/presentation/stock_screen.dart), [`stock_repository.dart`](file:///c:/Users/ABHIMANYU/Desktop/nammalvar-iyerkai-angadi/lib/features/stock/data/stock_repository.dart) |
| **Inventory Management**| Physical inventory adjustment with mandatory audit reasoning | **Implemented** | [`stock_screen.dart`](file:///c:/Users/ABHIMANYU/Desktop/nammalvar-iyerkai-angadi/lib/features/stock/presentation/stock_screen.dart), `adjust_stock` RPC |
| **Inventory Management**| Immutable stock movement ledger | **Implemented** | [`stock_screen.dart`](file:///c:/Users/ABHIMANYU/Desktop/nammalvar-iyerkai-angadi/lib/features/stock/presentation/stock_screen.dart), `stock_movements` table |
| **Sales Auditing** | Global sales invoice history (Admin view) | **Implemented** | [`sales_history_screen.dart`](file:///c:/Users/ABHIMANYU/Desktop/nammalvar-iyerkai-angadi/lib/features/sales/presentation/sales_history_screen.dart) |
| **Sales Auditing** | Personal sales invoice history (Seller view - RLS enforced) | **Implemented** | [`sales_history_screen.dart`](file:///c:/Users/ABHIMANYU/Desktop/nammalvar-iyerkai-angadi/lib/features/sales/presentation/sales_history_screen.dart) |
| **Sales Auditing** | Atomic sale cancellation & stock restoration | **Implemented** | [`sales_history_screen.dart`](file:///c:/Users/ABHIMANYU/Desktop/nammalvar-iyerkai-angadi/lib/features/sales/presentation/sales_history_screen.dart), `cancel_sale` RPC |
| **Financial Analytics** | Daily store closing summary & payment split | **Implemented** | [`reports_screen.dart`](file:///c:/Users/ABHIMANYU/Desktop/nammalvar-iyerkai-angadi/lib/features/reports/presentation/reports_screen.dart), [`sales_providers.dart`](file:///c:/Users/ABHIMANYU/Desktop/nammalvar-iyerkai-angadi/lib/features/sales/presentation/sales_providers.dart) |
| **Financial Analytics** | Itemized seller tracking (who sold which product) | **Implemented** | [`reports_screen.dart`](file:///c:/Users/ABHIMANYU/Desktop/nammalvar-iyerkai-angadi/lib/features/reports/presentation/reports_screen.dart) |
| **Financial Analytics** | Profit & loss calculation (Revenue - COGS - Expenses) | **Implemented** | [`reports_screen.dart`](file:///c:/Users/ABHIMANYU/Desktop/nammalvar-iyerkai-angadi/lib/features/reports/presentation/reports_screen.dart) |
| **Reporting & Export** | Unicode-safe PDF daily closing summary report | **Implemented** | [`reports_screen.dart`](file:///c:/Users/ABHIMANYU/Desktop/nammalvar-iyerkai-angadi/lib/features/reports/presentation/reports_screen.dart) (`printing`, `pdf`) |
| **Reporting & Export** | Multi-sheet Excel workbook export (`.xlsx`) | **Implemented** | [`reports_screen.dart`](file:///c:/Users/ABHIMANYU/Desktop/nammalvar-iyerkai-angadi/lib/features/reports/presentation/reports_screen.dart) (`excel`) |
| **Expense Tracking** | Operational expense logging with categorized breakdowns | **Implemented** | [`expenses_screen.dart`](file:///c:/Users/ABHIMANYU/Desktop/nammalvar-iyerkai-angadi/lib/features/expenses/presentation/expenses_screen.dart), [`expense_repository.dart`](file:///c:/Users/ABHIMANYU/Desktop/nammalvar-iyerkai-angadi/lib/features/expenses/data/expense_repository.dart) |
| **Terminal Settings** | User profile card, active terminal ID, sign out | **Implemented** | [`settings_screen.dart`](file:///c:/Users/ABHIMANYU/Desktop/nammalvar-iyerkai-angadi/lib/features/settings/presentation/settings_screen.dart) |
| **Hardware Integration**| Direct Bluetooth thermal receipt printer integration | **Partially Implemented** | Digital PDF receipt generation is complete; direct ESC/POS hardware pairing is planned. |
| **Barcode Scanning** | Physical barcode / QR hardware scanner bridge | **Partially Implemented** | Instant keyword and SKU search is implemented; camera scanner integration is planned. |

---

## 2. Role-Based Access Control (RBAC) Matrix

The system enforces strict permission boundaries between **Store Owners (Admin)** and **Counter Cashiers (Seller)**:

| Feature / Action | Admin Role | Seller Role | Enforcement Mechanism |
|---|---|---|---|
| View Store Revenue & Daily Closing | Full Access | Restricted | UI Shell + RLS |
| Access POS Terminal & Process Sales | Yes | Yes | Open to all authenticated staff |
| View Product Cost Price & Gross Margin | Yes | Hidden | Presentation Layer + RLS |
| Add / Modify Products & Selling Prices | Yes | Read-Only | RLS policy on `public.products` |
| Receive Inward Stock / Invoices | Yes | Restricted | `receive_stock` RPC authorization check |
| Adjust Stock Quantities | Yes | Restricted | `adjust_stock` RPC authorization check |
| View Global Store Sales History | All Sellers | Own Sales Only | RLS: `seller_id = auth.uid()` |
| Cancel Sale & Restore Inventory | Yes (with reason) | Restricted | `cancel_sale` RPC (`is_admin()`) |
| View Expense Records | Full Access | Hidden | Tab omitted + RLS on `public.expenses` |
| Export Audit Reports (PDF / Excel) | Yes | Hidden | Restricted to Admin Reports Screen |

---

## 3. High-Fidelity Export Pipeline

### Indian Rupee (`₹`) Unicode PDF Generation
Standard PDF fonts (e.g., standard Helvetica) lack the currency symbol glyph `₹` (U+20B9), resulting in character corruption or missing glyph exceptions. Nammalvar resolves this by:
1. Bundling TrueType Unicode font files (`Arial-Regular.ttf` and `Arial-Bold.ttf`) in `assets/fonts/`.
2. Applying custom `pw.ThemeData.withFont` when building documents.
3. Automatically falling back to `PdfGoogleFonts.robotoRegular()` if offline assets are unreachable.

### Multi-Sheet Excel Workbook (`.xlsx`)
The Excel export engine utilizes `excel: ^4.0.6` to generate structured workbooks containing four dedicated worksheets:
1. **Summary Sheet**: High-level store metrics, total revenue, payment splits, transaction counts, gross profit, and net margin.
2. **Sales Sheet**: Itemized table of every recorded transaction with timestamp, seller name, payment method, and amount.
3. **Sale Items Sheet**: Granular snapshot of individual line items sold per invoice.
4. **Expenses Sheet**: Comprehensive log of operational overhead expenses.
