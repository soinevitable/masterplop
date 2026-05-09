-- ===============================================================
-- 06_INDICADOR_TOP_COMERCIOS.SQL
-- Ranking Top 10 de porcentaje de gasto por nombre de MCG.
--
-- Para sacar el porcentaje necesito dividir el gasto de cada 
-- categoría entre el gasto total. Uso CTEs para que el código 
-- sea legible: primero calculo el total, después agrupo por 
-- categoría, al final divido.
--
-- Decisión: uso LEFT JOIN para no perder transacciones si su
-- mcg_id no existe en mcg_list (por el mcg_id 35 huérfano en 
-- los datos). Si usara INNER JOIN, esas transacciones no se 
-- estarían teniendo en cuenta, y llego a un resultado que no es.
-- ===============================================================

WITH gasto_total AS (

    -- CTE 1: gasto total de toda la base (denom del porcentaje)

    SELECT SUM(amt) AS total
    FROM transac
),

gasto_por_mcg AS (

    -- CTE 2: agrupo el gasto por categoría
    -- LEFT JOIN trae el nombre desde mcg_list. Si el mcg_id no existe en mcg_list, el nombre queda NULL.

    SELECT
        m.mcg_name,
        SUM(t.amt) AS gasto_mcg
    FROM transac t
    LEFT JOIN mcg_list m ON t.mcg_id = m.mcg
    GROUP BY m.mcg_name
)

SELECT
    -- COALESCE: si el nombre es NULL lo reemplazo por 'Sin categoría'
    -- Esto puede aparecer si hay mcg_ids huérfanos

    COALESCE(mcg_name, 'Sin categoría') AS categoria,
    
    ROUND(gasto_mcg, 2) AS gasto,
    
    -- Calculo el porcentaje: gasto del MCG sobre el gasto total general

    ROUND((gasto_mcg / total) * 100, 2) AS porcentaje_gasto
    
FROM gasto_por_mcg

-- CROSS JOIN porque gasto_total tiene una sola fila (el total general)
-- Ahí agrego esa columna 'total' a cada fila de gasto_por_mcg

CROSS JOIN gasto_total
ORDER BY porcentaje_gasto DESC
LIMIT 10;

