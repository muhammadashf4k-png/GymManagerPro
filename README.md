# Gym Manager Pro

Multi-gym management app foundation. One gym owner account is designed to access only its own gym workspace.

## Current starter features
- Responsive Android-friendly web UI
- Overview dashboard and sample member records
- Add/search member records
- Supabase email/password auth integration
- Multi-tenant database schema with row-level security starter policies
- Preview mode when cloud credentials are not configured

## Run locally
`npm install`
`npm run dev`

## Enable secure cloud accounts
1. Create a Supabase project.
2. Open SQL Editor and run `supabase/schema.sql`.
3. In the project settings, copy the Project URL and anon/public key.
4. Add them as build environment variables:
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`
5. Configure Supabase Auth email confirmation and SMTP.
6. Deploy the Vite app to a static hosting provider and set the same environment variables there.

Never put a Supabase service-role key in browser code.

## Important status
This is an initial MVP scaffold, not a finished production SaaS. Payments, attendance, plans, super-admin controls, automated WhatsApp/SMS delivery, backups, and production-grade gym onboarding still need implementation and testing. WhatsApp/SMS require a provider account, approved templates/consent where applicable, and a secure server-side integration. Do not enter real customer data in preview mode.
