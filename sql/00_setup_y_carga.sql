-- ============================================================
-- 00_SETUP_Y_CARGA.SQL
-- Cargar los archivos del desafío como tablas en DuckDB
-- ============================================================

-- Cargo la tabla de transacciones desde el CSV

CREATE OR REPLACE TABLE transac_raw AS 
SELECT * 
FROM read_csv_auto('C:/Users/LAURA/Documents/Responsabilidades/Work/AplicacionesJOBS/Artefact/Analytics engineer/masterplop/data/db_transac.csv', header=true);


-- Cargo la tabla maestra de MCG directamente con INSERT

CREATE OR REPLACE TABLE mcg_list (
    mcg INTEGER, 
    mcg_name VARCHAR
);

INSERT INTO mcg_list VALUES
    (1, 'Groceries and Supermarkets'),
    (2, 'Restaurants and Dining'),
    (3, 'Entertainment'),
    (4, 'Travel and Transportation'),
    (5, 'Clothing and Accessories'),
    (6, 'Electronics and Appliances'),
    (7, 'Health and Wellness'),
    (8, 'Home Improvement'),
    (9, 'Automotive'),
    (10, 'Education and Books'),
    (11, 'Financial Services'),
    (12, 'Professional Services'),
    (13, 'Utilities and Bills'),
    (14, 'Government Services'),
    (15, 'Charity and Donations'),
    (16, 'Personal Services'),
    (17, 'Office Supplies'),
    (18, 'Hardware and Garden'),
    (19, 'Furniture and Decor'),
    (20, 'Sporting Goods'),
    (21, 'Beauty and Personal Care'),
    (22, 'Pet Supplies and Services'),
    (23, 'Telecommunications'),
    (24, 'Online Services and Digital Goods'),
    (25, 'Specialty Retail');


-- Verifico que todo cargó bien

SELECT 'transac_raw' AS tabla, COUNT(*) AS filas FROM transac_raw
UNION ALL
SELECT 'mcg_list', COUNT(*) FROM mcg_list;
