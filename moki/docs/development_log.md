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
- [x] Personaje Chibbi.
- [x] Sistema de animaciones.
- [x] Interacciones con la mascota.
- [x] Habitación de Chibbi.
- [x] Sistema de necesidades (base: tiempo, estados, guardado e interfaz).

### Notas — Chibbi (2026-11-20)
- Montaje cutout híbrido: modo "pose completa" activo y rig Skeleton2D/Bone2D preparado.
- Pivotes medidos por silueta y template matching y comprobados con renders: las cabezas de expresión coinciden píxel a píxel con las cabezas integradas en `body_*`.
- Animaciones RESET, idle, bounce, wave, surprised, tilt. Expresiones independientes de la animación.
- Integrado en Home con `ChibbiStage` (toque → reacción aleatoria, sin interrumpir la reacción en curso).
- **Arte pendiente**: `torso_front` y `tail_front` (y otras vistas) para activar el rig; cabeza con ojos cerrados (parpadeo/sueño); caras triste, cansada y comiendo; brazos sin mano para usar `hands/`.

### Notas — Habitación (2026-11-20)
- `chibbi_room.tscn` con los recursos de `assets/characters/room/`. Acceso desde Home con el botón "Mi habitación".
- Las cajas `bin_shelf_*` y `bin_cabinet_*` encajan exactamente en los huecos del estante y del mueble bajo (escala común 0,62).
- Objetos seleccionables (`RoomItem`) por categoría; tocar muestra su nombre y Chibbi reacciona.
- **Recursos dañados, no usados**: `chair_blue.png`, `chair_orange.png` y `table_green_round.png` (partes borradas y fragmentos sueltos al quitar el fondo).
- Probado en 1280×720, 1600×720, 1280×960, 1920×1080 y 1024×768.

### Notas — Necesidades (2026-11-20)
- Hambre, Energía, Higiene y Diversión (0–100, 100 = satisfecha). Bajadas por minuto: 2 / 1,5 / 1 / 2,5 (configurable).
- Estados bien/medio/bajo/crítico con histéresis; Chibbi pasa a cara neutral y pide atención en bajo/crítico. Sin castigos ni muerte.
- Guardado en `user://moki_save.json` (cambio de escena, cada 30 s, al cerrar, segundo plano). La app cerrada no hace bajar las necesidades (opción desactivada).
- HUD en la habitación con un medidor por necesidad, generado desde la configuración.
- **Arte pendiente**: iconos de hambre, energía, higiene y diversión (ahora se muestran iniciales; Hambre e Higiene comparten "H").
- Pendiente para la siguiente etapa: acciones que suben las necesidades (comer, dormir, bañarse, jugar) mediante `NeedsManager.change()`.

### Nota sobre pruebas automáticas
- Las pruebas con ventana se abren en el segundo monitor (Windows no permite colocarlas fuera de pantalla) y pueden recibir clics reales. Las pruebas lógicas se ejecutan en headless y los renders con `gui_disable_input`.

## Fase 3: Sistema educativo
- [ ] Mundos educativos.
- [ ] Actividades.
- [ ] Progresión por niveles.

## Fase 4: Integración y pulido
- [ ] Dificultad adaptativa.
- [ ] Sistema de guardado.
- [ ] Pruebas finales.