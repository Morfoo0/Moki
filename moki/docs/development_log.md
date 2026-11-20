# MOKI - REGISTRO DE DESARROLLO

## Fase 1: Arquitectura y configuración
- [x] Arquitectura del proyecto.
- [x] Escena principal.
- [x] Navegación entre escenas.

### Notas (2026-11-20)
- Carpetas creadas según architecture.md; `asstes/` renombrada a `assets/`.
- `project.godot`: escena principal, viewport 1280×720, stretch `canvas_items`/`expand`, orientación horizontal (sensor).
- Autoload `SceneManager` (`scripts/core/scene_manager.gd`): `change_scene(path)` con fundido.
- `ScenePaths` (`scripts/core/scene_paths.gd`): rutas de escenas centralizadas.
- `BigButton` (`scenes/ui/big_button.tscn`): botón grande reutilizable con animación al presionar y `target_scene` opcional.
- Escenas: Main → Home → WorldMap (mundos deshabilitados de momento).

## Fase 2: Chibbi y experiencia principal
- [ ] Personaje Chibbi.
- [ ] Sistema de animaciones.
- [ ] Interacciones con la mascota.

## Fase 3: Sistema educativo
- [ ] Mundos educativos.
- [ ] Actividades.
- [ ] Progresión por niveles.

## Fase 4: Integración y pulido
- [ ] Dificultad adaptativa.
- [ ] Sistema de guardado.
- [ ] Pruebas finales.