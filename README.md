# Marchese CRM

React + TypeScript + Vite. Navy, black and gold workspace for recruitment, staffing and sales.

## Start

Node 22+; `npm ci`, copy `.env.example` to `.env.local`, fill in the dedicated Marchese Supabase URL and publishable key, then `npm run dev`. `npm run build` validates TypeScript and produces `dist/`.

Project: `lzcuhmszshahknmdmezl` (MarcheseCRM). Never point this application at ONYX45's database. Only public/publishable keys belong in the browser. Never store a service-role key in Vite variables or Git.

## Database

Versioned migrations are in `supabase/migrations`. They have been applied to Marchese's dedicated project. On a fresh project apply them in order with Supabase CLI or the SQL editor. Do not run them over existing unrelated tables.

See [operations](docs/OPERATIONS.md) for access, onboarding, deployment, backups, exports and remaining work. RLS regression script: `tests/rls.sql` (transactional, rollback-only; run through a trusted SQL test connection).

## Phase 1 status

Implemented: responsive shell and dashboard; invite-account password sign-in; primary roles plus six module scopes; database RLS and ownership protection; audited permission/record changes; companies/contacts, opportunities, projects, candidates, tasks and meeting create/list; pipeline drag/drop plus keyboard-accessible stage selector; JSON export of loaded accessible records; database-enforced meeting overlap prevention.

Pending: production SMTP/redirect configuration and real invitation delivery verification, complete record editing/deletion workflows, candidate document upload, retention/deletion workflow, advanced reports and paginated full exports. This is an initial foundation, not a completed production CRM.

No business sample data is shipped. No paid third-party services or automatic external emails are enabled.

## Language and access

Swedish is the default. The header language selector supports Swedish and English and remembers the browser preference. System labels and stages are translated without changing database keys or user-entered content. Public visitors can open the login page; business records remain protected by Supabase Auth and RLS. Two explicitly approved administrator accounts have been provisioned; passwords are never stored in the application or repository.

## Calendar, invitations and contact phones

Day/week/month calendar, owner and meeting-type filters, click-to-book, rescheduling, completion/cancellation and conflict checks are implemented. Company, contact and candidate forms accept phone numbers; directories support updating numbers and click-to-call. Admin team invitations use the deployed protected Edge Function; see [email setup](docs/EMAIL_INVITATIONS.md). External delivery still needs verified SMTP and redirect configuration. `npm test` covers calendar dates, overlaps, i18n and permission defaults; `tests/contact-calendar.sql` verifies phone writes and conflict rejection with rollback-only fixtures.
