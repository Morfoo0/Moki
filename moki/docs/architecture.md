# MOKI - ARQUITECTURA DEL PROYECTO

## Escenas
- scenes/main/: escenas principales.
- scenes/home/: habitación y pantalla principal.
- scenes/characters/: escenas de personajes.
- scenes/minigames/: minijuegos.
- scenes/levels/: niveles educativos.
- scenes/ui/: interfaces de usuario.

## Scripts
- scripts/core/: sistemas centrales del juego.
- scripts/characters/: comportamiento de personajes.
- scripts/gameplay/: mecánicas del juego.
- scripts/progression/: progresión y desbloqueos.
- scripts/ui/: lógica de las interfaces.

## Recursos (.tres)
- resources/character/: librerías de piezas de Chibbi (`PartLibrary`).
- resources/needs/: configuración de necesidades (`NeedsConfig`).

## Autoloads (en este orden)
| Nombre | Script | Responsabilidad |
|---|---|---|
| `SceneManager` | scripts/core/scene_manager.gd | Cambio de escena con fundido; señal `scene_changed(path)`. |
| `SaveService` | scripts/core/save_service.gd | Guardado genérico por secciones en `user://moki_save.json`. |
| `NeedsManager` | scripts/progression/needs_manager.gd | Valores, paso del tiempo y estados de las necesidades. |

`SaveService` depende de `SceneManager` (guarda en cada cambio de escena) y `NeedsManager` de `SaveService` (registra su sección), por eso el orden importa.

## Navegación
`Main` → `Home` → (`Jugar`) `WorldMap` / (`Mi habitación`) `ChibbiRoom`.
Las rutas están en `ScenePaths`. `BigButton.target_scene` navega mediante `SceneManager`.

## Chibbi (personaje cutout híbrido)
- `scenes/characters/chibbi.tscn` (`Chibbi`, scripts/characters/chibbi.gd). Origen = suelo entre los pies.
- Piezas: `CharacterPart` (Sprite2D) lee textura y pivote de una `PartLibrary` (diccionario de `PartVariant`). Cambiar de variante no desplaza la pieza; `variant` se puede animar con pistas discretas.
- Dos modos:
  - **Pose completa** (actual): `body_*` de la vista + cabeza de expresión superpuesta exactamente sobre la cabeza integrada.
  - **Rig** (Skeleton2D/Bone2D: Hip → Tail, LegL/R, Torso → ArmL/R, Head): se activa solo cuando `chibbi_torsos.tres` tenga torso para la vista. Las librerías de torso y cola existen vacías a propósito.
- Animaciones (`AnimationPlayer`): RESET, idle, bounce, wave, surprised, tilt. Todas fijan la pose completa en su primer fotograma. El nodo `Body` se mueve en ambos modos; los huesos solo se ven en modo rig.
- Expresiones (`Chibbi.Mood`): NEUTRAL, HAPPY, LAUGHING, SURPRISED, ANGRY. Solo cambian la textura de la cabeza: son independientes de la animación. `rest_expression` = cara a la que vuelve tras reaccionar.
- `ChibbiStage` (Control): coloca y escala a Chibbi dentro de la UI y convierte toques en `react_to_tap()`. Solo su zona táctil cuenta como "punto" del control, para no tapar objetos detrás.

## Habitación de Chibbi
- `scenes/characters/chibbi_room.tscn` (`ChibbiRoom`, scripts/gameplay/chibbi_room.gd).
- Lienzo de diseño `Room` de 1280×720 centrado en pantalla; el fondo se estira en horizontal (es uniforme) y se prolonga con los colores de pared y suelo para otras proporciones. La `UI` se ancla a la pantalla, no al lienzo.
- Orden de dibujo: Background → Wall → FurnitureBack → ChibbiStage → FurnitureFront → Bins → Books → Props → Toys → UI.
- Objetos: `RoomItem` (scripts/gameplay/room_item.gd, TextureRect). Tamaño = PNG × `art_scale`; solo responde a toques en píxeles opacos; categoría (`DECOR`, `FURNITURE`, `TOY`, `BOOK`, `BIN`, `PROP`); emite `selected(item)`.
- `ChibbiRoom` reenvía `item_selected(item)`, muestra el nombre (rótulo) y Chibbi reacciona según la categoría (provisional).

## Necesidades
- Datos: `NeedDefinition` (id, nombre, color, icono, valor inicial, bajada por minuto, umbrales 70/40/15 e histéresis) y `NeedsConfig` (lista + tiempo, mínimo, app cerrada, autoguardado) en `resources/needs/chibbi_needs.tres`.
- **Convención: 100 = necesidad satisfecha** (el hambre es "saciedad").
- Estados: `NeedDefinition.State` = GOOD, MEDIUM, LOW, CRITICAL. Bajar de estado es inmediato; subir exige superar el umbral + histéresis.
- `NeedsManager`: acumula `delta × time_scale` (máx. 5 s por fotograma) y aplica la bajada cada `tick_interval`. Señales `need_changed`, `need_state_changed`, `overall_state_changed` (peor estado), `needs_loaded`. API: `get_value`, `get_state`, `get_overall_state`, `get_lowest_need`, `change(id, cantidad)` (entrada para futuras acciones), `set_paused`, `reset`.
- No hay castigos: los valores nunca bajan de `min_value` y Chibbi nunca usa expresiones negativas por necesidades.
- **Puente con Chibbi**: `ChibbiNeedsLink` (scripts/characters/chibbi_needs_link.gd) en Home y en la habitación. Peor estado → `rest_expression` (bien: HAPPY; resto: NEUTRAL). En bajo/crítico, Chibbi pide atención (`tilt`) cada 20/10 s y emite `attention_requested(need_id)`. Chibbi no depende de las necesidades.
- **Interfaz**: `NeedsHud` (scenes/ui/needs_hud.tscn) crea un `NeedMeter` por necesidad configurada (insignia + barra de color por estado, pulso en bajo/crítico, sin números). Tocar un medidor muestra su nombre en el rótulo de la habitación.

## Guardado
- `SaveService.register_section(nombre, getter, setter)`. Archivo `{version, saved_at, sections}`; escritura en `.tmp` + renombrado.
- Guarda: en cada cambio de escena, cada `autosave_interval` s, al cerrar la ventana y al pasar a segundo plano.
- Partida dañada o de versión nueva → se empieza de cero (aviso en el log). Secciones desconocidas se conservan; necesidades nuevas reciben su valor inicial.
- Tiempo con la app cerrada: desactivado por defecto (`offline_decay`); si se activa, máximo `offline_max_minutes` y nunca por debajo de `offline_floor`.
