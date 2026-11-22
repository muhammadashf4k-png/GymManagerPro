-- Gym Manager Pro: tenant-isolated starter schema
create extension if not exists pgcrypto;

create table if not exists public.gyms (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  gym_id uuid not null references public.gyms(id) on delete cascade,
  role text not null default 'owner' check (role in ('super_admin','owner','staff')),
  created_at timestamptz not null default now()
);

create or replace function public.current_gym_id()
returns uuid
language sql stable security definer
set search_path = public, pg_temp
as $$
  select gym_id from public.profiles where id = auth.uid()
$$;

create table if not exists public.members (
  id uuid primary key default gen_random_uuid(),
  gym_id uuid not null default public.current_gym_id() references public.gyms(id) on delete cascade,
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

-- Create a private gym workspace and owner profile automatically at signup.
create or replace function public.handle_new_gym_owner()
returns trigger
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  new_gym_id uuid;
  gym_label text;
begin
  gym_label := coalesce(nullif(trim(new.raw_user_meta_data->>'gym_name'), ''), 'My Gym');
  insert into public.gyms(name) values (gym_label) returning id into new_gym_id;
  insert into public.profiles(id, gym_id, role) values (new.id, new_gym_id, 'owner');
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_gym on auth.users;
create trigger on_auth_user_created_gym
  after insert on auth.users
  for each row execute function public.handle_new_gym_owner();

alter table public.gyms enable row level security;
alter table public.profiles enable row level security;
alter table public.members enable row level security;

drop policy if exists "owners see own gym" on public.gyms;
create policy "owners see own gym" on public.gyms
  for select to authenticated using (id = public.current_gym_id());
drop policy if exists "owners update own gym" on public.gyms;
create policy "owners update own gym" on public.gyms
  for update to authenticated using (id = public.current_gym_id())
  with check (id = public.current_gym_id());

drop policy if exists "users see own profile" on public.profiles;
create policy "users see own profile" on public.profiles
  for select to authenticated using (id = auth.uid());

drop policy if exists "members isolated by gym" on public.members;
create policy "members isolated by gym" on public.members
  for all to authenticated
  using (gym_id = public.current_gym_id())
  with check (gym_id = public.current_gym_id());

-- Run this script in the Supabase SQL Editor. Review and test before production.
