-- ============================================================
-- 05_INDICADOR_TICKET_REGIONAL.SQL
-- Monto de transacción promedio de tarjetas de crédito por
-- producto en países de Sudamérica.
--
-- DIFERENCIA CON EL TICKET TRIMESTRAL: aquí me piden el promedio
-- por TRANSACCIÓN (no por tarjeta). Por eso uso AVG(amt) directo.
-- 
-- LISTA DE PAÍSES SUDAMERICANOS: incluyo los 9 que aparecen en
-- la data. Venezuela, Guyana, Suriname y Guayana Francesa no
-- tienen transacciones en el dataset.
-- ============================================================

SELECT
    product_name,
    
    -- AVG(amt) = promedio por transacción

    ROUND(AVG(amt), 2) AS ticket_promedio,
    
    -- Cantidad de transacciones para dar contexto al promedio

    COUNT(*) AS num_transacciones,
    
    -- Suma total para tener referencia del volumen

    ROUND(SUM(amt), 2) AS gasto_total
    
FROM transac
WHERE product_type = 'Crédito'
  AND ctry_card IN (
      'Argentina', 
      'Bolivia', 
      'Brazil', 
      'Chile', 
      'Colombia',
      'Ecuador', 
      'Paraguay', 
      'Peru', 
      'Uruguay'
  )
GROUP BY product_name
ORDER BY ticket_promedio DESC;

