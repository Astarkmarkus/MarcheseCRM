-- Trusted database test connection; no permanent fixtures. Choose the approved test admin.
begin;
select set_config('request.jwt.claim.sub',(select id::text from auth.users where email='markus@onyx45.com'),true);
set local role authenticated;
do $$declare company uuid; candidate uuid; begin
 insert into public.companies(name,phone,owner_id) values('QA rollback company','+46 70 123 45 67',auth.uid()) returning id into company;
 update public.companies set phone='+46 8 555 00 00' where id=company;
 if not exists(select 1 from public.companies where id=company and phone='+46 8 555 00 00') then raise exception 'Phone persistence failed';end if;
 insert into public.candidates(name,phone,owner_id) values('QA rollback candidate','+34 600 123 456',auth.uid()) returning id into candidate;
 insert into public.meetings(name,owner_id,starts_at,ends_at) values('QA rollback meeting',auth.uid(),'2099-01-02 09:00+01','2099-01-02 09:30+01');
 begin
  insert into public.meetings(name,owner_id,starts_at,ends_at) values('QA conflict',auth.uid(),'2099-01-02 09:15+01','2099-01-02 09:45+01');
  raise exception 'Overlap protection failed';
 exception when exclusion_violation then null;end;
 if not exists(select 1 from public.candidates where id=candidate and phone='+34 600 123 456') then raise exception 'Candidate phone persistence failed';end if;
end$$;
select 'PASS: company and candidate phone writes, meeting overlap protection' as result;
rollback;
