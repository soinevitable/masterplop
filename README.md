# Desafío Analytics Engineer — Masterplop

**Laura Inés Martínez Suárez**  
Mayo 2026

\---

## Estructura del repositorio

```
masterplop\_challenge/
├── sql/
│   ├── 00\_setup\_y\_carga.sql
│   ├── 01\_diagnostico\_datos.sql
│   ├── 02\_limpieza.sql
│   ├── 03\_indicador\_volumen.sql
│   ├── 04\_indicador\_ticket\_trimestral.sql
│   ├── 05\_indicador\_ticket\_regional.sql
│   ├── 06\_indicador\_top\_comercios.sql
│   ├── 07\_indicador\_adopcion\_contactless.sql
│   └── 08\_reto\_cashback.sql
├── dashboard/
│   └── masterplop\_dashboard.html
├── ai\_log.md
└── README.md
```

**Stack:** DuckDB (motor SQL) + DBeaver Community Edition (interfaz visual) + HTML/CSS/JS para el dashboard.

\---

## 1\. Diagnóstico de calidad de datos

Antes de calcular cualquier indicador hice un diagnóstico de calidad sobre las 2,400,000 transacciones. Encontré 5 problemas que, sin corregirlos, dan resultados incorrectos:

**a) product\_type fragmentado en 6 variantes.** El campo tiene versiones en inglés, español sin tilde y español con tilde para cada categoría (Credit/Credito/Crédito y Debit/Debito/Débito). Sin normalizar, los conteos por tipo de producto quedan partidos en 3 y un filtro de "solo crédito" pierde dos tercios de los registros.

**b) Países duplicados por idioma o tildes.** Brazil/Brasil, Mexico/México, Peru/Perú, Panama/Panamá, Republica Dominicana/República Dominicana. Esto afecta el ranking de contactless por país y la integridad del filtro por país en general. Por suerte Chile no tiene variante con tilde, pero igual era necesario unificar el resto.

**c) Formato de fecha inconsistente.** Algunas fechas vienen con guiones (01-01-2024) y otras con barras (31/05/2024). Si las dejo como string sin parsear, los filtros por mes y trimestre fallan en silencio.

**d) MCG ID huérfano.** La tabla mcg\_list tiene IDs del 1 al 25, pero en la data hay transacciones con mcg\_id = 35 que no tiene nombre en la tabla maestra. Usé LEFT JOIN + COALESCE para no perder esas transacciones y agruparlas como "Sin categoría".

**e) Montos negativos.** El campo amt tiene un mínimo de -5,126.20 USD. Son devoluciones o chargebacks. Esto impacta especialmente el cálculo del cashback (lo explico en la sección 3).

**Solución:** Creé una VIEW llamada `transac` que normaliza product\_type a 2 categorías (Crédito/Débito), unifica los países a su versión sin tildes, y parsea las fechas a tipo DATE. Todos los indicadores se calculan sobre esta vista limpia.

\---

## 2\. Indicadores clave: resultados y decisiones

### Volumen (tarjetas únicas por trimestre y tipo)

Usé `COUNT(DISTINCT card\_id)` porque necesito cantidad de tarjetas, no de transacciones. Una tarjeta con 50 transacciones al mes cuenta como 1.

|Trimestre|Crédito|Débito|
|-|-|-|
|Q1 2024|46,747|8,224|
|Q2 2024|51,037|8,960|

Crecimiento de 9.2% en tarjetas de crédito activas entre Q1 y Q2.

### Ticket Trimestral (crédito)

Calculé el ticket como `SUM(amt) / COUNT(DISTINCT card\_id)`, no como `AVG(amt)`. Son métricas distintas: AVG da el promedio por transacción ($195), mientras que SUM/COUNT DISTINCT da el gasto promedio por tarjeta en el trimestre ($3,229 en Q1, $5,019 en Q2). Como me piden "gasto promedio por tarjeta", corresponde la segunda.

|Trimestre|Ticket promedio por tarjeta|
|-|-|
|Q1 2024|$3,229.40|
|Q2 2024|$5,019.38|

### Ticket Regional (Sudamérica, crédito, por producto)

Acá sí necesito "monto de transacción promedio", entonces usé `AVG(amt)` directo. Filtré los 9 países sudamericanos que aparecen en la data (Argentina, Bolivia, Brazil, Chile, Colombia, Ecuador, Paraguay, Peru, Uruguay).

|Producto|Ticket promedio|
|-|-|
|P5|$1,008.62|
|P4|$592.14|
|P3|$186.76|
|P2|$118.23|
|P1|$67.59|

P5 tiene 15x más ticket que P1 pero solo el 5% de las transacciones. Hay una oportunidad de migración a productos premium.

### Top 10 MCG (% de gasto)

Usé CTEs para calcular el gasto por categoría y dividirlo entre el gasto total. LEFT JOIN con mcg\_list para no perder transacciones con mcg\_id huérfano.

|#|Categoría|% del gasto|
|-|-|-|
|1|Groceries and Supermarkets|22.16%|
|2|Restaurants and Dining|17.12%|
|3|Entertainment|13.40%|
|4|Travel and Transportation|10.34%|
|5|Clothing and Accessories|8.11%|

Las primeras 3 categorías concentran el 52.7% del gasto total.

### Adopción Contactless (% de gasto por país)

Usé `SUM(CASE WHEN is\_contactless = 1 THEN amt ELSE 0 END) / SUM(amt)` para sacar el porcentaje condicional.

Hallazgo principal: hay una brecha de 50 puntos porcentuales entre los 5 mercados grandes (Mexico, Colombia, Brazil, Argentina, Chile, todos en \~70%) y el resto de LATAM (\~20%). Es una oportunidad clara de penetración tecnológica en mercados secundarios.

\---

## 3\. Reto principal: Campaña Cashback Mayo 2024

### Reglas de la campaña

* Tarjetas de crédito emitidas en Chile
* Transacciones de mayo 2024
* Compras realizadas fuera de Chile (campo ctry\_mrch)
* Cashback: 7% del gasto del mes
* Tope máximo: 50 USD por tarjeta

### Decisiones de diseño (las más importantes del desafío)

**Decisión 1: El tope se aplica POR TARJETA, no por transacción.**

Esto importa para la lógica del query. Si aplico el tope por transacción, una tarjeta con 5 compras de $1,000 podría recibir 5 × $50 = $250 de cashback, lo cual viola el espíritu del tope. La forma correcta es: primero sumar el gasto del mes a nivel de card\_id (GROUP BY card\_id), después calcular el 7% sobre ese total, y solo entonces aplicar el cap con LEAST(cashback, 50).

**Decisión 2: Excluí montos negativos (devoluciones).**

En el diagnóstico identifiqué 30 transacciones con amt < 0 en el universo elegible. Una devolución no es una "compra realizada en comercios fuera de Chile", entonces no debería generar cashback. Filtré con `amt > 0`.

### Resultados

|Métrica|Valor|
|-|-|
|Tarjetas impactadas|**4,029**|
|Costo total del cashback|**$178,608.87 USD**|
|Cashback promedio por tarjeta|$44.33|
|Gasto total elegible|$7,327,231.90|
|Tarjetas que alcanzaron el tope|2,681 (66.5%)|
|Tarjetas bajo el tope|1,348 (33.5%)|

### Análisis financiero del tope

|Escenario|Costo|
|-|-|
|Sin tope (7% directo)|$512,906|
|Con tope de $50 (real)|$178,609|
|**Ahorro para Masterplop**|**$334,298 (65%)**|

La tasa efectiva de cashback resultó ser 2.44% sobre el gasto elegible, muy por debajo del 7% nominal. El tope de $50 fue una decisión financiera que redujo el costo de la campaña en 65% sin sacrificar el atractivo comercial para el cliente.

Que el 66.5% de las tarjetas haya alcanzado el tope indica que el segmento de chilenos que compra en el exterior tiene un perfil de gasto alto: gastaron más de $714 USD mensuales en compras internacionales (que es el umbral donde el 7% llega a $50).

\---

## 4\. Dashboard

El dashboard está construido como una aplicación HTML interactiva con dos páginas navegables:

* **Página 1 — Pulso del Negocio:** KPIs generales, volumen por trimestre, ticket trimestral, top 10 MCG, ticket regional por producto, y adopción contactless por país.
* **Página 2 — Campaña Cashback Mayo 2024:** KPIs del reto, distribución del cashback por rangos, comparación de costos con y sin tope, y métricas de cierre (gasto elegible, gasto promedio por tarjeta, tasa efectiva).

Para visualizarlo: abrir `dashboard/masterplop\_dashboard.html` en cualquier navegador.


\---

## Contacto

Laura Inés Martínez Suárez  
li.martinez10@hotmail.com  
(+57) 317 800 57 82  
[LinkedIn](http://www.linkedin.com/in/laura-inés-martinez)

