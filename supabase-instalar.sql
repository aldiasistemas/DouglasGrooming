-- =====================================================================
--  Al Día Sistemas · Douglas's Grooming
--  Instalación de la base de datos en Supabase
--
--  Cómo usarlo:
--  1. Cree un PROYECTO NUEVO de Supabase solo para esta app
--     (no lo corra en el proyecto de Elegancia ni de Cuadra).
--  2. Abra  SQL Editor → New query, pegue TODO este archivo y toque Run.
--  3. Revise las dos líneas marcadas con  👉  al final antes de correrlo.
--
--  Quién ve qué:
--  · aldia      → usted (Al Día Sistemas). Ve y edita todo, incluido Finanzas.
--  · admin      → quien administra el negocio: todo, MENOS Finanzas (no la ve ni sabe que existe).
--  · grooming   → sus horas, la agenda y editar la información del servicio.
--  · transporte → rutas, marcar recogido/entregado (nada más), sus horas y la agenda.
-- =====================================================================

-- ---------- Tablas ----------
create table if not exists public.registros (
  negocio     text        not null,
  tipo        text        not null,   -- cita, cliente, servicio, zona, equipo, config, hora, gasto, pago
  id          text        not null,
  data        jsonb       not null default '{}'::jsonb,
  actualizado timestamptz not null default now(),
  primary key (negocio, tipo, id)
);

create table if not exists public.perfiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  negocio text not null,
  rol     text not null check (rol in ('aldia','admin','grooming','transporte')),
  emp_id  text,
  nombre  text
);

create table if not exists public.invitaciones (
  correo  text not null,
  negocio text not null,
  rol     text not null check (rol in ('aldia','admin','grooming','transporte')),
  emp_id  text,
  nombre  text,
  creado  timestamptz not null default now(),
  primary key (correo, negocio)
);

-- Si ya había corrido una versión anterior (con el rol 'duena'), esto lo actualiza sin borrar nada
alter table public.perfiles     drop constraint if exists perfiles_rol_check;
alter table public.invitaciones drop constraint if exists invitaciones_rol_check;
update public.perfiles     set rol = 'admin' where rol = 'duena';
update public.invitaciones set rol = 'admin' where rol = 'duena';
alter table public.perfiles     add constraint perfiles_rol_check     check (rol in ('aldia','admin','grooming','transporte'));
alter table public.invitaciones add constraint invitaciones_rol_check check (rol in ('aldia','admin','grooming','transporte'));

-- ---------- Funciones de ayuda (leen el perfil de quien está conectado) ----------
create or replace function public.mi_rol() returns text
language sql stable security definer set search_path = public as $$
  select rol from perfiles where user_id = auth.uid()
$$;

create or replace function public.mi_negocio() returns text
language sql stable security definer set search_path = public as $$
  select negocio from perfiles where user_id = auth.uid()
$$;

create or replace function public.mi_emp() returns text
language sql stable security definer set search_path = public as $$
  select emp_id from perfiles where user_id = auth.uid()
$$;

-- ¿Puede ver este negocio? (Al Día ve todos los negocios del proyecto)
create or replace function public.es_mi_negocio(n text) returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((select rol = 'aldia' or negocio = n from perfiles where user_id = auth.uid()), false)
$$;

-- ---------- Seguridad por filas ----------
alter table public.registros    enable row level security;
alter table public.perfiles     enable row level security;
alter table public.invitaciones enable row level security;

drop policy if exists "leer registros"   on public.registros;
drop policy if exists "crear registros"  on public.registros;
drop policy if exists "cambiar registros" on public.registros;
drop policy if exists "borrar registros" on public.registros;

-- LEER
create policy "leer registros" on public.registros for select to authenticated using (
  es_mi_negocio(negocio) and (
       mi_rol() = 'aldia'                                                     -- Al Día: todo
    or (tipo in ('gasto','pago') and false)                                   -- Finanzas: nadie más
    or (tipo in ('cita','cliente','servicio','zona','equipo','config','licencia'))  -- todos los del negocio
    or (tipo = 'hora' and (mi_rol() = 'admin' or data->>'emp' = mi_emp()))   -- horas: admin todas, cada quien las suyas
  )
);

-- CREAR
create policy "crear registros" on public.registros for insert to authenticated with check (
  es_mi_negocio(negocio) and (
       mi_rol() = 'aldia'
    or (mi_rol() = 'admin' and tipo in ('cita','cliente','servicio','zona','equipo','config','hora'))
    or (tipo = 'hora' and data->>'emp' = mi_emp())
  )
);

-- CAMBIAR
create policy "cambiar registros" on public.registros for update to authenticated
using (
  es_mi_negocio(negocio) and (
       mi_rol() = 'aldia'
    or (mi_rol() = 'admin' and tipo in ('cita','cliente','servicio','zona','equipo','config','hora'))
    or (mi_rol() in ('grooming','transporte') and tipo = 'cita')              -- grooming: editar el servicio · transporte: solo recogido/entregado
    or (tipo = 'hora' and data->>'emp' = mi_emp())
  )
)
with check (
  es_mi_negocio(negocio) and (
       mi_rol() = 'aldia'
    or (mi_rol() = 'admin' and tipo in ('cita','cliente','servicio','zona','equipo','config','hora'))
    or (mi_rol() in ('grooming','transporte') and tipo = 'cita')
    or (tipo = 'hora' and data->>'emp' = mi_emp())
  )
);

-- BORRAR
create policy "borrar registros" on public.registros for delete to authenticated using (
  es_mi_negocio(negocio) and (
       mi_rol() = 'aldia'
    or (mi_rol() = 'admin' and tipo in ('cita','cliente','servicio','zona','equipo','config','hora'))
  )
);

-- Transporte solo puede cambiar si la mascota ya se recogió o entregó; nada más de la cita
create or replace function public.solo_entregas() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.tipo = 'cita' and mi_rol() = 'transporte'
     and ((new.data - 'trans') is distinct from (old.data - 'trans')
          or new.negocio <> old.negocio or new.id <> old.id or new.tipo <> old.tipo) then
    raise exception 'Transporte solo puede marcar si la mascota se recogió o se entregó.';
  end if;
  return new;
end $$;
drop trigger if exists solo_entregas on public.registros;
create trigger solo_entregas before update on public.registros
  for each row execute function public.solo_entregas();

-- Perfiles: cada quien lee el suyo; admin ve los de su negocio, pero nunca el de Al Día
drop policy if exists "leer perfiles" on public.perfiles;
create policy "leer perfiles" on public.perfiles for select to authenticated using (
  user_id = auth.uid()
  or mi_rol() = 'aldia'
  or (mi_rol() = 'admin' and negocio = mi_negocio() and rol <> 'aldia')
);

-- Invitaciones: admin invita a su equipo (grooming / transporte); Al Día invita a cualquiera
drop policy if exists "leer invitaciones"    on public.invitaciones;
drop policy if exists "crear invitaciones"   on public.invitaciones;
drop policy if exists "cambiar invitaciones" on public.invitaciones;
drop policy if exists "borrar invitaciones"  on public.invitaciones;
create policy "leer invitaciones" on public.invitaciones for select to authenticated using (
  mi_rol() = 'aldia' or (mi_rol() = 'admin' and negocio = mi_negocio() and rol in ('grooming','transporte'))
);
create policy "crear invitaciones" on public.invitaciones for insert to authenticated with check (
  mi_rol() = 'aldia' or (mi_rol() = 'admin' and negocio = mi_negocio() and rol in ('grooming','transporte'))
);
create policy "cambiar invitaciones" on public.invitaciones for update to authenticated
  using      (mi_rol() = 'aldia' or (mi_rol() = 'admin' and negocio = mi_negocio() and rol in ('grooming','transporte')))
  with check (mi_rol() = 'aldia' or (mi_rol() = 'admin' and negocio = mi_negocio() and rol in ('grooming','transporte')));
create policy "borrar invitaciones" on public.invitaciones for delete to authenticated using (
  mi_rol() = 'aldia' or (mi_rol() = 'admin' and negocio = mi_negocio() and rol in ('grooming','transporte'))
);

-- ---------- Al crear cuenta: si el correo fue invitado, se le da su acceso ----------
create or replace function public.al_crear_cuenta() returns trigger
language plpgsql security definer set search_path = public as $$
declare inv record;
begin
  select * into inv from invitaciones where lower(correo) = lower(new.email) order by creado desc limit 1;
  if found then
    insert into perfiles (user_id, negocio, rol, emp_id, nombre)
    values (new.id, inv.negocio, inv.rol, inv.emp_id, inv.nombre)
    on conflict (user_id) do update
      set negocio = excluded.negocio, rol = excluded.rol, emp_id = excluded.emp_id, nombre = excluded.nombre;
  end if;
  return new;   -- sin invitación la cuenta existe, pero no ve nada
end $$;

drop trigger if exists al_crear_cuenta on auth.users;
create trigger al_crear_cuenta after insert on auth.users
  for each row execute function public.al_crear_cuenta();

-- Si admin cambia el rol de alguien o lo quita del equipo, su acceso se actualiza
create or replace function public.al_cambiar_invitacion() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'DELETE' then
    delete from perfiles p using auth.users u
     where u.id = p.user_id and lower(u.email) = lower(old.correo) and p.negocio = old.negocio and p.rol <> 'aldia';
    return old;
  end if;
  insert into perfiles (user_id, negocio, rol, emp_id, nombre)
  select u.id, new.negocio, new.rol, new.emp_id, new.nombre from auth.users u where lower(u.email) = lower(new.correo)
  on conflict (user_id) do update
    set negocio = excluded.negocio, rol = excluded.rol, emp_id = excluded.emp_id, nombre = excluded.nombre
    where perfiles.rol <> 'aldia';
  return new;
end $$;

drop trigger if exists al_cambiar_invitacion on public.invitaciones;
create trigger al_cambiar_invitacion after insert or update or delete on public.invitaciones
  for each row execute function public.al_cambiar_invitacion();

-- ---------- Accesos iniciales ----------
-- 👉 Revise que DOUGLAS-01 sea el código del cliente (el mismo de config.js) y el correo de quien administra el negocio.
insert into public.invitaciones (correo, negocio, rol, nombre) values
  ('aldiasistemascr@gmail.com', 'DOUGLAS-01', 'aldia', 'Al Día Sistemas'),
  ('correo-del-negocio@ejemplo.com', 'DOUGLAS-01', 'admin', 'Administración')
on conflict (correo, negocio) do update set rol = excluded.rol, nombre = excluded.nombre;

-- ---------- Mensualidad ----------
-- Primer mes de regalo: queda pagado hasta el próximo día 23.
-- Cada mes, cuando le llegue el comprobante, entre a la app con su cuenta de Al Día →
-- Ajustes → "Registrar pago de un mes". Solo usted puede cambiar esto.
insert into public.registros (negocio, tipo, id, data)
select 'DOUGLAS-01', 'licencia', 'estado', jsonb_build_object(
  'pagadoHasta', to_char(case when extract(day from current_date) < 23
                              then date_trunc('month', current_date) + interval '22 days'
                              else date_trunc('month', current_date) + interval '1 month 22 days' end, 'YYYY-MM-DD'),
  'pagos', '[]'::jsonb)
on conflict (negocio, tipo, id) do nothing;
