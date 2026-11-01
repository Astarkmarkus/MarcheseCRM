# Operations & handover

## Architecture

`src/db.ts`: dedicated Supabase client and shared record types. `src/permissions.ts`: default permissions and explicit override handling. `src/main.tsx`: initial shell, auth, modules, forms and dashboard. `src/style.css`: responsive Marchese design tokens and components. Split module screens into separate components as workflows expand.

Companies have many contacts and opportunities. Projects reference companies and optionally won opportunities. Candidates are independent profiles; candidate_matches links them to many projects without duplication. Meetings have real start/end intervals. Tasks have owners and due dates. Team membership is independent of primary role. Configurable pipeline stages preserve stable identifiers; archive stages rather than deleting stages referenced by history.

## First admin

The two explicitly approved administrator accounts are provisioned and active. The temporary server-side setup endpoint is disabled and no credentials are stored in source. For future accounts, an approved user must first be invited through Supabase Authentication. After they accept, a trusted administrator inserts a profiles row with their auth user UUID, display_name, role='admin' and active=true. Never derive roles from user_metadata. Do not automatically make the first person who signs up an admin. Provision ONYX45 technical access only after Marchese explicitly approves its identity and scope.

Disable public signups in Supabase Auth for invite-only use. Set Site URL and approved redirect URLs to the actual deployed origins. Configure email delivery before enabling invitations. Do not expose the service-role key in the client. Team invitation delivery is intentionally not implemented in the browser.

## Permissions

Primary roles: admin, appointment_setter, sales, talent_broker. Explicit per-module overrides win over defaults, including `none`. Scopes: none, view_assigned, edit_assigned, view_team, edit_team, full. Assigned means owner_id equals auth.uid(); team means exact non-null team_id match. Full means read/write module records, not administrative access. Only active admins manage profiles, teams, permission overrides and stage definitions. Only admins can reassign or delete records. Active status is checked from the database on every policy evaluation, so revocation does not wait for JWT refresh.

Private security-definer lookup functions are narrowly used to avoid RLS recursion. Their search_path is empty, EXECUTE is revoked from PUBLIC, and they check auth.uid(). All public tables have RLS. No anon business-table grants. Audits store actor, entity, operation and changed column names, never candidate notes or document bodies. Candidate data requires its separate module permission; company access never grants candidate access.

The initial UI edits module overrides. Primary role changes, deactivation and invitations currently require trusted administration through Supabase; complete these UI workflows before wider rollout. Keep at least one Marchese-controlled admin. ONYX45 access can be revoked independently by deactivating its profile, without affecting ownership of data or code.

## Validation

`npm run build` checks TypeScript and production build. Run `tests/rls.sql` through a trusted SQL connection before enabling live sensitive data. It creates isolated fixture UUIDs and rolls back every change. Validate assigned and team scopes, overrides including none, candidate boundaries, deactivation and ownership protection. Supabase security advisors should be clean. Test Auth end to end with invited accounts before release; no credentials are generated or committed by this application.

## Deployment

GitHub repository: Astarkmarkus/MarcheseCRM. Public at initial inspection; change to private in GitHub settings if that remains the intended visibility. The application source has no secret credentials or business data.

Static frontend: npm ci; provide VITE_SUPABASE_URL and VITE_SUPABASE_PUBLISHABLE_KEY; npm run build; serve dist over HTTPS. Vite variables are compile-time, not runtime secrets. GitHub Pages uses `/MarcheseCRM/` base via GITHUB_ACTIONS. `.github/workflows/pages.yml` builds and deploys when Pages is configured to GitHub Actions. The workflow includes only the project URL and publishable frontend key. Sites hosting uses `.openai/hosting.json` and root base. No backend server or external email integration is required for this phase.

## Export, backup, retention

UI JSON export contains only the currently loaded accessible module rows (maximum 500). It is not a full backup. For complete Marchese handover use a trusted PostgreSQL dump/restore, plus a separate private Storage object backup once uploads exist. Verify backup restoration in an isolated project. Record the configured Supabase plan's actual backup retention and costs before relying on hosted backups. Define retention periods, lawful basis, candidate access/export/erasure procedures, and access reviews with Marchese before importing sensitive candidate data. Hard deletion and candidate uploads remain disabled in the first UI.

## Independent ownership

Marchese owns its business data. Software licensing, hosting and technical support are separate contractual matters. Transfer Supabase organization/project administration to Marchese-controlled accounts as agreed, maintain an independent backup/export and document support access revocation. Data ownership does not imply free hosting or assignment of software IP. No paid upgrades were enabled by this build.
