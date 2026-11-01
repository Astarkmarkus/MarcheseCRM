# Team email invitations

Admins use Team → Invite by email. The deployed `invite-team-member` Supabase Edge Function validates the caller token with Auth, checks the current active admin profile, validates the requested role and creates a protected invitation record. It uses Supabase Auth's `inviteUserByEmail`; no service-role key is exposed to the browser. No shared password is sent by email. The recipient follows the link and chooses a password (minimum 12 characters). The client handles invitation and password recovery landing sessions. Failed deliveries and retries are visible in Team; only administrators can read invitation records. Existing profiles are not silently promoted during retries. Per-recipient cooldown is 60 seconds and attempts are rate limited from the audited invitation events.

## Required Supabase configuration

These settings could not be verified or changed through the available Supabase tools. Dashboard access requires a separate Supabase sign-in.

1. Authentication → URL Configuration: Site URL = `https://marchese-crm.lovely-haven-7526.chatgpt.site`; allow redirect = `https://marchese-crm.lovely-haven-7526.chatgpt.site/?invite=1` (or this origin's appropriate allowed redirect pattern).
2. Authentication → Email → SMTP: configure Marchese's approved email sender with the provider's host, port, username and credential. Store credentials only in Supabase's secure SMTP settings. Do not put them in source code, GitHub, browser variables or SQL migrations.
3. Supabase's default mail service normally refuses addresses outside the project's organization team. Configure production SMTP before inviting external staff. See https://supabase.com/docs/guides/auth/auth-smtp . Provider quotas and costs remain the organization's responsibility; no paid service has been enabled by this change.
4. Review the invite template and sender identity; disable open self-signup if invite-only onboarding is required.
5. Test with an explicitly approved real recipient. No test invitations were sent to other people during development.

The frontend sends a request only when an administrator clicks Send invitation or Send again. The fixed redirect target is defined server-side. Success means Supabase accepted the send; it does not prove inbox delivery. Errors such as SMTP authorization, rate limits and existing members are shown rather than falsely reporting success.

## Deployment

Deploy `supabase/functions/invite-team-member/index.ts` to the dedicated Marchese project. `verify_jwt=false` is deliberate: the body validates every token with `auth.getUser` and rechecks profile authorization, supporting current Supabase signing keys. Requests without a valid token are rejected with 401; non-admin users are rejected with 403. CORS allows only the production Site, the configured GitHub Pages origin and the local QA origin. Deployment secrets use Supabase's built-in server environment.

Meeting booking currently creates internal calendar records. External attendee email invitations are a separate workflow and are not sent automatically by this implementation.
