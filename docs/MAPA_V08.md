# Garage Radar v0.8 — cartografía con imagen autorizada

## Estado implementado
- Visor nuevo en `mapa-v08.html`: Leaflet 1.9.4 con `CRS.Simple`, zoom multitáctil y desplazamiento.
- Selección local de PNG/JPEG/WebP (máximo 15 MB) con confirmación explícita de derechos de uso.
- La imagen se guarda **solo en el navegador** mediante IndexedDB. No se sube a GitHub ni Supabase.
- Coordenadas de puntos normalizadas: X e Y de 0 a 1, sobre la imagen completa. El visor usa un espacio virtual 0..1000 y traduce `[Y, X]` para Leaflet.
- Colocación de puntos por toque, selección de vehículo, filtros, listado y exportación JSON de puntos.
- **Sin imagen pública añadida y sin coordenadas históricas importadas.** Reportes externos no equivalen a puntos ubicados correctamente.
- Puntos locales `garage-radar-map-v08`; colección previa `garage-radar-v01` intacta. No hay escritura de ubicaciones a Supabase en v0.8.

## Uso
1. Abre `https://basdf-h1.github.io/gta6-garage-radar/mapa-v08.html`.
2. Selecciona una imagen del mapa que tengas derecho a utilizar (tú decides si su uso personal cumple las licencias aplicables).
3. Confirma derechos de uso, pulsa «Usar imagen en este dispositivo».
4. Selecciona un vehículo y «Colocar punto»; toca su lugar en la imagen.
5. Exporta JSON para respaldar los puntos.

## Cartografía en GitHub: método pendiente
Solo subir a `assets/mapa-leonida-autorizado.webp` **después** de verificar explícitamente los derechos de publicación y distribución. Atribución y licencia deben quedar documentadas en `assets/LICENSE-MAP.md`; el visor todavía no enlaza automáticamente ese archivo porque no existe. Para integrar una imagen hospedada, usar `L.imageOverlay('./assets/mapa-leonida-autorizado.webp', [[0,0],[1000,1000]])`. Mantener la relación de aspecto de la imagen y los mismos puntos normalizados.

## Limitaciones y próximos pasos
- Coordenadas de candidatos históricos no verificadas, y no se transfieren desde el antiguo croquis.
- Cambiar una imagen de base desalineará los puntos previamente colocados, salvo que se haga recalibración.
- Imágenes personales grandes pueden ser descartadas por el almacenamiento del navegador, así que conservar el original.
- La biblioteca Leaflet se carga desde un CDN; requiere conexión al primer uso.
- v0.9: catálogo `map_locations`, `vehicle_locations`, `location_reports` con RLS y reconciliación por usuario; exigir evidencia antes de marcar como verificado.
- No crear claves secretas en el frontend ni asumir permiso para republicar mapas externos.
