-- ============================================================
-- 03_INDICADOR_VOLUMEN.SQL
-- Cantidad de tarjetas que han realizado transacciones en cada 
-- trimestre, por tipo de tarjeta.
--
-- Clave acá: cuento tarjetas únicas, no transacciones.
-- Una tarjeta con 50 transacciones cuenta como 1 sola tarjeta.
-- ============================================================

SELECT
    -- QUARTER() me devuelve 1, 2, 3 o 4 según el trimestre de la fecha

    QUARTER(prch_date) AS trimestre,
    product_type,

    -- DISTINCT dentro del COUNT cuenta valores únicos de card_id

    COUNT(DISTINCT card_id) AS cantidad_tarjetas

FROM transac
GROUP BY 
    QUARTER(prch_date), 
    product_type
ORDER BY 
    trimestre, 
    product_type;

