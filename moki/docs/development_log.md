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
- [x] Sistema de cuidado: hambre y energía, descanso, inventario y alimentación.

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
- Primera versión con cuatro necesidades; corregida en el sistema de cuidado (ver abajo).
- Estados bien/medio/bajo/crítico con histéresis. Sin castigos ni muerte.
- Guardado en `user://moki_save.json` (cambio de escena, cada 30 s, al cerrar, segundo plano).
- HUD en la habitación con un medidor por necesidad, generado desde la configuración.

### Notas — Sistema de cuidado, inventario y alimentación (2026-11-20)
- **Solo dos necesidades: Hambre y Energía.** Higiene y Diversión eliminadas (eran solo datos en `chibbi_needs.tres`; sin restos en código, HUD ni guardado). Las partidas antiguas con cuatro necesidades se migran solas.
- La diversión no es una barra: vendrá de las actividades educativas, que serán un sistema independiente.
- Bajadas: hambre 2/min, energía 1,2/min. **Descanso**: energía +8/min, hambre −0,5/min; se despierta solo con la energía llena. Si se cierra la app con Chibbi descansando, al volver la energía se ha recuperado (máx. 8 h); el hambre nunca baja con la app cerrada.
- Menos presión: Chibbi solo pide atención en estado crítico (cada 30 s) y nunca descansando; solo el estado crítico pulsa en el HUD.
- Objetos como datos (`ItemDefinition`/`ItemCatalog`), autoload `Inventory`, barra de inventario y `ChibbiCare`.
- Alimentos: Manzana (+20, ilimitada), Plátano (+25, ilimitado), Galleta (+10, 5 unidades). Los básicos son ilimitados para que Chibbi siempre pueda comer.
- Alimentar: arrastrar hasta Chibbi o tocar alimento + tocar a Chibbi. Lleno: "¡Estoy lleno!" y no se gasta.
- Descanso: botón luna/sol o tocar el osito. Habitación oscurecida y "Z z z".
- La decoración de la habitación ya no responde (pared, cuadros, alfombra, muebles, mesa, silla).
- **Iconos provisionales** dibujados por código (manzana, plátano, galleta, luna, sol) en `ItemIcon`: se sustituyen asignando `icon` en cada `.tres`.
- **Arte pendiente**: iconos de alimentos, de descanso y de las necesidades (ahora iniciales H/E); cara de Chibbi comiendo y durmiendo (ojos cerrados); opcional: cama o cojín.
- Pruebas: 58 comprobaciones de integración en headless (necesidades, descanso, app cerrada, migración, inventario, alimentación, habitación, navegación). El gesto de arrastrar se verificó hasta el inicio del arrastre y el soltar con la API de soltar de Godot (en headless el motor no ejecuta esa fase con input simulado): **comprobar a mano con F5**.

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