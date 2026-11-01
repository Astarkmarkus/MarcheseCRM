begin;
alter table public.companies add column phone text;
alter table public.companies add constraint companies_phone_length check(phone is null or length(phone)<=50);
alter table public.contacts add constraint contacts_phone_length check(phone is null or length(phone)<=50);
alter table public.candidates add constraint candidates_phone_length check(phone is null or length(phone)<=50);
create table public.team_invitations (
 id uuid primary key default gen_random_uuid(),
 email text not null unique check(email=lower(trim(email))),
 display_name text not null,
 role public.primary_role not null default 'appointment_setter',
 user_id uuid references auth.users(id) on delete set null,
 invited_by uuid not null references public.profiles(user_id),
 status text not null check(status in ('sending','sent','failed','accepted')),
 delivery_error text,
 last_attempt_at timestamptz not null default now(),
 last_sent_at timestamptz,
 created_at timestamptz not null default now()
);
alter table public.team_invitations enable row level security;
create policy invitations_admin_read on public.team_invitations for select to authenticated using(private.is_admin());
grant select on public.team_invitations to authenticated;
revoke insert,update,delete on public.team_invitations from anon,authenticated;
create function private.audit_invitation() returns trigger language plpgsql security definer set search_path='' as $$begin
 insert into public.audit_log(actor_id,entity,record_id,action) values(coalesce(auth.uid(),new.invited_by),'team_invitations',new.id::text,TG_OP);
 return new;
end$$;
revoke all on function private.audit_invitation() from public;
create trigger audit_change after insert or update on public.team_invitations for each row execute function private.audit_invitation();
create index on public.team_invitations(invited_by);
create index on public.team_invitations(user_id);
create index on public.team_invitations(last_attempt_at);
commit;
