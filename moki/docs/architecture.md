# MOKI - ARQUITECTURA DEL PROYECTO

## Escenas
- scenes/main/: escenas principales.
- scenes/home/: habitación y pantalla principal.
- scenes/characters/: escenas de personajes.
- scenes/minigames/: minijuegos.
- scenes/levels/: niveles educativos.
- scenes/ui/: interfaces de usuario.
- scenes/education/: pantallas educativas (mapa de niveles, lección, guía Moki).

## Scripts
- scripts/core/: sistemas centrales del juego.
- scripts/characters/: comportamiento de personajes.
- scripts/gameplay/: mecánicas del juego.
- scripts/progression/: progresión y desbloqueos.
- scripts/ui/: lógica de las interfaces (scripts/ui/education/: vistas y componentes educativos).
- scripts/education/: motor educativo (datos, generadores, lecciones, progreso, narración).

## Recursos (.tres)
- resources/character/: librerías de piezas de Moki (`PartLibrary`).
- resources/needs/: configuración de necesidades (`NeedsConfig`).
- resources/education/: catálogo educativo, mundos, niveles y bancos de contenido.
- resources/items/: catálogo de objetos (`ItemCatalog`) y sus definiciones (`ItemDefinition`): `food/` (alimentos) y `room/` (acciones de objetos de la habitación).

## Autoloads (en este orden)
| Nombre | Script | Responsabilidad |
|---|---|---|
| `SceneManager` | scripts/core/scene_manager.gd | Cambio de escena con fundido; señal `scene_changed(path)`. |
| `SaveService` | scripts/core/save_service.gd | Guardado genérico por secciones en `user://moki_save.json`. |
| `NeedsManager` | scripts/progression/needs_manager.gd | Valores, paso del tiempo, estados y descanso de las necesidades. |
| `Inventory` | scripts/progression/inventory.gd | Cantidades de objetos, validación y uso (aplica efectos en `NeedsManager`). |
| `EducationProgress` | scripts/education/education_progress.gd | Progreso educativo: desbloqueos, historial, desempeño (sección `education`). |
| `Narrator` | scripts/education/narrator.gd | Voz de Moki: audio grabado (futuro) → voz del sistema (TTS) → solo texto. **Desactivada temporalmente** (`enabled = false`): las frases se cortaban entre sí. |

`SaveService` depende de `SceneManager` (guarda en cada cambio de escena); `NeedsManager` e `Inventory` registran su sección en `SaveService`, e `Inventory` usa `NeedsManager`. Por eso el orden importa.

## Navegación
`Main` → `Home` → (`Jugar`) `WorldMap` → `LevelMap` → `LessonScreen` / (`Mi habitación`) `MokiRoom`.
Las rutas están en `ScenePaths`. `BigButton.target_scene` navega mediante `SceneManager`.
`SceneManager.change_scene(path, params)` acepta parámetros opcionales (p. ej. `{"level_id": &"letters_a"}`) que la escena nueva lee con `SceneManager.get_params()`.

## Moki (personaje cutout híbrido)
- `scenes/characters/moki.tscn` (`Moki`, scripts/characters/moki.gd). Origen = suelo entre los pies.
- Piezas: `CharacterPart` (Sprite2D) lee textura y pivote de una `PartLibrary` (diccionario de `PartVariant`). Cambiar de variante no desplaza la pieza; `variant` se puede animar con pistas discretas.
- Dos modos:
  - **Pose completa** (actual): `body_*` de la vista + cabeza de expresión superpuesta exactamente sobre la cabeza integrada.
  - **Rig** (Skeleton2D/Bone2D: Hip → Tail, LegL/R, Torso → ArmL/R, Head): se activa solo cuando `moki_torsos.tres` tenga torso para la vista. Las librerías de torso y cola existen vacías a propósito.
- Animaciones (`AnimationPlayer`): RESET, idle, bounce, wave, surprised, tilt. Todas fijan la pose completa en su primer fotograma. El nodo `Body` se mueve en ambos modos; los huesos solo se ven en modo rig.
- Expresiones (`Moki.Mood`): NEUTRAL, HAPPY, LAUGHING, SURPRISED, ANGRY. Solo cambian la textura de la cabeza: son independientes de la animación. `rest_expression` = cara a la que vuelve tras reaccionar.
- `MokiStage` (Control): coloca y escala a Moki dentro de la UI y convierte toques en `react_to_tap()`. Solo su zona táctil cuenta como "punto" del control, para no tapar objetos detrás.

## Habitación de Moki
- `scenes/characters/moki_room.tscn` (`MokiRoom`, scripts/gameplay/moki_room.gd).
- Lienzo de diseño `Room` de 1280×720 centrado en pantalla; el fondo se estira en horizontal (es uniforme) y se prolonga con los colores de pared y suelo para otras proporciones. La `UI` se ancla a la pantalla, no al lienzo.
- Orden de dibujo: Background → Wall → FurnitureBack → MokiStage → FurnitureFront → Bins → Books → Props → Toys → UI.
- Objetos: `RoomItem` (scripts/gameplay/room_item.gd, TextureRect). Tamaño = PNG × `art_scale`; solo responde a toques en píxeles opacos; categoría (`DECOR`, `FURNITURE`, `TOY`, `BOOK`, `BIN`, `PROP`); emite `selected(item)`; acción opcional `item: ItemDefinition`.
- **Decoración vs interactivos**: pared, cuadros, banderines, ventana, alfombra, estante, mueble bajo, mesa y silla tienen `interactive = false` (no responden). Juguetes, libros, cajas y objetos de la mesa son interactivos. El osito tiene la acción de descanso (`resources/items/room/teddy_rest.tres`).
- `MokiRoom` reenvía `item_selected(item)` y muestra el nombre en el rótulo. Si el objeto tiene acción la gestiona `MokiCare`; si no, Moki reacciona según la categoría.
- Barra superior (`UI/TopBar`): Volver · botón de descanso · barra de inventario · HUD de necesidades.

## Necesidades
- **Solo dos**: Hambre (`hunger`) y Energía (`energy`).
- Datos: `NeedDefinition` (id, nombre, color, icono, valor inicial, bajada por minuto, cambio por minuto al descansar, umbrales 70/40/15 e histéresis) y `NeedsConfig` (lista + tiempo, mínimo, app cerrada, descanso, autoguardado) en `resources/needs/moki_needs.tres`.
- **Convención: 100 = necesidad satisfecha** (el hambre es "saciedad").
- Estados: `NeedDefinition.State` = GOOD, MEDIUM, LOW, CRITICAL. Bajar de estado es inmediato; subir exige superar el umbral + histéresis.
- `NeedsManager`: acumula `delta × time_scale` (máx. 5 s por fotograma) y aplica la bajada cada `tick_interval`. Señales `need_changed`, `need_state_changed`, `overall_state_changed` (peor estado), `needs_loaded`. API: `get_value`, `get_state`, `get_overall_state`, `get_lowest_need`, `change(id, cantidad)` (entrada para futuras acciones), `set_paused`, `reset`.
- **Descanso**: `NeedsManager.set_resting()`. Mientras descansa, cada necesidad usa `resting_rate_per_minute` (energía +8/min, hambre −0,5/min). Se despierta solo con la energía llena (`wake_when_rested`). Nunca es obligatorio.
- Principios: sin castigos, sin muerte, sin presión. Los valores nunca bajan de `min_value`; Moki nunca usa expresiones negativas por necesidades; con la app cerrada nada baja (y si se dejó descansando, la energía se recupera, máx. `offline_rest_max_minutes`).
- **Puente con Moki**: `MokiNeedsLink` (scripts/characters/moki_needs_link.gd) en Home y en la habitación. Peor estado → `rest_expression` (bien: HAPPY; resto: NEUTRAL). Solo en estado crítico (y nunca descansando) Moki pide atención con calma cada 30 s (`attention_requested(need_id)`). Al descansar: cara tranquila y animación a 0,4×; al despertar, `bounce`. Moki no depende de las necesidades.
- **Interfaz**: `NeedsHud` (scenes/ui/needs_hud.tscn) crea un `NeedMeter` por necesidad configurada (insignia + barra de color por estado, pulso solo en crítico, sin números). Tocar un medidor muestra su nombre en el rótulo de la habitación.

## Objetos, inventario y alimentación
- **`ItemDefinition`** (scripts/gameplay/items/item_definition.gd): id, nombre, tipo (`FOOD`, `REST`, `TOY`, `OTHER`), icono (o icono provisional `placeholder`), acción (`FEED`, `REST`, `NONE`), destino (`MOKI`, `ROOM`), efectos `{necesidad: puntos}`, `refuse_when_not_needed`, `show_in_inventory`, `consumable`, `unlimited`, cantidades inicial/máxima, reacción y expresión de Moki y mensaje.
- **`ItemCatalog`** (`resources/items/item_catalog.tres`): lista de objetos. **Añadir un objeto = crear su `.tres` y añadirlo al catálogo**; el inventario y la barra lo muestran solos.
- **`Inventory`** (autoload): `get_quantity` (−1 = ilimitado), `can_use(id, destino)` → `UseResult` (`OK`, `UNKNOWN_ITEM`, `NOT_AVAILABLE`, `WRONG_TARGET`, `NOT_NEEDED`), `use(id, destino)` (aplica efectos con `NeedsManager.change()` y gasta una unidad), `add(id, n)` (futuras recompensas). Señales `quantity_changed`, `item_used`, `use_refused`. Sección de guardado `inventory`.
- **UI**: `InventoryBar` (scenes/ui/inventory_bar.tscn) crea un `InventorySlot` por objeto del inventario (filtrable por tipo; en la habitación, comida). Casilla: toque = seleccionar; arrastre = soltar sobre Moki; contador solo si no es ilimitado. `ItemIcon` dibuja el icono del objeto o uno provisional vectorial.
- **`MokiCare`** (scripts/gameplay/moki_care.gd, nodo de la habitación): alimentar (arrastrar el alimento hasta Moki, o tocar alimento + tocar a Moki), validar con `Inventory`, animar la comida hacia la boca, reacción de Moki y mensaje. Si está lleno, lo dice con calma y no se gasta nada. Descansar con el botón (luna/sol) o con el osito; tocar a Moki o darle comida lo despierta. Habitación oscurecida y "Z z z" mientras descansa.
- `MokiStage` ofrece `tap_handler` (gestionar el toque antes que la reacción por defecto) y `drop_filter` + `data_dropped` (aceptar objetos soltados). Sin asignarlos se comporta como antes (Home).

## Aprendizaje y diversión (separación de sistemas)
- La diversión **no** es una necesidad: se obtiene con las actividades educativas y la interacción con Moki.
- Los futuros mundos (Letras, Números, Figuras, Combinación, Repaso) vivirán en su propio sistema (`scenes/levels/`, `scenes/minigames/`, `scripts/gameplay/`). `NeedsManager` e `Inventory` no saben nada de ellos.
- Puntos de conexión previstos: una actividad puede llamar a `NeedsManager.change(&"energy", -x)` (cansarse un poco) y a `Inventory.add(id, n)` (recompensas). Nada más.

## Guardado
- `SaveService.register_section(nombre, getter, setter)`. Archivo `{version, saved_at, sections}`; escritura en `.tmp` + renombrado.
- Guarda: en cada cambio de escena, cada `autosave_interval` s, al cerrar la ventana y al pasar a segundo plano.
- Partida dañada o de versión nueva → se empieza de cero (aviso en el log). Secciones desconocidas se conservan; necesidades nuevas reciben su valor inicial.
- Tiempo con la app cerrada: desactivado por defecto (`offline_decay`); si se activa, máximo `offline_max_minutes` y nunca por debajo de `offline_floor`.

## Sistema educativo
Independiente del cuidado de Moki: nada en `scripts/education/` usa `NeedsManager` ni `Inventory` (se comprueba en las pruebas).

### Datos (Resources editables)
- `EducationCatalog` → `WorldDefinition` (orden, desbloqueo, niveles, niveles "próximamente") → `LevelDefinition`.
- **Nivel ≠ lección.** `LevelDefinition` = objetivo permanente: conceptos, introducción y cierre (`DialogueLine`), plantillas, banco de contenido, tamaño de lección (5–8) y niveles que desbloquea. Cada vez que se juega se **genera** una lección distinta.
- `ActivityTemplate`: una dinámica (id, vista `CHOICE`/`SEARCH`/`SORT`, etapa `RECOGNIZE`/`DISCRIMINATE`/`ASSOCIATE`/`CONTEXT`/`REINFORCE`, rango de dificultad 1–5, instrucción y 4 pistas) + un `ActivityGenerator`.
- `ActivityGenerator` (subclases `LetterChoiceGenerator`, `LetterSearchGenerator`, `WordImageGenerator`, con modos) → `ActivityInstance` concreta (tarjetas `CardData`, respuestas, tarjeta de enunciado, tarjeta modelo para la pista visual, distractores retirables y **firma de contenido**). Siempre usan el RNG de la lección.
- `ContentBank`: letra objetivo, distractores por dificultad (fáciles/medios/parecidos), minúsculas, palabras con imagen (`WordEntry`, imágenes reales del juego), palabras para deletrear, tipografías del sistema y colores. Otro nivel = otro banco.
- `DialogueLine`: texto, texto hablado, tipo (instrucción, explicación, consejo, pista, acertijo, felicitación, ánimo), expresión y `voice_key` (audio grabado futuro).

### Motor
- `LessonBuilder` → `LessonPlan` (huecos plantilla + dificultad). Dificultad base según el dominio del concepto, **±1 como máximo** respecto a la lección anterior. Estructura por etapas (reconocer → distinguir → asociar → contexto → extras en las etapas más débiles → reforzar). Puntúa candidatas (penaliza repetir en la lección, en la anterior y recientes; premia etapas débiles) con azar ponderado y **búsqueda con vuelta atrás** para no repetir plantilla ni vista seguidas. Si sale igual que la anterior, la rehace.
- `LessonSession` (sin interfaz, solo señales): genera cada actividad al empezarla con la dificultad adaptada y evitando firmas recientes; evalúa respuestas (CHOICE una, SEARCH todas, SORT por cesta); ayuda progresiva; refuerzos; resultado por actividad.
- `AdaptiveDifficulty`: 2 aciertos seguidos al primer intento → +1 (máx. +1); muchas pistas/errores o salto → −1 (mín. −2) e inserción de un refuerzo (otra plantilla, otra vista si es posible).
- `HintLadder`: reformular → pista verbal → acertijo/comparación → pista visual (tarjeta modelo + se retiran distractores, siempre quedan ≥ 2 opciones). Tras 2 errores más, salto suave a otra actividad. Nunca revela la respuesta ni su posición (validado en pruebas).
- `EducationProgress`: mundos/niveles desbloqueados, veces completado, últimas 10 lecciones por nivel, últimas 40 firmas, desempeño por concepto y etapa (media móvil: no se domina con una respuesta), pistas, saltos y última dificultad. Guarda en cada actividad y al terminar.

### Interfaz
- `MokiGuide` (scenes/education/moki_guide.tscn): rostro de Moki (cabezas existentes vía `moki_heads.tres`, nunca enfadado) + bocadillo con cola (`BubbleTail`) hacia él; color según el tipo de frase; botones **?** (ayuda) y **Oír** (repetir voz; oculto si no hay voz). API: `say`, `say_text`, `set_expression`, `show_model`, `clear_model`, `replay`, `show_guide`, `hide_guide`.
- `ActivityView` (base) → `ChoiceView`, `SearchView`, `SortView` (+ `SortBin`), con `ActivityCard`. Para otro tipo de actividad: nueva subclase registrada en `ActivityView.create()`.
- `LessonScreen`: introducción (auto o botón "Seguir") → actividades → celebración ("Otra vez" / "Mapa"). `LevelMap` y `WorldMap` se generan desde el catálogo.
- Entrada: `_gui_input` con clic; los toques se emulan como clic (`emulate_mouse_from_touch`). En SORT: tocar tarjeta + tocar cesta, o arrastrar.

### Añadir contenido
- Nivel nuevo de letras: un `ContentBank` + un `LevelDefinition` con las mismas plantillas (o variantes) y añadirlo al `WorldDefinition`.
- Otro tipo de conocimiento (números, figuras, cantidades, memoria…): nuevos generadores (y, si hace falta, nuevas vistas) reutilizando `LessonBuilder`, `LessonSession`, `HintLadder`, `MokiGuide` y `EducationProgress`.
