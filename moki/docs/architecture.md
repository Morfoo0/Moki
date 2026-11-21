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
- resources/items/: catálogo de objetos (`ItemCatalog`) y sus definiciones (`ItemDefinition`): `food/` (alimentos) y `room/` (acciones de objetos de la habitación).

## Autoloads (en este orden)
| Nombre | Script | Responsabilidad |
|---|---|---|
| `SceneManager` | scripts/core/scene_manager.gd | Cambio de escena con fundido; señal `scene_changed(path)`. |
| `SaveService` | scripts/core/save_service.gd | Guardado genérico por secciones en `user://moki_save.json`. |
| `NeedsManager` | scripts/progression/needs_manager.gd | Valores, paso del tiempo, estados y descanso de las necesidades. |
| `Inventory` | scripts/progression/inventory.gd | Cantidades de objetos, validación y uso (aplica efectos en `NeedsManager`). |

`SaveService` depende de `SceneManager` (guarda en cada cambio de escena); `NeedsManager` e `Inventory` registran su sección en `SaveService`, e `Inventory` usa `NeedsManager`. Por eso el orden importa.

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
- Objetos: `RoomItem` (scripts/gameplay/room_item.gd, TextureRect). Tamaño = PNG × `art_scale`; solo responde a toques en píxeles opacos; categoría (`DECOR`, `FURNITURE`, `TOY`, `BOOK`, `BIN`, `PROP`); emite `selected(item)`; acción opcional `item: ItemDefinition`.
- **Decoración vs interactivos**: pared, cuadros, banderines, ventana, alfombra, estante, mueble bajo, mesa y silla tienen `interactive = false` (no responden). Juguetes, libros, cajas y objetos de la mesa son interactivos. El osito tiene la acción de descanso (`resources/items/room/teddy_rest.tres`).
- `ChibbiRoom` reenvía `item_selected(item)` y muestra el nombre en el rótulo. Si el objeto tiene acción la gestiona `ChibbiCare`; si no, Chibbi reacciona según la categoría.
- Barra superior (`UI/TopBar`): Volver · botón de descanso · barra de inventario · HUD de necesidades.

## Necesidades
- **Solo dos**: Hambre (`hunger`) y Energía (`energy`).
- Datos: `NeedDefinition` (id, nombre, color, icono, valor inicial, bajada por minuto, cambio por minuto al descansar, umbrales 70/40/15 e histéresis) y `NeedsConfig` (lista + tiempo, mínimo, app cerrada, descanso, autoguardado) en `resources/needs/chibbi_needs.tres`.
- **Convención: 100 = necesidad satisfecha** (el hambre es "saciedad").
- Estados: `NeedDefinition.State` = GOOD, MEDIUM, LOW, CRITICAL. Bajar de estado es inmediato; subir exige superar el umbral + histéresis.
- `NeedsManager`: acumula `delta × time_scale` (máx. 5 s por fotograma) y aplica la bajada cada `tick_interval`. Señales `need_changed`, `need_state_changed`, `overall_state_changed` (peor estado), `needs_loaded`. API: `get_value`, `get_state`, `get_overall_state`, `get_lowest_need`, `change(id, cantidad)` (entrada para futuras acciones), `set_paused`, `reset`.
- **Descanso**: `NeedsManager.set_resting()`. Mientras descansa, cada necesidad usa `resting_rate_per_minute` (energía +8/min, hambre −0,5/min). Se despierta solo con la energía llena (`wake_when_rested`). Nunca es obligatorio.
- Principios: sin castigos, sin muerte, sin presión. Los valores nunca bajan de `min_value`; Chibbi nunca usa expresiones negativas por necesidades; con la app cerrada nada baja (y si se dejó descansando, la energía se recupera, máx. `offline_rest_max_minutes`).
- **Puente con Chibbi**: `ChibbiNeedsLink` (scripts/characters/chibbi_needs_link.gd) en Home y en la habitación. Peor estado → `rest_expression` (bien: HAPPY; resto: NEUTRAL). Solo en estado crítico (y nunca descansando) Chibbi pide atención con calma cada 30 s (`attention_requested(need_id)`). Al descansar: cara tranquila y animación a 0,4×; al despertar, `bounce`. Chibbi no depende de las necesidades.
- **Interfaz**: `NeedsHud` (scenes/ui/needs_hud.tscn) crea un `NeedMeter` por necesidad configurada (insignia + barra de color por estado, pulso solo en crítico, sin números). Tocar un medidor muestra su nombre en el rótulo de la habitación.

## Objetos, inventario y alimentación
- **`ItemDefinition`** (scripts/gameplay/items/item_definition.gd): id, nombre, tipo (`FOOD`, `REST`, `TOY`, `OTHER`), icono (o icono provisional `placeholder`), acción (`FEED`, `REST`, `NONE`), destino (`CHIBBI`, `ROOM`), efectos `{necesidad: puntos}`, `refuse_when_not_needed`, `show_in_inventory`, `consumable`, `unlimited`, cantidades inicial/máxima, reacción y expresión de Chibbi y mensaje.
- **`ItemCatalog`** (`resources/items/item_catalog.tres`): lista de objetos. **Añadir un objeto = crear su `.tres` y añadirlo al catálogo**; el inventario y la barra lo muestran solos.
- **`Inventory`** (autoload): `get_quantity` (−1 = ilimitado), `can_use(id, destino)` → `UseResult` (`OK`, `UNKNOWN_ITEM`, `NOT_AVAILABLE`, `WRONG_TARGET`, `NOT_NEEDED`), `use(id, destino)` (aplica efectos con `NeedsManager.change()` y gasta una unidad), `add(id, n)` (futuras recompensas). Señales `quantity_changed`, `item_used`, `use_refused`. Sección de guardado `inventory`.
- **UI**: `InventoryBar` (scenes/ui/inventory_bar.tscn) crea un `InventorySlot` por objeto del inventario (filtrable por tipo; en la habitación, comida). Casilla: toque = seleccionar; arrastre = soltar sobre Chibbi; contador solo si no es ilimitado. `ItemIcon` dibuja el icono del objeto o uno provisional vectorial.
- **`ChibbiCare`** (scripts/gameplay/chibbi_care.gd, nodo de la habitación): alimentar (arrastrar el alimento hasta Chibbi, o tocar alimento + tocar a Chibbi), validar con `Inventory`, animar la comida hacia la boca, reacción de Chibbi y mensaje. Si está lleno, lo dice con calma y no se gasta nada. Descansar con el botón (luna/sol) o con el osito; tocar a Chibbi o darle comida lo despierta. Habitación oscurecida y "Z z z" mientras descansa.
- `ChibbiStage` ofrece `tap_handler` (gestionar el toque antes que la reacción por defecto) y `drop_filter` + `data_dropped` (aceptar objetos soltados). Sin asignarlos se comporta como antes (Home).

## Aprendizaje y diversión (separación de sistemas)
- La diversión **no** es una necesidad: se obtiene con las actividades educativas y la interacción con Chibbi.
- Los futuros mundos (Letras, Números, Figuras, Combinación, Repaso) vivirán en su propio sistema (`scenes/levels/`, `scenes/minigames/`, `scripts/gameplay/`). `NeedsManager` e `Inventory` no saben nada de ellos.
- Puntos de conexión previstos: una actividad puede llamar a `NeedsManager.change(&"energy", -x)` (cansarse un poco) y a `Inventory.add(id, n)` (recompensas). Nada más.

## Guardado
- `SaveService.register_section(nombre, getter, setter)`. Archivo `{version, saved_at, sections}`; escritura en `.tmp` + renombrado.
- Guarda: en cada cambio de escena, cada `autosave_interval` s, al cerrar la ventana y al pasar a segundo plano.
- Partida dañada o de versión nueva → se empieza de cero (aviso en el log). Secciones desconocidas se conservan; necesidades nuevas reciben su valor inicial.
- Tiempo con la app cerrada: desactivado por defecto (`offline_decay`); si se activa, máximo `offline_max_minutes` y nunca por debajo de `offline_floor`.
