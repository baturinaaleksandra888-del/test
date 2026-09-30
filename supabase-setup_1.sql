-- Выполните целиком в Supabase: SQL Editor -> New query -> Run

create table if not exists public.results (
  id bigint generated always as identity primary key,
  name text not null check (char_length(name) between 1 and 30),
  score int not null,
  total int not null default 6,
  created_at timestamptz not null default now()
);

alter table public.results enable row level security;

-- Читать стену может кто угодно, писать напрямую в таблицу нельзя
drop policy if exists "read all" on public.results;
create policy "read all" on public.results for select to anon using (true);
grant select on public.results to anon;

-- Запись идёт только через эту функцию. Баллы считает база, ключ ответов в браузер не попадает
create or replace function public.submit_result(p_name text, p_answers int[])
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  ans_key int[] := array[1,2,3,2,0,3];
  s int := 0;
  i int;
  n text := trim(coalesce(p_name, ''));
begin
  if char_length(n) not between 1 and 30 then raise exception 'bad name'; end if;
  if array_length(p_answers, 1) is distinct from 6 then raise exception 'bad answers'; end if;
  for i in 1..6 loop
    if p_answers[i] = ans_key[i] then s := s + 1; end if;
  end loop;
  insert into public.results(name, score, total) values (n, s, 6);
  return s;
end;
$$;

revoke all on function public.submit_result(text, int[]) from public;
grant execute on function public.submit_result(text, int[]) to anon;
