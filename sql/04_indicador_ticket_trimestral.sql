-- ============================================================
-- 04_INDICADOR_TICKET_TRIMESTRAL.SQL
-- Gasto promedio por tarjeta de crédito por trimestre.
--
-- Clave: el "gasto promedio por tarjeta" se calcula
-- como GASTO TOTAL / TARJETAS ÚNICAS, no como AVG(amt).
-- 
-- Ejemplo de por qué: si una tarjeta hace 100 transacciones de
-- $10, su gasto del trimestre es $1,000 (no $10). Si yo usara
-- AVG(amt), me daría el promedio POR TRANSACCIÓN, que es otra
-- métrica distinta y no es lo que están pidiendo.
-- ============================================================

SELECT
    QUARTER(prch_date) AS trimestre,
    
    -- Gasto total del trimestre (solo crédito)

    ROUND(SUM(amt), 2) AS gasto_total,
    
    -- Cantidad de tarjetas únicas que transaccionaron

    COUNT(DISTINCT card_id) AS tarjetas_unicas,
    
    -- Ticket promedio por tarjeta = Gasto total / Tarjetas únicas

    ROUND(SUM(amt) / COUNT(DISTINCT card_id), 2) AS ticket_promedio_tarjeta
    
FROM transac
WHERE product_type = 'Crédito'   -- Solo tarjetas de crédito
GROUP BY QUARTER(prch_date)
ORDER BY trimestre;

