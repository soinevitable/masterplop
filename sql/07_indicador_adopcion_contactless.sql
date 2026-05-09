-- ===============================================================
-- 07_INDICADOR_ADOPCION_CONTACTLESS.SQL
-- Porcentaje de gasto contactless ordenado por país.
--
-- útil acá: para el porcentaje condicional uso
-- SUM(CASE WHEN condicion THEN valor ELSE 0 END). Esto suma 
-- solo las filas que cumplen la condición y deja en 0 las que no.
-- ===============================================================

SELECT
    ctry_card AS pais,
    
    -- Gasto total del país (todas las transacciones)

    ROUND(SUM(amt), 2) AS gasto_total,
    
    -- Gasto contactless: solo sumo cuando is_contactless = 1

    ROUND(
        SUM(CASE WHEN is_contactless = 1 THEN amt ELSE 0 END), 
        2
    ) AS gasto_contactless,
    
    -- Porcentaje = (gasto contactless / gasto total) * 100

    ROUND(
        SUM(CASE WHEN is_contactless = 1 THEN amt ELSE 0 END) 
        / SUM(amt) * 100,
        2
    ) AS pct_contactless
    
FROM transac
GROUP BY ctry_card
ORDER BY pct_contactless DESC;

