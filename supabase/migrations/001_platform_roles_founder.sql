-- GLOBAL ENERGY & TECHNOLOGY
-- Founder role registry — REVIEW DRAFT ONLY; NOT APPLIED.
-- Confirm the Auth UUID and take a backup before deployment.

begin;

create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;

create table if not exists private.platform_user_roles (
    user_id uuid primary key references auth.users(id) on delete cascade,
    role text not null check (role in ('founder', 'platform_admin')),
    created_at timestamptz not null default now()
);

alter table private.platform_user_roles enable row level security;
revoke all on table private.platform_user_roles from public, anon, authenticated;

create unique index if not exists platform_user_roles_single_founder
    on private.platform_user_roles ((role))
    where role = 'founder';

-- Auth account verified in this project's auth.users on 2026-11-28.
-- Email and UUID are not repeated in client code.
insert into private.platform_user_roles (user_id, role)
values ('7090de41-59c2-488e-849a-ef5446fd5a6c'::uuid, 'founder')
on conflict (user_id) do update
set role = 'founder'
where private.platform_user_roles.role = 'founder';

create or replace function private.is_platform_founder()
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
    select exists (
        select 1
        from private.platform_user_roles pur
        where pur.user_id = (select auth.uid())
          and pur.role = 'founder'
    );
$function$;

alter function private.is_platform_founder() owner to postgres;
revoke all on function private.is_platform_founder() from public, anon;
grant execute on function private.is_platform_founder() to authenticated;

comment on table private.platform_user_roles is
'Private server-controlled platform role registry. No direct client table access.';
comment on function private.is_platform_founder() is
'Returns true only for the protected Founder account.';

commit;

-- Deployment gates:
-- 1. Verify the UUID belongs to the intended Founder.
-- 2. Back up the database.
-- 3. Apply in staging first.
-- 4. Test founder=true only for the Founder session; anon=false.
-- 5. Do not expose admin operations until all table policies and tests pass.
