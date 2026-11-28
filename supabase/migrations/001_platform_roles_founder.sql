-- GLOBAL ENERGY & TECHNOLOGY
-- 001_platform_roles_founder.sql
-- REVIEW DRAFT ONLY. NOT APPLIED TO SUPABASE.
-- Purpose: establish a server-controlled platform role registry with one Founder.
-- Verify the Founder UUID against the intended Auth account before deployment.

begin;

create table if not exists public.platform_user_roles (
    user_id uuid primary key references auth.users(id) on delete cascade,
    role text not null check (role in ('founder', 'platform_admin')),
    created_at timestamptz not null default now()
);

alter table public.platform_user_roles enable row level security;

-- Database-level guarantee: at most one Founder row can exist.
create unique index if not exists platform_user_roles_single_founder
    on public.platform_user_roles ((role))
    where role = 'founder';

-- No direct client access. Only trusted database/server administration may
-- manage this table. Do not add client INSERT/UPDATE/DELETE policies.
revoke all on table public.platform_user_roles from public, anon, authenticated;

-- Sole Founder identity verified in the live Auth users table on 2026-11-28.
-- Do not replace this with client-editable user metadata or a profile field.
insert into public.platform_user_roles (user_id, role)
values ('7090de41-59c2-488e-849a-ef5446fd5a6c'::uuid, 'founder')
on conflict (user_id) do update
set role = 'founder'
where public.platform_user_roles.role = 'founder';

create or replace function public.is_platform_founder()
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
    select exists (
        select 1
        from public.platform_user_roles pur
        where pur.user_id = auth.uid()
          and pur.role = 'founder'
    );
$function$;

alter function public.is_platform_founder() owner to postgres;
revoke all on function public.is_platform_founder() from public, anon;
grant execute on function public.is_platform_founder() to authenticated;

comment on table public.platform_user_roles is
'Server-controlled platform roles. No direct client grants; Founder is assigned only by reviewed migration or trusted administrative operation.';

comment on function public.is_platform_founder() is
'Returns true only for the single protected Founder account. Safe for authenticated RLS checks; no client role mutation is permitted.';

commit;

-- Deployment checklist:
-- 1. Confirm the UUID above is the intended Founder account.
-- 2. Take/verify a database backup.
-- 3. Review current grants and dependencies.
-- 4. Apply in a staging project first.
-- 5. Verify anon=false and founder account=true using authenticated sessions.
-- 6. Do not expose admin UI until this migration and subsequent RLS policies pass tests.
