# Garage Radar — Discovery AI v0.9

## Qué implementamos
- Página web `discovery.html` enlazada desde Garage Radar.
- Inicio de sesión por email con la misma instancia de Supabase que usa `nube.html`.
- Fuentes de Instagram, YouTube, TikTok y enlaces HTTPS de otros sitios; se conservan título, creador, URL y observaciones.
- Hallazgos con estado `unverified`, `review`, `approved` o `discarded`. Aprobar es una revisión personal: **no implica corroboración objetiva ni publica una coordenada en el mapa**.
- Tareas personales con prioridades y estados `todo`, `doing`, `done`, `discarded`.
- Importación manual del caso DISC-002 AfrozPlays: enlace original y 12 nombres legibles de la captura. 36 puntos es una afirmación del creador, no 36 ubicaciones georreferenciadas ni validadas.
- Antiduplicados: restricción única `(user_id, source_url)` en fuentes y `(source_id,item_label)` en hallazgos.
- Privacidad: todas las tablas están protegidas por RLS y privilegios SQL para `authenticated`. Sin acceso anónimo.

## Para activar Supabase
1. Entra al proyecto `garage-radar` → **SQL Editor** → nueva consulta.
2. Copia y ejecuta completo `supabase/migrations/003_discovery_ai.sql`.
3. El resultado final debe mostrar **3 filas** (`discovery_sources`, `discovery_findings`, `user_tasks`) con `rls_enabled = true`, `can_read = true`, `can_insert = true`, `anon_can_read = false`.
4. En **Authentication → URL Configuration → Redirect URLs**, agrega **exactamente** `https://basdf-h1.github.io/gta6-garage-radar/discovery.html` si vas a solicitar enlaces de acceso desde esta pantalla. Si ya iniciaste sesión desde `nube.html` en el mismo navegador, normalmente no hace falta solicitar un enlace nuevo.
5. Abre `https://basdf-h1.github.io/gta6-garage-radar/discovery.html` después de completar la publicación de GitHub Pages.

## Primera validación
1. Inicia sesión; carga la lista vacía sin errores.
2. Pulsa **Importar 12 candidatos revisables a mi cuenta**.
3. Comprueba que se crea la fuente `DISC-002` y se ven los 12 hallazgos `Sin verificar`.
4. Elige uno y pulsa `＋ Por hacer`; debería aparecer en tus actividades.
5. Modifica el estado de una tarea y recarga para confirmar persistencia.
6. Pulsa de nuevo Importar: no debería crear duplicados.

## Límites expresos
- **No hay descarga automática de Reels**; los enlaces guardados no permiten a la aplicación ver automáticamente el video.
- **No se procesan videos ni capturas mediante IA**; esto requiere un pipeline multimodal posterior y contenido accesible legalmente.
- **No se añaden puntos georreferenciados a los mapas v0.8**: falta calibración y evidencia de coordenadas.
- **No se modifica** `garage-radar-v01`, ni las tablas `user_garage` y `farming_attempts`.
- El almacenamiento gratuito de Supabase puede tener límites o pausas por inactividad.
- Las capturas y datos privados del usuario no se suben al repositorio.

## Próximas mejoras
1. Aplicar una fuente de ubicación al mapa solo después de revisión manual de coordenada + etiqueta `map_id` + evidencia.
2. Añadir un analizador multimodal de archivos compartidos con permiso, sin scraping de Instagram y sin exponer claves secretas.
