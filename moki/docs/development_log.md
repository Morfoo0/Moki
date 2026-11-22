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

## Fase 2: Moki y experiencia principal
- [x] Personaje Moki.
- [x] Sistema de animaciones.
- [x] Interacciones con la mascota.
- [x] Habitación de Moki.
- [x] Sistema de necesidades (base: tiempo, estados, guardado e interfaz).
- [x] Sistema de cuidado: hambre y energía, descanso, inventario y alimentación.

### Notas — Moki (2026-11-20)
- Montaje cutout híbrido: modo "pose completa" activo y rig Skeleton2D/Bone2D preparado.
- Pivotes medidos por silueta y template matching y comprobados con renders: las cabezas de expresión coinciden píxel a píxel con las cabezas integradas en `body_*`.
- Animaciones RESET, idle, bounce, wave, surprised, tilt. Expresiones independientes de la animación.
- Integrado en Home con `MokiStage` (toque → reacción aleatoria, sin interrumpir la reacción en curso).
- **Arte pendiente**: `torso_front` y `tail_front` (y otras vistas) para activar el rig; cabeza con ojos cerrados (parpadeo/sueño); caras triste, cansada y comiendo; brazos sin mano para usar `hands/`.

### Notas — Habitación (2026-11-20)
- `moki_room.tscn` con los recursos de `assets/characters/room/`. Acceso desde Home con el botón "Mi habitación".
- Las cajas `bin_shelf_*` y `bin_cabinet_*` encajan exactamente en los huecos del estante y del mueble bajo (escala común 0,62).
- Objetos seleccionables (`RoomItem`) por categoría; tocar muestra su nombre y Moki reacciona.
- **Recursos dañados, no usados**: `chair_blue.png`, `chair_orange.png` y `table_green_round.png` (partes borradas y fragmentos sueltos al quitar el fondo).
- Probado en 1280×720, 1600×720, 1280×960, 1920×1080 y 1024×768.

### Notas — Necesidades (2026-11-20)
- Primera versión con cuatro necesidades; corregida en el sistema de cuidado (ver abajo).
- Estados bien/medio/bajo/crítico con histéresis. Sin castigos ni muerte.
- Guardado en `user://moki_save.json` (cambio de escena, cada 30 s, al cerrar, segundo plano).
- HUD en la habitación con un medidor por necesidad, generado desde la configuración.

### Notas — Sistema de cuidado, inventario y alimentación (2026-11-20)
- **Solo dos necesidades: Hambre y Energía.** Higiene y Diversión eliminadas (eran solo datos en `moki_needs.tres`; sin restos en código, HUD ni guardado). Las partidas antiguas con cuatro necesidades se migran solas.
- La diversión no es una barra: vendrá de las actividades educativas, que serán un sistema independiente.
- Bajadas: hambre 2/min, energía 1,2/min. **Descanso**: energía +8/min, hambre −0,5/min; se despierta solo con la energía llena. Si se cierra la app con Moki descansando, al volver la energía se ha recuperado (máx. 8 h); el hambre nunca baja con la app cerrada.
- Menos presión: Moki solo pide atención en estado crítico (cada 30 s) y nunca descansando; solo el estado crítico pulsa en el HUD.
- Objetos como datos (`ItemDefinition`/`ItemCatalog`), autoload `Inventory`, barra de inventario y `MokiCare`.
- Alimentos: Manzana (+20, ilimitada), Plátano (+25, ilimitado), Galleta (+10, 5 unidades). Los básicos son ilimitados para que Moki siempre pueda comer.
- Alimentar: arrastrar hasta Moki o tocar alimento + tocar a Moki. Lleno: "¡Estoy lleno!" y no se gasta.
- Descanso: botón luna/sol o tocar el osito. Habitación oscurecida y "Z z z".
- La decoración de la habitación ya no responde (pared, cuadros, alfombra, muebles, mesa, silla).
- **Iconos provisionales** dibujados por código (manzana, plátano, galleta, luna, sol) en `ItemIcon`: se sustituyen asignando `icon` en cada `.tres`.
- **Arte pendiente**: iconos de alimentos, de descanso y de las necesidades (ahora iniciales H/E); cara de Moki comiendo y durmiendo (ojos cerrados); opcional: cama o cojín.
- Pruebas: 58 comprobaciones de integración en headless (necesidades, descanso, app cerrada, migración, inventario, alimentación, habitación, navegación). El gesto de arrastrar se verificó hasta el inicio del arrastre y el soltar con la API de soltar de Godot (en headless el motor no ejecuta esa fase con input simulado): **comprobar a mano con F5**.

### Nota sobre pruebas automáticas
- Las pruebas con ventana se abren en el segundo monitor (Windows no permite colocarlas fuera de pantalla) y pueden recibir clics reales. Las pruebas lógicas se ejecutan en headless y los renders con `gui_disable_input`.

## Fase 3: Sistema educativo
- [x] Motor de niveles y lecciones dinámicas (base).
- [x] Actividades (prototipo: Mundo Letras · Nivel 1, letra A).
- [x] Progresión por niveles y progreso persistente.
- [x] Mundo Letras completo: vocales A, E, I, O, U.
- [x] Mundo Números completo: del 1 al 10 en cinco lecciones.
- [x] Mundo Figuras completo: círculo, cuadrado, triángulo, rectángulo y óvalo.
- [x] Mundo Combinación completo: cinco lecciones integradoras.
- [ ] Mundo Repaso.

### Notas — Sistema educativo (2026-11-20)
- Nivel = objetivo permanente; lección = sesión generada de 5–8 actividades, distinta cada vez (historial, firmas de contenido, puntuación ponderada, sin repetir plantilla ni vista seguidas).
- Nivel 1 (letra A): 9 dinámicas con 3 vistas reutilizables: toca la A, busca todas las A, ¿cuál no es A?, la A disfrazada (minúscula "a" en dificultad alta), ¿qué dibujo empieza con A?, ¿con qué letra empieza?, las A de la palabra, cesta de la A (clasificar) y la A escondida.
- Imágenes de palabras: recursos reales de la habitación (A: aros, alfombra, ábaco, arcoíris; sin A: oso, casa, castillo, libros, ventana, estrella, flor, silla, mesa, lápices, cubo, caja). Tipografías del sistema para variar la forma de las letras.
- Moki guía: rostro + bocadillo con cola; introducción (qué, cómo, ejemplo cotidiano); ayuda progresiva en 4 pasos sin revelar la respuesta; salto suave tras agotar la ayuda; felicitaciones que reconocen el esfuerzo. Sin vidas, puntos, tiempo ni competencia.
- Voz: voz del sistema (TTS) en español (en este equipo, Sabina es-MX); preparado para audios grabados por `voice_key`.
- **Ritmo del niño:** nada avanza por tiempo. Cada frase de la introducción y cada felicitación esperan a que el niño pulse "Seguir ▶" (más grande y con un pulso suave; aparece tras 0,6 s para evitar saltos por doble toque y se oculta durante la actividad).
- **Voz desactivada temporalmente** (`Narrator.enabled = false`): cada mensaje nuevo cortaba el audio del anterior. El botón "Oír" se oculta solo. Pendiente: que Moki termine cada frase antes de la siguiente (cola de frases) y reactivar la voz.
- Adaptación: dificultad base por dominio (±1 entre lecciones), ±1 dentro de la lección, refuerzos al tener dificultades.
- Progreso persistente en la sección `education` del guardado.
- `SceneManager.change_scene(path, params)` acepta parámetros opcionales (compatible con todo lo anterior).
- **Arte recomendado**: más imágenes de palabras con A (avión, abeja, árbol, araña, anillo); la "alfombra" actual (vista desde arriba) se reconoce con dificultad. Iconos para los botones de ayuda y escuchar.
- **Limitación conocida**: con solo 3 vistas, los refuerzos para un niño con dificultades suelen ser la cesta de clasificar (es la única vista distinta disponible); mejorará al añadir más tipos de actividad.
- Pruebas: motor (23 comprobaciones: 2.700 instancias generadas válidas, ayuda progresiva, 20 lecciones con niño que acierta y 12 con niño con dificultades, separación de sistemas), interfaz (34: navegación, guía, introducción, lección completa con ratón y dedo, pistas, salto suave, final, repetición distinta, registro), persistencia entre dos procesos, y regresión del cuidado (58).

### Notas — Mundo Letras completo: E, I, O, U (2026-11-21)
- Cuatro niveles nuevos con datos (banco + nivel por vocal) sobre el mismo motor; la A no cambia salvo `unlocks = [letters_e]` (antes no desbloqueaba nada).
- Guía: Moki (Chibbi era el nombre antiguo del personaje). Mismo `MokiGuide`, mismas pistas progresivas y salto suave.
- 12 dinámicas por vocal: las 9 de la A con textos propios de cada vocal + 3 nuevas (¿qué vocal suena así?, grande y pequeñita, todas grandes y pequeñitas). Cada etapa tiene al menos 2 dinámicas, así que la primera y la última actividad también varían (en la A siempre son "toca la A" y la cesta).
- Refuerzo del concepto tras cada acierto (`reinforce_lines`) y cierres que invitan a la siguiente vocal.
- Desbloqueo retroactivo al cargar: las partidas con la A ya completada abren la E.
- **Dibujos provisionales con emoji** (decisión del usuario): solo había estrella (E) y oso (O) en la habitación. Se comprobó el render en color en Windows; dependen de la fuente de emoji del sistema. Descartados: `1️⃣` para "uno" (se veía una caja vacía) y el estante (no se reconoce).
- Corregido: la cesta de clasificar mostraba vacíos los dibujos emoji (solo pintaba texturas) y la tarjeta de sonido se salía del recuadro.
- **Voz**: sigue desactivada (decisión del usuario: se buscará una voz no robótica). La actividad de sonido se apoya en el texto («eee») y en describir la boca; cada frase lleva ya su texto hablado (`spoken`) para cuando haya voz.
- **Arte pendiente (prioridad)**: PNG para sustituir los emoji, sobre todo U (solo uvas y unicornio: faltan uña, uniforme, uno) e iguana (se parece a una lagartija). El resto: elefante, escoba, erizo, espejo, isla, imán, iglesia, oveja, ojo, oruga, ola, oreja.
- **Limitación conocida del constructor de lecciones** (afecta también a la A; no se cambió para no alterar la A): en ~55 % de las lecciones una plantilla aparece dos veces (con contenido distinto), porque los huecos extra solo eligen entre las 2 etapas más débiles y la regla de no repetir vista. Propuesta: en `LessonBuilder._ordered_candidates`, descartar plantillas ya usadas en la lección cuando haya alternativas válidas.
- Pruebas (scripts fuera del proyecto; partida del usuario copiada y restaurada): motor (755.380 comprobaciones, 34.200 actividades generadas en las 5 vocales: respuestas válidas, pistas rellenas, la pista visual nunca retira la respuesta, dibujos "con/sin" vocal correctos, sin "l" junto a "I", 25 lecciones por vocal sin plantilla ni vista seguidas y sin lecciones consecutivas idénticas, sesiones de niño que acierta y con dificultades); progreso (37: cadena de desbloqueo, rejugar, migración de partida antigua, persistencia entre dos procesos); interfaz (112: mapa con 5 lecciones y estados, lecciones completas de A, E, I, O, U alternando ratón y toque, ayuda, cesta, final); arranque de la escena principal sin errores en consola.

### Notas — Mundo Números (2026-11-21)
- Cinco lecciones (1-2, 3-4, 5-6, 7-8, 9-10) sobre el mismo motor. Lo nuevo es: un banco (`NumberBank`), dos generadores, dos tipos de tarjeta (numeral y grupo de objetos) y tres opciones de `ActivityInstance` (tocar N, tocar en orden, Moki cuenta).
- **Números se abre al terminar Letras** (decisión del usuario): mecanismo nuevo `WorldDefinition.unlocked_after_level`, también retroactivo para partidas con la U ya completada.
- 12 dinámicas compartidas: reconocer, distinguir, contar, número ↔ cantidad, tocar contando, comparar, número escondido, secuencias, ordenar y clasificar. Repaso acumulativo de los números anteriores en cada lección.
- Ajustes tras medir 200 lecciones por nivel:
  - "¿Qué número falta?" nunca salía (la posición de contexto siempre exigía una vista SEARCH). Se movió "toca y cuenta" a la etapa ASSOCIATE.
  - "¿Dónde hay más?" salía en ~10 % de las lecciones; en ASSOCIATE sale en ~50 %.
  - Las lecciones 4 y 5 no tenían una segunda actividad de refuerzo con otra vista: la cesta repasa allí números de 6 o menos.
- Corregido: el hueco de la secuencia (`_`) se veía poco; ahora es `?`.
- **Pendiente / limitaciones**:
  - Emoji provisionales para los objetos (verificados en color en Windows).
  - En la lección 1 la variedad de contenido es la menor posible (solo 1 y 2: "ordena 1 y 2" es siempre igual).
  - Igual que en Letras, el `LessonBuilder` compartido repite a veces una plantilla dentro de la lección (con contenido distinto). "El número escondido" sale en casi todas las lecciones por la alternancia de vistas.
  - Voz desactivada: "Moki cuenta" se ve en el bocadillo ("¡Uno!", "¡Dos!"…).
- Pruebas (scripts fuera del proyecto; partida del usuario copiada y restaurada):
  - Motor: 665.245 comprobaciones. Grupos con la cantidad exacta y dentro del máximo, comparaciones sin empates, secuencias consecutivas, orden creciente, respuestas únicas, pistas rellenas, la pista visual nunca retira la respuesta, repaso presente, 200 lecciones por nivel sin plantilla ni vista seguidas ni lecciones idénticas consecutivas, y sesiones de niño que acierta y con dificultades.
  - Disposiciones: 18.000 colocaciones sin solaparse.
  - Progreso: 44 comprobaciones (bloqueo hasta la U, cadena 1→5, rejugar, desempeño/pistas/historial, migración, persistencia entre dos procesos).
  - Interfaz: 193 comprobaciones (mapa de mundos bloqueado/abierto, mapa de Números, las 5 lecciones con ratón y toque, rejugar, y una lección forzada con tocar-y-contar, secuencia, orden, comparar y cesta).
  - Regresión de Letras: motor 755.380, interfaz 112 y progreso 37, sin cambios.
  - Arranque sin errores en consola.

### Notas — Mundo Figuras (2026-11-21)
- Cinco lecciones acumulativas sobre el mismo motor. Lo nuevo es:
  - geometría exacta dibujada por código, sin arte nuevo;
  - un banco (`ShapeBank`), dos generadores y 8 dibujos compuestos;
  - una cuarta vista (`SCENE`: encontrar figuras dentro de un dibujo).
- **Figuras se abre al terminar Números.**
- 12 dinámicas compartidas:
  - reconocer y emparejar sin fijarse en el color;
  - buscar entre figuras variadas y la diferente;
  - figuras parecidas (cuadrado ↔ rectángulo, círculo ↔ óvalo);
  - figura ↔ objeto en los dos sentidos, y tocar todas las cosas de una forma;
  - figuras en dibujos y contar esquinas o lados;
  - clasificar objetos y figuras en 2 o 3 cestas.
- **Objetos revisados con capturas.** Se descartaron waffle 🧇 (se ve como un rombo), dado 🎲 y cubo de hielo 🧊 (cubos en 3D, no cuadrados), queso 🧀 y limón 🍋 (formas irregulares). Se añadieron dibujos de la habitación que sí tienen su forma: ventana y caja (cuadrado), banderines (triángulo), cuadro (rectángulo) y alfombra (óvalo).
- **Archivos sin usar** que se crearon durante este desarrollo y ya no se referencian: `resources/education/content/shape_objects/{waffle,die,ice,cheese,lemon}.tres`. No se han borrado (CLAUDE.md: no eliminar archivos sin autorización); se pueden borrar.
- Corregido en el dibujo del tren: la chimenea flotaba separada de la locomotora.
- **Pendiente / limitaciones**:
  - Emoji provisionales para algunos objetos.
  - Por la alternancia de vistas del `LessonBuilder`, "figuras parecidas" sale en ~24 % de las lecciones y "cuenta las esquinas" en ~21 %. La comparación cuadrado ↔ rectángulo también aparece en "toca", "busca todos" y "¿cuál es diferente?" con dificultad alta, porque allí la figura parecida es el primer distractor.
  - "Figuras escondidas" sale en casi todas las lecciones.
  - Voz desactivada.
- Pruebas (scripts fuera del proyecto; partida del usuario copiada y restaurada):
  - Motor: 8.349.167 comprobaciones.
    - Geometría: radio constante, lados opuestos iguales, ángulos rectos, cuadrado 1:1 y poco girado, proporciones del rectángulo y del óvalo, triángulos no aplastados, y todo dentro de su espacio, también en los 8 dibujos.
    - Respuestas: una por forma, objeto ↔ forma, esquinas correctas, cestas correctas, partes del dibujo = figura pedida.
    - Pistas rellenas y la pista visual nunca retira la respuesta.
    - Repaso presente.
    - 200 lecciones por nivel sin plantilla ni vista seguidas ni lecciones idénticas.
    - Sesiones de niño que acierta y con dificultades.
  - Progreso: 39 comprobaciones (bloqueo hasta Números, cadena 1→5, rejugar, pistas, historial, migración, persistencia entre dos procesos).
  - Interfaz: 164 comprobaciones.
    - Toques en partes superpuestas (gana la de encima; fuera de la figura no cuenta).
    - Mapa de mundos y de Figuras.
    - Las cinco lecciones con ratón y toque, y una lección forzada con parecidas, dibujo, esquinas, objetos y cestas.
  - Regresión: Letras (motor 755.380, interfaz 112, progreso 37) y Números (motor 665.245, interfaz 192, progreso 44), sin cambios.
  - Arranque sin errores en consola.

### Notas — Mundo Combinación (2026-11-21)
- Cinco lecciones que usan lo enseñado en los tres mundos, sin contenido ni arte nuevos (dibujos de las vocales, objetos de Números, figuras por código y los 8 dibujos de Figuras).
- **Se abre al terminar Figuras.** La lección 5 se llama "El gran desafío de Moki" (Chibbi es el nombre antiguo).
- **Pieza clave**: `ContentBank.resolve_for()` + `CombinationBank`. Cada actividad recibe el banco que entiende su generador, así que las 12 plantillas de Números y varias de Figuras se reutilizan tal cual. Lo nuevo es un generador (18 modos), la tarjeta `COLLECTION` y 19 plantillas.
- Corregido durante el desarrollo:
  - Los bancos de apoyo tenían el mismo nombre que los bancos de las lecciones 2 y 3; ahora son `combo_support_*`.
  - Las figuras dentro de los conjuntos eran demasiado pequeñas para contarlas: ahora ocupan al menos el 80 % de su celda, y las comparaciones van siempre en filas.
- **Pendiente / limitaciones**:
  - Igual que en los otros mundos, por la alternancia de vistas algunas plantillas salen menos ("toca los dibujos que empiezan con…" ~20 %; en el gran desafío, "secuencias" y "esquinas" ~15 %).
  - Emoji provisionales.
  - Voz desactivada.
  - Siguen sin borrar 5 archivos sin usar de Figuras (`shape_objects/{waffle,die,ice,cheese,lemon}.tres`), a la espera de autorización.
- Pruebas (scripts fuera del proyecto; partida del usuario copiada y restaurada):
  - Motor: 512.791 comprobaciones.
    - Cada plantilla recibe el banco correcto.
    - Respuesta única.
    - Conteos correctos (figuras pedidas en conjuntos y en dibujos, dibujos por vocal inicial) entre 1 y 10.
    - Comparaciones sin empate y una sola figura válida al preguntar por esquinas.
    - Cestas correctas, sin I ni 1 al clasificar letras y números.
    - Pistas rellenas y la pista visual nunca retira la respuesta.
    - Las lecciones 4 y 5 usan los tres mundos.
    - 200 lecciones por nivel sin plantilla ni vista seguidas y todas las plantillas aparecen.
    - Sesiones de niño que acierta y con dificultades.
  - Progreso: 61 comprobaciones (bloqueo hasta Figuras, cadena 1→5, rejugar, el progreso de otros mundos no cambia, migración, persistencia entre dos procesos).
  - Interfaz: 162 comprobaciones (mapa de mundos y de Combinación, las cinco lecciones con ratón y toque, y una lección forzada con las 8 dinámicas combinadas).
  - Regresión sin cambios:
    - Letras: motor 755.380, interfaz 112, progreso 37.
    - Números: 665.245, 194, 44.
    - Figuras: 8.349.167, 164, 39.
  - Arranque sin errores.

## Fase 4: Integración y pulido
- [ ] Dificultad adaptativa.
- [ ] Sistema de guardado.
- [ ] Pruebas finales.