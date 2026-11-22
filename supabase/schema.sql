-- Gym Manager Pro: multi-tenant database foundation
-- Run this in Supabase SQL Editor after creating a Supabase project.
create extension if not exists pgcrypto;
create table if not exists public.gyms (
 id uuid primary key default gen_random_uuid(),
 name text not null,
 created_at timestamptz not null default now()
);
create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 gym_id uuid references public.gyms(id) on delete set null,
 role text not null default 'owner' check (role in ('super_admin','owner','staff')),
 created_at timestamptz not null default now()
);
create table if not exists public.members (
 id uuid primary key default gen_random_uuid(),
 gym_id uuid not null default (nullif(current_setting('request.jwt.claim.gym_id', true), '')::uuid) references public.gyms(id) on delete cascade,
 name text not null,
 phone text,
 plan text not null default 'Monthly',
 fee numeric(12,2) not null default 0,
 joined_on date not null default current_date,
 expires_on date,
 status text not null default 'Active' check (status in ('Active','Expired','Paused')),
 created_at timestamptz not null default now()
);
create index if not exists members_gym_id_idx on public.members(gym_id);
alter table public.gyms enable row level security;
alter table public.profiles enable row level security;
alter table public.members enable row level security;
create or replace function public.current_gym_id() returns uuid language sql stable security definer set search_path=public as $$
 select gym_id from public.profiles where id = auth.uid()
$$;
create policy "owners see own gym" on public.gyms for select to authenticated using (id=public.current_gym_id());
create policy "signed-in users create gyms" on public.gyms for insert to authenticated with check (true);
create policy "users see own profile" on public.profiles for select to authenticated using (id=auth.uid());
create policy "users create own profile" on public.profiles for insert to authenticated with check (id=auth.uid());
create policy "users update own profile" on public.profiles for update to authenticated using (id=auth.uid()) with check (id=auth.uid());
create policy "members isolated by gym" on public.members for all to authenticated using (gym_id=public.current_gym_id()) with check (gym_id=public.current_gym_id());
-- Important: configure Supabase Auth email confirmation and SMTP before production use.
