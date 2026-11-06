# Douglas's Grooming · Al Día Sistemas

App de agenda, expedientes, transporte (recoger y entregar), horas del equipo y finanzas.
Cliente **DOUGLAS-01** · Mensualidad **₡30 000** · Pago el **23** de cada mes por SINPE al 8599-4415.

## Quién ve qué

| Cuenta | Qué ve |
|---|---|
| **Al Día Sistemas** (aldiasistemascr@gmail.com) | Todo, incluido **Finanzas** y la mensualidad. Nunca se bloquea. |
| **Administración** (quien maneja el negocio) | Agenda, Clientes, Transporte, Equipo y Ajustes. **No ve Finanzas**: ni la pestaña ni los datos. |
| **Grooming** | Sus horas (marcar entrada y salida) y la agenda, con sus citas primero. Sin precios. |
| **Transporte** | Las rutas de recoger y entregar, sus horas y la agenda. |

Gastos, planilla y tarifas del equipo solo los puede leer la cuenta de Al Día. Eso lo bloquea la base de datos, no solo la pantalla.

## Instalación (una sola vez)

### 1. Supabase
1. Entre a supabase.com con aldiasistemascr@gmail.com → organización **AlDíaSistemas** → **New project**. Use un proyecto **nuevo**, solo para esta app.
2. Abra **SQL Editor → New query**, pegue todo `supabase-instalar.sql` y toque **Run**.
   Antes, cambie `correo-del-negocio@ejemplo.com` (casi al final) por el correo de quien administra el negocio.
3. Vaya a **Authentication → URL Configuration** y en **Site URL** ponga la dirección de GitHub Pages, por ejemplo `https://aldiasistemas.github.io/DouglasGrooming/`.
4. Vaya a **Project Settings → API** y copie la **Project URL** y la clave **anon public**.

### 2. config.js
Pegue esas dos cosas en `config.js`, donde dice `PEGUE_AQUI…`. Nunca pegue la clave `service_role`.

### 3. GitHub Pages
1. En la cuenta **aldiasistemas**, cree el repositorio `DouglasGrooming` (público).
2. Suba todos los archivos de esta carpeta: **Add file → Upload files**.
3. Vaya a **Settings → Pages → Branch: main → Save**. En un par de minutos la app queda en la dirección del paso 1.3.

### 4. Cuentas
1. **Usted:** abra la app → **Soy nuevo: crear mi cuenta** con aldiasistemascr@gmail.com → confirme el correo → entre.
2. **Administración del negocio:** hace lo mismo con su correo (el que puso en el SQL).
3. **El equipo:** se agregan en **Equipo → + Integrante** con nombre, correo y qué hace (Grooming o Recoger y entregar). Después, cada persona crea su cuenta con ese mismo correo desde su teléfono.
4. **Instalar como app:** en el celular abra la dirección → menú del navegador → **Agregar a pantalla de inicio**.

## Cada mes
- El negocio la ve siempre en **Ajustes → Mi suscripción**, y un aviso 5 días antes del 23. Si no paga, la app se pausa para ellos (los datos quedan guardados).
- Cuando le llegue el comprobante: entre con su cuenta → **Ajustes → Registrar pago de un mes**. La app se desbloquea sola en todos los teléfonos.
- El primer mes queda pagado hasta el próximo 23.

## Finanzas y facturas (solo usted)
- **Facturas:** cuando un cliente pide factura electrónica (se marca en su ficha), sus servicios terminados aparecen en **Finanzas → Facturas por emitir**. Toque uno, copie los datos, emítala y márquela como emitida. El negocio no ve esta parte.
- **Ingresos:** salen solos de los servicios realizados y cobrados.
- **Gastos:** **+ Gasto**, con las mismas categorías de Elegancia.
- **Planilla:** toque el nombre de cada integrante para poner cuánto gana por hora o fijo. El monto se calcula con las horas que marcan. **Registrar pago** lo anota como gasto.
