# Garage Radar — Supabase Free (fase de preparación)

## Estado
El esquema SQL fue añadido a GitHub. **No** se ha creado todavía ningún proyecto en Supabase y la aplicación sigue usando `localStorage` con clave `garage-radar-v01`. No se han migrado datos de ningún usuario.

## ¿Por qué Supabase?
PostgreSQL + Auth + API integrada + RLS. Es adecuado para un MVP en GitHub Pages. El plan Free tiene límites y puede pausarse por inactividad; revisa https://supabase.com/pricing.

## Crear el proyecto
1. Entra a https://supabase.com/dashboard, crea una cuenta y un proyecto **Free**, nombre sugerido `garage-radar`.
2. Abre **SQL Editor**, pega y ejecuta `supabase/migrations/001_init.sql`.
3. Revisa **Table Editor** y confirma que se crearon `vehicles`, `vehicle_sources`, `user_garage` y `farming_attempts`.
4. En **Authentication** habilita un inicio de sesión (recomendado: email con confirmación).
5. En Authentication > URL Configuration define el Site URL `https://basdf-h1.github.io/gta6-garage-radar/` y los redirect URLs necesarios.

## Seguridad
- Las tablas personales usan políticas RLS que comparan `user_id` contra `auth.uid()`.
- Catálogo y fuentes son legibles públicamente, pero sus escrituras no se autorizan a clientes públicos. Adminístralos mediante SQL Editor o futuras funciones seguras.
- **Solo** el Project URL y la **publishable key** pueden estar en JavaScript público. Nunca copiar `service_role`, claves secretas, contraseñas ni una cadena de conexión PostgreSQL a GitHub.
- Antes de habilitar sincronización, probar con dos usuarios que cada uno solo vea sus propios datos.

## Siguiente implementación, todavía pendiente
- Cliente Supabase JS en la PWA y pantalla de login.
- Migración voluntaria de la colección local tras un backup JSON.
- Guardado/sincronización de `user_garage` y `farming_attempts`, con gestión de conflictos y modo offline.
- Panel de métricas (ingresos netos/minuto, tasa de éxito) calculadas únicamente con intentos reales registrados.
- Prueba de fin a fin en un iPhone.

## Persistencia local existente
No borrar localStorage ni desinstalar la PWA hasta respaldar el JSON y probar la migración de datos.
