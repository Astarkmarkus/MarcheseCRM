begin;
insert into auth.users(id) values('10000000-0000-0000-0000-000000000001'),('10000000-0000-0000-0000-000000000002');
insert into public.profiles(user_id,display_name,role,active) values('10000000-0000-0000-0000-000000000001','TEST setter','appointment_setter',true),('10000000-0000-0000-0000-000000000002','TEST talent','talent_broker',true);
-- Trusted fixture creation; guard checks see fixture owner in JWT.
select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001',true);
insert into public.companies(id,name,owner_id) values('20000000-0000-0000-0000-000000000001','RLS TEST company','10000000-0000-0000-0000-000000000001');
select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000002',true);
insert into public.candidates(id,name,owner_id) values('30000000-0000-0000-0000-000000000001','RLS TEST candidate','10000000-0000-0000-0000-000000000002');
set local role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001',true);
do $$begin
 if (select count(*) from public.companies)<>1 then raise exception 'FAIL own company read'; end if;
 if (select count(*) from public.candidates)<>0 then raise exception 'FAIL candidate isolation'; end if;
 begin insert into public.permissions values(auth.uid(),'candidates','full');raise exception 'FAIL privilege escalation';exception when insufficient_privilege then null;end;
 update public.candidates set name='should not update';if found then raise exception 'FAIL unauthorized candidate update';end if;
 begin update public.companies set owner_id='10000000-0000-0000-0000-000000000002';raise exception 'FAIL owner reassignment';exception when raise_exception then if SQLERRM='FAIL owner reassignment' then raise;end if;end;
end$$;
select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000002',true);
do $$begin
 if (select count(*) from public.companies)<>0 then raise exception 'FAIL assigned isolation'; end if;
 if (select count(*) from public.candidates)<>1 then raise exception 'FAIL own candidate read'; end if;
end$$;
reset role;
insert into public.permissions values('10000000-0000-0000-0000-000000000002','companies','full');
set local role authenticated;
do $$begin if (select count(*) from public.companies)<>1 then raise exception 'FAIL override';end if;end$$;
reset role;
update public.profiles set active=false where user_id='10000000-0000-0000-0000-000000000002';
set local role authenticated;
do $$begin if (select count(*) from public.candidates)<>0 or (select count(*) from public.companies)<>0 then raise exception 'FAIL revoked access';end if;end$$;
reset role;
select 'PASS: assigned isolation, candidate isolation, privilege escalation, ownership protection, overrides, deactivation' as result;
rollback;
