# Security Architecture & Repository Security Audit — Nammalvar

This document outlines the security posture, authentication architecture, authorization mechanisms, and audit findings for **Nammalvar Iyerkai Angadi**.

---

## 1. Security Model & Architecture

### Client-Side vs Server-Side Trust Boundary
In modern client-server architectures using Supabase (PostgreSQL), the Flutter mobile client is considered an untrusted environment. Therefore, security cannot rely on client-side checks alone.

```mermaid
flowchart LR
    Client[Flutter Client<br/>• Anon Key<br/>• User Session JWT] -->|RPC Request| Gateway[Supabase API Gateway]
    Gateway -->|Verify JWT| Auth[GoTrue Auth Engine]
    Auth -->|Set auth.uid()| Postgres[PostgreSQL Engine]
    
    subgraph PostgreSQL Trust Boundary
        Postgres --> RLS[Row Level Security Engine]
        RLS --> RPC[Stored Procedures: SECURITY DEFINER]
        RPC -->|Row-level Locks FOR UPDATE| Tables[(Physical Tables)]
    end
```

### The Role of the Supabase Anonymous Key
The key configured in `lib/core/constants/app_constants.dart` is a **publishable anonymous key** (`role: anon`):
- The anonymous key is intended by design to be distributed with mobile and web clients.
- It identifies the API project and allows public endpoints to be accessed.
- **Critical Requirement**: Data protection is enforced strictly by **Row Level Security (RLS)** in PostgreSQL. The presence of the anonymous key grants zero access to tables where RLS policies deny access.

> [!IMPORTANT]
> A Supabase **Service-Role Key** grants administrative bypass over all RLS policies. It **must never** be embedded in client source code, committed to version control, or exposed in environment bundles.

---

## 2. Row Level Security (RLS) Implementation

All 12 tables in the database schema have Row Level Security explicitly enabled (`ALTER TABLE ... ENABLE ROW LEVEL SECURITY;`).

1. **Role Verification via `public.is_admin()`**:
   Administrative privileges are verified on the database server using a secure SQL function:
   ```sql
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
   ```
2. **Sales Data Segregation**:
   Cashiers can only query sales records where `seller_id = auth.uid()`. Administrators can query all records across the entire store.
3. **Product Price Protection**:
   Cashiers can view product names and selling prices, but write operations (`INSERT`, `UPDATE`, `DELETE`) are restricted exclusively to administrators.

---

## 3. Concurrency Protection & Transaction Atomicity

A major retail vulnerability is the **race condition / double-sell hazard**, where two cashiers attempt to sell the last item of inventory simultaneously.

Nammalvar eliminates this vulnerability at the database engine level inside `process_sale`:
```sql
-- Lock product row for update to eliminate race conditions
SELECT * INTO v_product
FROM public.products
WHERE id = v_product_id
FOR UPDATE;

-- Strict stock verification
IF v_product.current_stock < v_qty THEN
    RAISE EXCEPTION 'Insufficient stock for "%". Requested: %, Available: %',
        v_product.name, v_qty, v_product.current_stock;
END IF;
```
If two terminals submit a checkout simultaneously, PostgreSQL forces the second transaction to wait until the first commits or rolls back, guaranteeing zero negative inventory.

---

## 4. Security Audit Findings & Remediation

A comprehensive automated and manual inspection of the repository was performed:

| Audit Check | Status | Finding / Action Taken |
|---|---|---|
| **Service-Role Keys** | **PASS** | No Supabase service-role keys detected in tracked files or Git history. |
| **Database Passwords** | **PASS** | No plain-text database passwords found in source code. Connection pooler URLs contain no embedded passwords. |
| **Private Signing Keys** | **PASS** | No `.jks`, `.keystore`, `.pem`, or `.key` private certificates tracked in Git. |
| **`.gitignore` Hardening** | **COMPLETED** | Updated `.gitignore` to explicitly exclude `.env`, `.env.*`, `supabase/.temp/`, keystores, and local report exports. |
| **Environment Template** | **COMPLETED** | Created sanitized [`.env.example`](file:///c:/Users/ABHIMANYU/Desktop/nammalvar-iyerkai-angadi/.env.example) for developers and CI/CD pipelines. |
| **Personal Data in Screenshots** | **FLAGGED & REMEDIATED** | Inspected external screenshot assets. Two screenshots depicting personal email addresses (`abhimanyutharanidharan@gmail.com` and `stdharan73@gmail.com`) were excluded from the public repository showcase. |
| **Live Database Verification** | **NOTICE** | Client code and migrations implement robust RLS and RPC constraints; developers must ensure migrations have been applied to their live Supabase instance. |

---

## 5. Security Recommendations for Production Deployment

1. **Keep Secrets in Environment Variables**: In production CI/CD builds, supply `SUPABASE_URL` and `SUPABASE_ANON_KEY` via `--dart-define` build arguments rather than relying on source defaults.
2. **Rotate Anon Key if Project Scope Changes**: If this open-source repository is made public on GitHub, generate a dedicated Supabase environment or rotate the anon key for production deployments.
3. **Enable Database Connection SSL**: Ensure all PostgreSQL client and pooler connections enforce TLS (`sslmode=require`).
