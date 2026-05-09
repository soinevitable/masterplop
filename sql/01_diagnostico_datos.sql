-- ============================================================
-- 01_DIAGNOSTICO_DATOS.SQL
-- Antes de empezar, exploro qué hay sucio en la data. Verificaciones
-- ============================================================

-- 1. ¿Cuántas filas y columnas hay? Confirmo tamaño del dataset

SELECT COUNT(*) AS total_filas FROM transac_raw;


-- 2. Variantes únicas de product_type
-- Pueden haber duplicados por idioma y tildes (Credit/Credito/Crédito)
-- El diccionario dice que solo hay 3 categorías: Crédito, Débito, Prepago

SELECT 
    product_type, 
    COUNT(*) AS cantidad
FROM transac_raw
GROUP BY product_type
ORDER BY cantidad DESC;


-- 3. Países en ctry_card
-- Revisar si hay duplicados por tildes o idioma

SELECT 
    ctry_card, 
    COUNT(*) AS cantidad
FROM transac_raw
GROUP BY ctry_card
ORDER BY cantidad DESC;


-- 4. Formato de fechas
-- Veo si hay formatos mixtos (con guiones, barras, etc.)

SELECT 
    prch_date, 
    COUNT(*) AS cantidad
FROM transac_raw
GROUP BY prch_date
ORDER BY prch_date
LIMIT 10;


-- 5. MCG IDs presentes en la data
-- Verifico si todos los mcg_id de las transacciones existen en mcg_list

SELECT DISTINCT mcg_id 
FROM transac_raw 
ORDER BY mcg_id;


-- 6. Detectar transacciones con mcg_id que no existan en mcg_list

SELECT 
    t.mcg_id, 
    COUNT(*) AS transacciones_huerfanas
FROM transac_raw t
LEFT JOIN mcg_list m ON t.mcg_id = m.mcg
WHERE m.mcg IS NULL
GROUP BY t.mcg_id;


-- 7. Estadísticas básicas del monto (amt)
-- Quiero saber si hay valores negativos (devoluciones), montos muy altos, etc.

SELECT
    MIN(amt) AS minimo,
    MAX(amt) AS maximo,
    AVG(amt) AS promedio,
    MEDIAN(amt) AS mediana,
    COUNT(*) FILTER (WHERE amt < 0) AS cantidad_negativos,
    COUNT(*) FILTER (WHERE amt = 0) AS cantidad_ceros
FROM transac_raw;


-- 8. NULL check en columnas críticas
-- Si hay NULLs en columnas clave necesito decidir cómo los gestiono

SELECT
    COUNT(*) FILTER (WHERE card_id IS NULL) AS card_id_nulls,
    COUNT(*) FILTER (WHERE product_type IS NULL) AS product_type_nulls,
    COUNT(*) FILTER (WHERE amt IS NULL) AS amt_nulls,
    COUNT(*) FILTER (WHERE prch_date IS NULL) AS prch_date_nulls,
    COUNT(*) FILTER (WHERE ctry_card IS NULL) AS ctry_card_nulls,
    COUNT(*) FILTER (WHERE ctry_mrch IS NULL) AS ctry_mrch_nulls
FROM transac_raw;
