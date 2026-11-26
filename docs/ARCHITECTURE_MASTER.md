# Decisión de producto vigente — 26 noviembre 2026
El alcance estratégico sustituye el roadmap cartográfico anterior. No replicar mapas ni enciclopedias externas. Radar AI asesora en el chat, investiga fuentes actuales al recibir solicitudes, cuestiona hipótesis y prioriza tiempo, disfrute, colección y rendimiento observado. No afirmar verificación sin evidencia; separar reportes, corroboración y pruebas personales. La aplicación conserva objetivos, contexto de sesión, resultados y enlaces a fuentes; no tiene IA integrada ni acceso directo del asistente a Supabase. v0.14 implementa panel local de estrategia y exportación; siguientes prioridades: persistencia privada, integración autorizada, reconciliación de datos, pruebas móviles. Conservar módulos históricos sin priorizar su expansión.

---

# Garage Radar — arquitectura maestra y contrato operativo
## Objetivo
Copiloto personal de GTA VI para PS5, orientado a colección, exploración, actividades y aprendizaje. Evitar spoilers más allá del progreso declarado. La interfaz es la referencia del jugador; el asistente investiga, estructura, verifica y actualiza los datos mediante accesos autorizados.
## Estado de partida
Frontend PWA en GitHub Pages; Supabase Auth y PostgreSQL operativos según pruebas del usuario de autenticación y garaje. El mapa, catálogo de hallazgos y trucos siguen parcialmente en HTML/localStorage. Hay 45 referencias de descubrimientos y 28 secuencias reportadas en el código, no todas comprobadas ni necesariamente transcritas correctamente. Cuatro referencias regionales dependen del mapa maestro local; no son puntos de aparición confirmados. No asumir que las publicaciones prueban que el juego o sus contenidos están disponibles.
## Arquitectura objetivo
- GitHub: código, migraciones SQL, pruebas, documentación y datos de bootstrap no privados.
- Supabase: fuente operativa central, catálogo, fuentes, hallazgos, geometrías, tareas, garaje, trucos y observaciones.
- PWA: lectura autenticada, filtros, mapa, edición de progreso, caché offline y exportación.
- Asistente: interfaz conversacional; acceso futuro mediante herramienta autenticada o API restringida. No existe actualmente una conexión directa del asistente a PostgreSQL. Nunca publicar service_role, contraseñas ni tokens privados.
- Ingesta: enlace + evidencia aportada legítimamente; extracción estructurada; revisión; deduplicación; aprobación. No descarga indiscriminada de Instagram.
- Cartografía: map_id, revision de imagen, dimensiones, x/y normalizados, precisión regional o puntual, método de calibración. Prohibido trasladar coordenadas entre mapas sin transformación validada. La imagen generada es ilustrativa, no cartografía.
## Dominios de datos
Conservar tablas existentes y sus datos. Evolucionar mediante migraciones aditivas y reversibles.
1. vehicles, vehicle_sources: catálogo y evidencia.
2. discovery_sources, discovery_findings: fuentes y afirmaciones.
3. map_assets, map_locations: mapas y puntos con revisión y precisión.
4. user_garage, user_tasks: progreso privado.
5. cheat_catalog, cheat_trials: secuencias y resultados privados.
6. farming_attempts: intentos observados.
7. learning_views: tasas, tamaño de muestra, resultados netos y tiempo.
## Principios
Identidad estable por registro; fuentes originales; separar afirmaciones de hechos confirmados; conservar datos desconocidos como null; deduplicación por fuente e identidad; RLS para datos privados; escrituras de catálogo autorizadas y auditadas; exportación y recuperación; no almacenar medios sin derechos.
## Roadmap y puertas de aceptación
P0 v0.13 Consolidación: inventario de datos, migración idempotente, reconciliar conteos y fuentes, backup, prueba de dos usuarios, no perder localStorage. No declarar completada hasta ejecutar SQL y verificar lectura/escritura reales.
P0 v0.14 World Radar: un mapa principal, imagen autorizada, puntos con evidencia/calibración, recuentos y filtros; prueba visual móvil. Hallazgos sin ubicación permanecen en bandeja.
P1 v0.15 Discovery: importación manual de URL/captura, clasificación y revisión; análisis multimodal solo de contenido accesible y autorizado.
P1 v0.16 Planner: tareas, prioridades, sesiones según tiempo y región.
P1 v0.17 Learning: tasas observadas con denominadores, tiempo y rentabilidad; sin estimar probabilidades sin muestra; no confundir reportes con intentos.
P2 v1.0 Copiloto: API/herramienta autenticada de lectura y escritura limitada, confirmación para cambios destructivos, trazabilidad.
P2 v2.0 Automatización modular: Scout, Cartographer, Verifier, Collector, Strategist, Analyst; evaluar costes y permisos antes de automatizar.
## KPIs de aceptación propuestos
100% de registros migrados reconciliados; 100% de puntos con map_id y fuente o declaración del jugador; cero ubicaciones inventadas; cero secretos en frontend; cero accesos cruzados entre usuarios en pruebas; flujo móvil de consulta y registro comprobado. Son metas, no mediciones realizadas.
## Siguiente acción
Auditar esquemas existentes y contenido de las páginas, preparar migración y datos bootstrap reproducibles, verificar Supabase con el usuario. No añadir más páginas aisladas hasta completar consolidación.

## v0.15 — Strategic Memory
Implemented explicit private strategy read/publish/restore with optimistic revision checks, local recovery snapshot, and context JSON export/copy. Apply migration 005_strategy.sql in Supabase SQL Editor; independent of migration 004. Authenticated user RLS. No direct assistant API, automated research, or automatic cross-device merge. Test signed-in read/write, stale revision rejection, restore and two-user isolation before calling live. Legacy data unchanged.
