create extension if not exists pgcrypto;

insert into storage.buckets (id, name, public)
values ('resource-files', 'resource-files', false)
on conflict (id) do nothing;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'user' check (role in ('user', 'admin')),
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$ begin insert into public.profiles (id) values (new.id) on conflict do nothing; return new; end; $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

create table if not exists public.resources (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null default '',
  category text not null,
  file_path text,
  file_type text,
  file_size bigint,
  author_id uuid references auth.users(id) on delete set null,
  status text not null default 'published' check (status in ('pending', 'published', 'rejected')),
  download_count integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.favorites (
  user_id uuid references auth.users(id) on delete cascade,
  resource_id uuid references public.resources(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, resource_id)
);

create table if not exists public.download_logs (
  id bigint generated always as identity primary key,
  user_id uuid references auth.users(id) on delete set null,
  resource_id uuid references public.resources(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.resources enable row level security;
alter table public.favorites enable row level security;

drop policy if exists "users can read their own profile" on public.profiles;
create policy "users can read their own profile" on public.profiles for select to authenticated using (auth.uid() = id);
alter table public.download_logs enable row level security;

drop policy if exists "published resources are publicly readable" on public.resources;
create policy "published resources are publicly readable" on public.resources for select to anon, authenticated using (status = 'published');
drop policy if exists "users can view their own favorites" on public.favorites;
create policy "users can view their own favorites" on public.favorites for select to authenticated using (auth.uid() = user_id);
drop policy if exists "users can add their own favorites" on public.favorites;
create policy "users can add their own favorites" on public.favorites for insert to authenticated with check (auth.uid() = user_id);
drop policy if exists "users can delete their own favorites" on public.favorites;
create policy "users can delete their own favorites" on public.favorites for delete to authenticated using (auth.uid() = user_id);
drop policy if exists "users can submit resources" on public.resources;
create policy "admins can submit video resources" on public.resources for insert to authenticated with check (auth.uid() = author_id and category = '视频' and (select role from public.profiles where id = auth.uid()) = 'admin');

drop policy if exists "authenticated users can upload resource files" on storage.objects;
create policy "admins can upload video files" on storage.objects for insert to authenticated with check (bucket_id = 'resource-files' and (storage.foldername(name))[1] = (select auth.uid()::text) and (select role from public.profiles where id = auth.uid()) = 'admin');
drop policy if exists "users can read published resource files" on storage.objects;
create policy "users can read published resource files" on storage.objects for select to authenticated using (bucket_id = 'resource-files');
drop policy if exists "users can delete their own resource files" on storage.objects;
create policy "users can delete their own resource files" on storage.objects for delete to authenticated using (bucket_id = 'resource-files' and owner_id = (select auth.uid()::text));

insert into public.resources (title, description, category, file_type, file_size, status)
select * from (values
  ('小学语文五年级下册精品课件', '覆盖五年级下册重点课文的课堂课件，包含教学目标、课堂活动与课后练习。', '课件', 'PPTX', 19503513::bigint, 'published'),
  ('初中数学几何专题复习资料', '整理平面几何核心知识点与典型例题，适合复习课和专题训练使用。', '教案', 'PDF', 6501171::bigint, 'published'),
  ('校园安全教育主题班会', '校园安全主题班会视频资源，适合班级教育和家校共育场景。', '视频', 'MP4', 44879052::bigint, 'published'),
  ('英语自然拼读互动练习', '适合低年级学生的自然拼读练习单，配套课堂互动环节。', '练习', 'DOCX', 3984588::bigint, 'published'),
  ('教师公开课评价量表', '公开课听评课通用评价量表，支持按课堂环节进行记录。', '表格', 'XLSX', 1153433::bigint, 'published')
) as seed(title, description, category, file_type, file_size, status)
where not exists (select 1 from public.resources);
