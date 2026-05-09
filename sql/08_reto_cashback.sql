-- ============================================================
-- 08_RETO_CASHBACK_MAYO_2024.SQL
-- EL RETO PRINCIPAL DEL DESAFÍO! 
--
-- Pregunta: ¿Cuál es el costo total del cashback de la 
-- campaña para Masterplop? ¿A cuántas tarjetas impactó?
--
-- Reglas de la campaña:
-- 1. Solo tarjetas de CRÉDITO emitidas en Chile
-- 2. Solo transacciones de mayo 2024
-- 3. Solo compras hechas FUERA de Chile (ctry_mrch != 'Chile')
-- 4. Cashback = 7% del gasto del mes POR TARJETA
-- 5. Tope máximo de 50 USD POR TARJETA
--
-- Decisiones clave que tomé:
--
-- a) EL TOPE ES POR TARJETA, NO POR TRANSACCIÓN.
--    Esto significa que primero tengo que SUMAR el gasto del 
--    mes a nivel de card_id, después calcular el 7%, y solo
--    entonces aplicar el tope de $50 con LEAST().
--    Si lo hiciera al revés (cashback por transacción + cap por
--    transacción), una tarjeta con 5 compras de $1000 podría
--    recibir 5 × $50 = $250 de cashback, lo cual viola el tope.
--
-- b) EXCLUYO MONTOS NEGATIVOS (devoluciones).
--    En el diagnóstico vi que hay transacciones con amt < 0
--    (devoluciones/chargebacks). Una devolución no genera 
--    cashback (es plata que sale, no que entra). Por eso
--    filtro amt > 0 antes del calculo.
-- ============================================================

WITH compras_elegibles AS (

    -- Paso 1: filtrar las transacciones que califican para la campaña

    SELECT 
        card_id, 
        amt
    FROM transac
    WHERE product_type = 'Crédito'           -- Solo crédito
      AND ctry_card = 'Chile'                -- Tarjetas chilenas
      AND MONTH(prch_date) = 5                -- Mes de mayo
      AND YEAR(prch_date) = 2024              -- Año 2024
      AND ctry_mrch != 'Chile'                -- Compras FUERA de Chile
      AND amt > 0                             -- Solo compras (no devoluciones)
),

gasto_por_tarjeta AS (

    -- Paso 2: sumar el gasto del mes por cada tarjeta
    -- CLAVE: agrego a nivel de card_id ANTES de calcular el cashback. 
    -- Así garantizo que el tope se aplique correctamente por tarjeta.

    SELECT
        card_id,
        SUM(amt) AS gasto_total_mes
    FROM compras_elegibles
    GROUP BY card_id
),

cashback_por_tarjeta AS (

    -- Paso 3: calcular el cashback aplicando el tope de 50 USD

    SELECT
        card_id,
        gasto_total_mes,
        
        -- Cashback bruto (sin tope) lo guardo para luego saber a cuántas tarjetas afectó el cap

        ROUND(gasto_total_mes * 0.07, 2) AS cashback_bruto,
        
        -- LEAST(a, b) devuelve el menor de los dos valores
        -- Si el 7% del gasto es mayor a 50, devuelve 50 (aplica el tope)
        -- Si el 7% del gasto es menor a 50, devuelve el 7% (no aplica el tope)

        ROUND(LEAST(gasto_total_mes * 0.07, 50), 2) AS cashback_final
    FROM gasto_por_tarjeta
)

-- Paso 4: respuesta final consolidada

SELECT
    -- Cuántas tarjetas distintas recibieron cashback

    COUNT(*) AS tarjetas_impactadas,
    
    -- Costo total que pagará Masterplop

    ROUND(SUM(cashback_final), 2) AS costo_total_cashback_usd,
    
    -- Métricas adicionales útiles para contextualizar

    ROUND(AVG(cashback_final), 2) AS cashback_promedio_por_tarjeta,
    ROUND(SUM(gasto_total_mes), 2) AS gasto_total_elegible,
    
    -- Cuántas tarjetas alcanzaron el tope de 50 USD
    -- Esto es información valiosa para la gerencia: indica si el tope es muy restrictivo o si la mayoría no llega

    SUM(CASE WHEN cashback_bruto >= 50 THEN 1 ELSE 0 END) AS tarjetas_con_tope,
    SUM(CASE WHEN cashback_bruto < 50 THEN 1 ELSE 0 END) AS tarjetas_sin_tope
    
FROM cashback_por_tarjeta;


