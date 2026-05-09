-- ============================================================
-- 02_LIMPIEZA.SQL
-- Creo una VISTA con los datos limpios y normalizados, para no 
-- duplicar los datos en memoria: cada vez que la consulto 
-- ejecuta la limpieza ahí mismo.
--
-- Con esto resuelvo:
-- 1. product_type tiene 6 variantes (Credit/Credito/Crédito + Debit/Debito/Débito)
-- 2. Países duplicados con/sin tildes (Brazil vs Brasil, etc.)
-- 3. Fechas en formatos mixtos: dd-mm-yyyy y dd/mm/yyyy
-- ============================================================

CREATE OR REPLACE VIEW transac AS
SELECT
    card_id,
    product_name,
    
    -- Normalizo product_type a sus 2 categorías reales que aparecen en la data
    -- Decisión: uso 'Crédito' y 'Débito' (con tilde) por ser el idioma del cliente (Masterplop opera en Latam principalmente)

    CASE 
        WHEN product_type IN ('Credit', 'Credito', 'Crédito') THEN 'Crédito'
        WHEN product_type IN ('Debit', 'Debito', 'Débito') THEN 'Débito'
        ELSE product_type   -- conservo cualquier otro valor por si aparece algo no esperado
    END AS product_type,
    
    amt,
    is_xb,
    is_contactless,
    
    -- Reemplazo todos los guiones por barras para tener formato uniforme dd/mm/yyyy
    -- Después uso STRPTIME para parsear el string a fecha real
    -- ::DATE convierte de timestamp a date (sin la hora, solo fecha)

    STRPTIME(REPLACE(prch_date, '-', '/'), '%d/%m/%Y')::DATE AS prch_date,
    
    prch_time,
    
    -- Normalizo país de la tarjeta y comercio: unifico nombres con tildes vs sin tildes
    -- Decisión: uso versión sin tildes por ser estándar internacional y manejar mejor los datos

    CASE ctry_card
        WHEN 'Brasil' THEN 'Brazil'
        WHEN 'México' THEN 'Mexico'
        WHEN 'Perú' THEN 'Peru'
        WHEN 'Panamá' THEN 'Panama'
        WHEN 'República Dominicana' THEN 'Republica Dominicana'
        ELSE ctry_card
    END AS ctry_card,

    CASE ctry_mrch
        WHEN 'Brasil' THEN 'Brazil'
        WHEN 'México' THEN 'Mexico'
        WHEN 'Perú' THEN 'Peru'
        WHEN 'Panamá' THEN 'Panama'
        WHEN 'República Dominicana' THEN 'Republica Dominicana'
        ELSE ctry_mrch
    END AS ctry_mrch,
    
    mrch,
    mcg_id

FROM transac_raw;

-- Valido que la limpieza funcionó: espero ver solo 2 categorías

SELECT 
    product_type, 
    COUNT(*) AS cantidad
FROM transac
GROUP BY product_type
ORDER BY cantidad DESC;


-- Valido países: ya no debería haber duplicados Brazil/Brasil, etc.

SELECT 
    ctry_card, 
    COUNT(*) AS cantidad
FROM transac
GROUP BY ctry_card
ORDER BY cantidad DESC;


-- Valido el rango de fechas para confirmar el parseo

SELECT 
    MIN(prch_date) AS fecha_minima,
    MAX(prch_date) AS fecha_maxima
FROM transac;
