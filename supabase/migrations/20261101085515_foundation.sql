-- Dedicated single-organization Marchese database. No ONYX45 data.
begin;
create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated;
create type public.primary_role as enum ('admin','appointment_setter','sales','talent_broker');
create type public.module_scope as enum ('none','view_assigned','edit_assigned','view_team','edit_team','full');
create table public.teams(id uuid primary key default gen_random_uuid(),name text not null);
create table public.profiles(user_id uuid primary key references auth.users(id) on delete cascade,display_name text not null,role public.primary_role not null default 'appointment_setter',active boolean not null default false,team_id uuid references public.teams(id),created_at timestamptz not null default now());
create table public.permissions(user_id uuid references public.profiles(user_id) on delete cascade,module text not null check(module in ('companies','contacts','opportunities','meetings','projects','candidates','tasks','reports')),scope public.module_scope not null,primary key(user_id,module));
create table public.audit_log(id bigint generated always as identity primary key,actor_id uuid,entity text not null,record_id text,action text not null,changed_columns text[],created_at timestamptz not null default now());
-- Internal, deliberately privileged lookups avoid recursive RLS on profiles.
create function private.is_admin() returns boolean language sql stable security definer set search_path='' as $$select auth.uid() is not null and exists(select 1 from public.profiles where user_id=auth.uid() and active and role='admin')$$;
create function private.effective_scope(m text) returns public.module_scope language plpgsql stable security definer set search_path='' as $$
declare p public.profiles; s public.module_scope;
begin
 if auth.uid() is null then return 'none'; end if;
 select * into p from public.profiles where user_id=auth.uid() and active;
 if not found then return 'none'; end if;
 select scope into s from public.permissions where user_id=p.user_id and module=m;
 if found then return s; end if;
 if p.role='admin' then return 'full'; end if;
 if p.role in ('appointment_setter','sales') and m in ('companies','contacts','opportunities','meetings','tasks') then return 'edit_assigned'; end if;
 if p.role='sales' and m in ('projects','reports') then return 'view_assigned'; end if;
 if p.role='talent_broker' and m in ('projects','candidates','meetings','tasks') then return 'edit_assigned'; end if;
 if p.role='talent_broker' and m in ('companies','contacts') then return 'view_assigned'; end if;
 return 'none';
end$$;
create function private.can_access(m text,record_owner uuid,record_team uuid,writing boolean default false) returns boolean language plpgsql stable security definer set search_path='' as $$
declare s public.module_scope; own_team uuid;
begin
 if auth.uid() is null then return false; end if;
 s:=private.effective_scope(m);
 if s='none' or (writing and s in ('view_assigned','view_team')) then return false; end if;
 if s='full' then return true; end if;
 if record_owner=auth.uid() then return true; end if;
 select team_id into own_team from public.profiles where user_id=auth.uid() and active;
 return s in ('view_team','edit_team') and own_team is not null and own_team=record_team;
end$$;
revoke all on function private.is_admin(),private.effective_scope(text),private.can_access(text,uuid,uuid,boolean) from public;
grant execute on function private.is_admin(),private.effective_scope(text),private.can_access(text,uuid,uuid,boolean) to authenticated;
create table public.companies(id uuid primary key default gen_random_uuid(),name text not null check(length(trim(name))>0),registration_number text,website text,industry text,city text,country text,status text not null default 'Lead',notes text,owner_id uuid not null references public.profiles(user_id),team_id uuid references public.teams(id),created_at timestamptz not null default now());
create unique index companies_registration_unique on public.companies(lower(registration_number)) where registration_number is not null;
create table public.contacts(id uuid primary key default gen_random_uuid(),company_id uuid not null references public.companies(id),name text not null,email text,phone text,title text,status text default 'New',notes text,owner_id uuid not null references public.profiles(user_id),team_id uuid references public.teams(id),created_at timestamptz not null default now());
create unique index contacts_company_email_unique on public.contacts(company_id,lower(email)) where email is not null;
create table public.pipeline_stages(id text primary key,label text not null,sort_order integer not null,archived boolean not null default false);
insert into public.pipeline_stages(id,label,sort_order) select s,s,n from unnest(array['New Lead','Researching','Contacted','Interested','Qualified','Meeting Booked','Meeting Completed','Proposal Sent','Negotiation','Won','Lost']) with ordinality as t(s,n);
create table public.opportunities(id uuid primary key default gen_random_uuid(),company_id uuid not null references public.companies(id),name text not null,stage text not null default 'New Lead' references public.pipeline_stages(id),value numeric check(value>=0),currency text default 'SEK',priority text default 'Normal',follow_up_at timestamptz,notes text,owner_id uuid not null references public.profiles(user_id),team_id uuid references public.teams(id),created_at timestamptz not null default now());
create table public.projects(id uuid primary key default gen_random_uuid(),company_id uuid not null references public.companies(id),opportunity_id uuid references public.opportunities(id),name text not null,status text not null default 'New Assignment' check(status in ('New Assignment','Requirements Confirmed','Sourcing','Screening','Client Interviews','Offer','Filled','Completed','On Hold','Cancelled')),positions integer not null default 1 check(positions>0),requirements text,deadline date,notes text,owner_id uuid not null references public.profiles(user_id),team_id uuid references public.teams(id),created_at timestamptz not null default now());
create table public.candidates(id uuid primary key default gen_random_uuid(),name text not null,email text,phone text,skills text[],available_from date,status text not null default 'New Candidate' check(status in ('New Candidate','Screening','Interview Scheduled','Interview Completed','Qualified','Presented to Client','Client Interview','Offer','Placed / Hired','Rejected / Withdrawn')),retention_review_at date,notes text,owner_id uuid not null references public.profiles(user_id),team_id uuid references public.teams(id),created_at timestamptz not null default now());
create table public.candidate_matches(id uuid primary key default gen_random_uuid(),candidate_id uuid not null references public.candidates(id) on delete cascade,project_id uuid not null references public.projects(id) on delete cascade,status text not null default 'New Candidate',created_at timestamptz not null default now(),unique(candidate_id,project_id));
create table public.meetings(id uuid primary key default gen_random_uuid(),name text not null,company_id uuid references public.companies(id),candidate_id uuid references public.candidates(id),starts_at timestamptz not null,ends_at timestamptz not null,meeting_type text not null default 'Sales Meeting',status text not null default 'Booked' check(status in ('Booked','Completed','Cancelled','No Show')),notes text,owner_id uuid not null references public.profiles(user_id),team_id uuid references public.teams(id),created_at timestamptz not null default now(),check(ends_at>starts_at),check(extract(epoch from (ends_at-starts_at)) in (900,1800,2700,3600)));
create extension if not exists btree_gist with schema extensions;
alter table public.meetings add constraint meetings_no_overlap exclude using gist (owner_id with =,tstzrange(starts_at,ends_at,'[)') with &&) where (status='Booked');
create table public.tasks(id uuid primary key default gen_random_uuid(),name text not null,status text default 'Open' check(status in ('Open','Completed','Cancelled')),due_at timestamptz,notes text,owner_id uuid not null references public.profiles(user_id),team_id uuid references public.teams(id),created_at timestamptz not null default now());
-- Assigned users may not grant access by changing ownership/team. Admin can reassign.
create function private.guard_assignment() returns trigger language plpgsql security invoker set search_path='' as $$begin
 if TG_OP='UPDATE' and not private.is_admin() and (new.owner_id is distinct from old.owner_id or new.team_id is distinct from old.team_id) then raise exception 'Only an administrator may reassign records'; end if;
 if TG_OP='INSERT' and not private.is_admin() and (new.owner_id<>auth.uid() or new.team_id is distinct from (select team_id from public.profiles where user_id=auth.uid())) then raise exception 'Invalid assignment'; end if;
 return new;
end$$;
-- Audit metadata only; no candidate notes, documents or credentials in logs.
create function private.audit_change() returns trigger language plpgsql security definer set search_path='' as $$
declare item jsonb; cols text[];
begin
 item:=case when TG_OP='DELETE' then to_jsonb(old) else to_jsonb(new) end;
 if TG_OP='UPDATE' then select array_agg(key) into cols from jsonb_each(to_jsonb(new)) where value is distinct from to_jsonb(old)->key; end if;
 insert into public.audit_log(actor_id,entity,record_id,action,changed_columns) values(auth.uid(),TG_TABLE_NAME,coalesce(item->>'id',item->>'user_id'),TG_OP,cols);
 return case when TG_OP='DELETE' then old else new end;
end$$;
revoke all on function private.audit_change(),private.guard_assignment() from public;
-- No direct anonymous access to business records.
do $$declare t text; begin
 foreach t in array array['companies','contacts','opportunities','projects','candidates','meetings','tasks'] loop
 execute format('alter table public.%I enable row level security',t);
 execute format('create policy read_access on public.%I for select to authenticated using(private.can_access(%L,owner_id,team_id,false))',t,t);
 execute format('create policy insert_access on public.%I for insert to authenticated with check(private.can_access(%L,owner_id,team_id,true))',t,t);
 execute format('create policy update_access on public.%I for update to authenticated using(private.can_access(%L,owner_id,team_id,true)) with check(private.can_access(%L,owner_id,team_id,true))',t,t,t);
 execute format('create policy delete_access on public.%I for delete to authenticated using(private.is_admin() and private.can_access(%L,owner_id,team_id,true))',t,t);
 execute format('create trigger guard_assignment before insert or update on public.%I for each row execute function private.guard_assignment()',t);
 execute format('create trigger audit_change after insert or update or delete on public.%I for each row execute function private.audit_change()',t);
 execute format('create index on public.%I(owner_id)',t);
 execute format('create index on public.%I(team_id)',t);
 execute format('grant select,insert,update,delete on public.%I to authenticated',t);
 end loop;
 foreach t in array array['profiles','permissions','teams','pipeline_stages','candidate_matches','audit_log'] loop execute format('alter table public.%I enable row level security',t); end loop;
 foreach t in array array['profiles','permissions','teams','pipeline_stages'] loop
 execute format('create policy admin_manage on public.%I for all to authenticated using(private.is_admin()) with check(private.is_admin())',t);
 execute format('create trigger audit_change after insert or update or delete on public.%I for each row execute function private.audit_change()',t);
 execute format('grant select,insert,update,delete on public.%I to authenticated',t);
 end loop;
end$$;
create policy self_profile on public.profiles for select to authenticated using(user_id=auth.uid());
create policy self_permissions on public.permissions for select to authenticated using(user_id=auth.uid() and exists(select 1 from public.profiles p where p.user_id=auth.uid() and active));
create policy stages_read on public.pipeline_stages for select to authenticated using(exists(select 1 from public.profiles where user_id=auth.uid() and active));
create policy own_team on public.teams for select to authenticated using(id=(select team_id from public.profiles where user_id=auth.uid() and active));
create policy audit_admin on public.audit_log for select to authenticated using(private.is_admin());
grant select on public.audit_log to authenticated;
-- Matches require access to both independently protected records.
create policy matches_read on public.candidate_matches for select to authenticated using(exists(select 1 from public.candidates c where c.id=candidate_id) and exists(select 1 from public.projects p where p.id=project_id));
create policy matches_write on public.candidate_matches for all to authenticated using(exists(select 1 from public.candidates c where c.id=candidate_id and private.can_access('candidates',c.owner_id,c.team_id,true)) and exists(select 1 from public.projects p where p.id=project_id and private.can_access('projects',p.owner_id,p.team_id,true))) with check(exists(select 1 from public.candidates c where c.id=candidate_id and private.can_access('candidates',c.owner_id,c.team_id,true)) and exists(select 1 from public.projects p where p.id=project_id and private.can_access('projects',p.owner_id,p.team_id,true)));
grant select,insert,update,delete on public.candidate_matches to authenticated;
-- Candidate files remain disabled until a reviewed upload workflow is implemented.
-- No bucket is made public and no storage policies are granted here.
commit;
