begin;
create function private.guard_links() returns trigger language plpgsql security invoker set search_path='' as $$
declare j jsonb:=to_jsonb(new);
begin
 if j->>'company_id' is not null and not exists(select 1 from public.companies where id=(j->>'company_id')::uuid) then raise exception 'Company is not accessible';end if;
 if j->>'candidate_id' is not null and not exists(select 1 from public.candidates where id=(j->>'candidate_id')::uuid) then raise exception 'Candidate is not accessible';end if;
 if j->>'opportunity_id' is not null and not exists(select 1 from public.opportunities where id=(j->>'opportunity_id')::uuid and company_id=(j->>'company_id')::uuid) then raise exception 'Opportunity must be accessible and belong to the company';end if;
 return new;
end$$;
revoke all on function private.guard_links() from public;
do $$declare t text;begin foreach t in array array['contacts','opportunities','projects','meetings'] loop execute format('create trigger guard_links before insert or update on public.%I for each row execute function private.guard_links()',t);end loop;end$$;
commit;
