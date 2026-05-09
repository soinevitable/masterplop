# AI Log — Uso de IA en el desafío
**Herramienta utilizada:** Claude (Anthropic)

Acá registro los prompts más útiles que usé. La idea fue usar la IA como sparring partner: yo planteo el problema, ella me devuelve trade-offs, edge cases o validaciones que yo no había considerado. Cero copiar y pegar a ciegas.

---

## Prompt 1: Estructura del análisis antes de meterme al SQL

Tenía la lista de indicadores que pide el desafío pero quise pensar primero en el orden lógico del análisis antes de empezar a codear. La intuición me decía que la limpieza tenía que ir antes de todo, pero quería confirmar el orden completo.

**Prompt:**
> "Tengo un desafío de analytics engineering con 6 indicadores que calcular sobre un dataset transaccional financiero. Antes de tirarme al SQL, ayúdame a pensar el orden óptimo: cuál sería la secuencia que me daría insights de manera incremental y que minimice retrabajo si encuentro problemas en la data a mitad de camino? Mi instinto dice diagnóstico, limpieza, indicadores básicos, indicadores compuestos, reto principal. Pero quiero saber si me estoy perdiendo algo."

**Resultado:** Confirmó la secuencia y me sumó una idea que sí me sirvió: dejar el reto principal (cashback) al final no solo por dificultad sino porque me sirve de stress test de la limpieza. Si los 5 indicadores básicos dan números coherentes, mi vista limpia está sólida y puedo confiar en ella para el cálculo del cashback que es el más sensible.

---

## Prompt 2: Sintaxis específica de DuckDB para fechas mixtas

Ya había detectado que las fechas venían en dos formatos. La lógica era clara (normalizar y parsear), pero DuckDB no lo manejo tanto como PostgreSQL y no quería gastar tiempo buscando documentación.

**Prompt:**
> "En DuckDB, tengo una columna de fechas con dos formatos en la misma columna: dd-mm-yyyy y dd/mm/yyyy. Cuál es la forma más limpia de parsearlos a tipo DATE en una sola expresión, sin tabla temporal? Idealmente que sea legible para alguien que tenga que mantener esto después."

**Resultado:** `STRPTIME(REPLACE(prch_date, '-', '/'), '%d/%m/%Y')::DATE`. Lo metí en la VIEW de limpieza. El código es legible y resuelve el problema en una línea.

---

## Prompt 3: Validación adversarial del query del cashback

El query del cashback era el más crítico del desafío y quería que alguien me lo cuestionara antes de darlo por bueno. La idea era simular lo que haría un revisor técnico en Artefact.

**Prompt:**
> "Asume que eres el data lead de Masterplop revisando mi query de cashback antes de subirlo a producción. Mi lógica es: filtrar transacciones elegibles, agrupar gasto por card_id, calcular 7%, aplicar LEAST(valor, 50). Pongamos que eres especialmente quisquilloso, que cosas cuestionarías? Edge cases en mente: tarjetas con una sola transacción exacta de $714.29, tarjetas con solo devoluciones, tarjetas con gasto neto cero, tarjetas con un dia de actividad."

**Resultado:** Me confirmó que la secuencia es correcta y validó que las tarjetas con solo devoluciones quedan excluidas automáticamente por mi filtro `amt > 0`, que es el comportamiento deseado. No encontró fallas estructurales en la lógica.

---

## Prompt 4: Trade-off para presentar el insight del cashback

Tenía 3 ángulos posibles para el insight principal de la campaña: el costo absoluto ($178K), el % de tarjetas en el tope (66.5%), o la tasa efectiva de cashback (2.44%). No estaba segura cuál de los 3 era más impactante para un gerente de banca.

**Prompt:**
> "Si fueras gerente de banca revisando los resultados de una campaña de cashback, qué te haría más ruido: el costo absoluto ($178K), el % de tarjetas que tocaron el tope (66.5%), o la tasa efectiva de cashback (2.44% vs 7% nominal)? No me digas los 3 son importantes. Cuál es el insight que cierra el reporte y cuáles son contexto que lo soporta."

**Resultado:** Me dijo que el insight de cierre debería ser la tasa efectiva, porque convierte el reporte en una validación financiera del diseño de la campaña (el tope funcionó). El costo absoluto y el % en el tope son los datos que te dan ese número. Reorganicé la página 2 del dashboard con esa jerarquía: KPIs operativos arriba, distribución y comparación con/sin tope al medio, y la tasa efectiva como métrica de cierre abajo.

---

## Prompt 5: Métricas derivadas que conecten datos con decisiones

Tenía los resultados base del cashback pero sentía que el análisis se quedaba corto. Quería sumar métricas que le dieran contexto financiero a las cifras crudas.

**Prompt:**
> "Tengo estos datos: $178K de costo total, 4,029 tarjetas, 66.5% en el tope, $7.3M de gasto elegible. Qué métricas derivadas puedo calcular que conecten estos datos con decisiones de negocio? Tipo: a qué umbral de gasto cambian las tarjetas de no-tope a tope, cuánto se ahorró Masterplop por el diseño del tope, etc. Quiero 3 metricas que muevan la aguja, no 10 que sean ruido."

**Resultado:** Me sugirió las 3 que terminé incluyendo: (1) tasa efectiva de cashback (2.44% vs 7% nominal), (2) gasto umbral del tope ($714 USD por tarjeta al mes), y (3) delta absoluto de costo con vs sin tope ($334K, 65% de reducción). Las 3 conectan los datos crudos con el comportamiento de los clientes y la decisión de diseño de la campaña.

---

## Prompt 6: Diseño y estructura del dashboard HTML

Decidí hacer el dashboard como HTML interactivo en lugar de Looker Studio porque me daba más control sobre la narrativa visual, y porque el desafío decía "la herramienta que prefieras". Necesitaba ayuda con la estructura técnica del archivo.

**Prompt:**
> "Necesito armar un dashboard HTML de 2 páginas para una empresa fintech. Página 1 con indicadores operativos, página 2 con el análisis de la campaña de cashback. Paleta: azul #1A56DB, amarillo #FBBF24, morado #7C3AED. Quiero navegación por tabs arriba (no scroll infinito), KPI cards prominentes, barras horizontales para los rankings, y cajas de insight destacadas para los hallazgos clave. La estética debe transmitir confianza institucional, no startup playful. Hazlo responsive. El tipo de letra debe ser Inter."

**Resultado:** Me generó la estructura base del HTML con el sistema de grillas, la navegación por tabs y los estilos CSS. Yo iteré sobre eso: ajusté la jerarquía visual de los KPIs, redacté los textos de los insights, decidí qué iba en cada gráfico, corregí el contenedor del logo para que se viera sobre el header oscuro, y arreglé la visualización de las barras de P1/P2 que quedaban muy chicas para mostrar el valor adentro.

---

## Reflexión

Usé la IA como sparring estratégico, no como motor de soluciones. Las decisiones de fondo (cómo tratar las devoluciones, por qué el tope va por tarjeta, qué KPIs cuentan la historia, qué insight cierra el análisis) fueron mías. La IA me ayudó a moverme rápido en sintaxis específica de DuckDB que no domino al 100%, a stress-test mi lógica con casos que no había pensado, y a encontrar la mejor forma de comunicar los hallazgos a una audiencia ejecutiva. El desafío me tomó alrededor de 8 horas y sin la IA habría sido el doble.
