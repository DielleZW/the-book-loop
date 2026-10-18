-- Run in Supabase SQL Editor. Review before execution.
create extension if not exists pgcrypto;
create table if not exists public.admins (user_id uuid primary key references auth.users(id) on delete cascade);
create table if not exists public.books (
 id uuid primary key default gen_random_uuid(), owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 title text not null check (char_length(title) between 1 and 120), author text not null check (char_length(author) between 1 and 120),
 genre text not null check (char_length(genre) between 1 and 40), condition text not null check (condition in ('Like new','Good','Well loved')),
 description text not null default '' check (char_length(description)<=500), cover_path text,
 status text not null default 'pending' check (status in ('pending','approved','rejected','swapped')),
 created_at timestamptz not null default now(),
 constraint cover_path_owner check (cover_path is null or cover_path like owner_id::text || '/%')
);
create table if not exists public.reviews (
 id uuid primary key default gen_random_uuid(), owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 title text not null check (char_length(title) between 1 and 120), rating int not null check (rating between 1 and 5),
 review text not null check (char_length(review) between 1 and 500), status text not null default 'pending' check (status in ('pending','approved','rejected')),
 created_at timestamptz not null default now()
);
create table if not exists public.swap_requests (
 id uuid primary key default gen_random_uuid(), requester_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 book_id uuid not null references public.books(id) on delete cascade,
 status text not null default 'pending' check (status in ('pending','approved','rejected','completed')),
 created_at timestamptz not null default now(), unique(requester_id,book_id)
);
create or replace function public.is_bookloop_admin() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.admins where user_id=(select auth.uid()));
$$;
revoke all on function public.is_bookloop_admin() from public;
grant execute on function public.is_bookloop_admin() to authenticated;
create or replace function public.protect_book_fields() returns trigger language plpgsql set search_path='' as $$
begin
 if not public.is_bookloop_admin() then
  if tg_op='INSERT' then new.owner_id:=auth.uid(); new.status:='pending';
  elsif tg_op='UPDATE' then
   if old.owner_id is distinct from auth.uid() or old.status <> 'pending' then raise exception 'Cannot edit this listing'; end if;
   new.owner_id:=old.owner_id; new.status:=old.status;
  end if;
 end if;
 return new;
end; $$;
create or replace function public.protect_review_fields() returns trigger language plpgsql set search_path='' as $$
begin
 if not public.is_bookloop_admin() then
  if tg_op='INSERT' then new.owner_id:=auth.uid(); new.status:='pending';
  elsif tg_op='UPDATE' then
   if old.owner_id is distinct from auth.uid() or old.status <> 'pending' then raise exception 'Cannot edit review'; end if;
   new.owner_id:=old.owner_id; new.status:=old.status;
  end if;
 end if;
 return new;
end; $$;
create or replace function public.protect_request_fields() returns trigger language plpgsql set search_path='' as $$
begin
 if not public.is_bookloop_admin() then
  if tg_op='INSERT' then new.requester_id:=auth.uid(); new.status:='pending';
  else raise exception 'Only parent administrators can change requests'; end if;
 end if;
 return new;
end; $$;
drop trigger if exists book_guard on public.books;
create trigger book_guard before insert or update on public.books for each row execute function public.protect_book_fields();
drop trigger if exists review_guard on public.reviews;
create trigger review_guard before insert or update on public.reviews for each row execute function public.protect_review_fields();
drop trigger if exists request_guard on public.swap_requests;
create trigger request_guard before insert or update on public.swap_requests for each row execute function public.protect_request_fields();
alter table public.admins enable row level security;
alter table public.books enable row level security;
alter table public.reviews enable row level security;
alter table public.swap_requests enable row level security;
drop policy if exists admin_self on public.admins;
create policy admin_self on public.admins for select to authenticated using (user_id=auth.uid());
drop policy if exists books_read on public.books;
create policy books_read on public.books for select to authenticated using (status='approved' or owner_id=auth.uid() or public.is_bookloop_admin());
drop policy if exists books_public_read on public.books;
create policy books_public_read on public.books for select to anon using (status='approved');
drop policy if exists books_insert on public.books;
create policy books_insert on public.books for insert to authenticated with check (owner_id=auth.uid() and status='pending');
drop policy if exists books_admin_update on public.books;
create policy books_admin_update on public.books for update to authenticated using (public.is_bookloop_admin()) with check (public.is_bookloop_admin());
drop policy if exists reviews_read on public.reviews;
create policy reviews_read on public.reviews for select to authenticated using (status='approved' or owner_id=auth.uid() or public.is_bookloop_admin());
drop policy if exists reviews_public_read on public.reviews;
create policy reviews_public_read on public.reviews for select to anon using (status='approved');
drop policy if exists reviews_insert on public.reviews;
create policy reviews_insert on public.reviews for insert to authenticated with check (owner_id=auth.uid() and status='pending');
drop policy if exists reviews_admin_update on public.reviews;
create policy reviews_admin_update on public.reviews for update to authenticated using (public.is_bookloop_admin()) with check (public.is_bookloop_admin());
drop policy if exists requests_read on public.swap_requests;
create policy requests_read on public.swap_requests for select to authenticated using (requester_id=auth.uid() or public.is_bookloop_admin());
drop policy if exists requests_insert on public.swap_requests;
create policy requests_insert on public.swap_requests for insert to authenticated with check (requester_id=auth.uid() and status='pending' and exists(select 1 from public.books b where b.id=book_id and b.status='approved' and b.owner_id<>auth.uid()));
drop policy if exists requests_admin_update on public.swap_requests;
create policy requests_admin_update on public.swap_requests for update to authenticated using (public.is_bookloop_admin()) with check (public.is_bookloop_admin());
insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('book-covers','book-covers',false,5242880,array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public=false,file_size_limit=5242880,allowed_mime_types=array['image/jpeg','image/png','image/webp'];
drop policy if exists cover_upload on storage.objects;
create policy cover_upload on storage.objects for insert to authenticated with check (bucket_id='book-covers' and (storage.foldername(name))[1]=auth.uid()::text and lower(storage.extension(name)) in ('jpg','jpeg','png','webp'));
drop policy if exists cover_read on storage.objects;
create policy cover_read on storage.objects for select to authenticated using (bucket_id='book-covers' and (public.is_bookloop_admin() or exists(select 1 from public.books b where b.cover_path=name and (b.status='approved' or b.owner_id=auth.uid()))));
drop policy if exists cover_public_read on storage.objects;
create policy cover_public_read on storage.objects for select to anon using (bucket_id='book-covers' and exists(select 1 from public.books b where b.cover_path=name and b.status='approved'));
-- After registering your adult admin account, run separately with its auth.users UUID:
-- insert into public.admins(user_id) values ('YOUR-ADULT-ACCOUNT-UUID');
