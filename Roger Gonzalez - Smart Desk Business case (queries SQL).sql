--1. Sales and Profit Analysis by Product Category for Adabs Entertainment in 2020
----Conducting an analysis of total sales and profit broken down by product category exclusively for the Adabs Entertainment account during the year 2020. Calculate the sums of Sales (maintenance, product, parts, support, totals), number of units sold, and total profit.

SELECT * FROM FORECASTS;
SELECT * FROM ACCOUNTS;
SELECT * FROM SALES;

SELECT
category,
	SUM(maintenance) AS ventas_mantenimiento,
	SUM(product) AS ventas_producto,
	SUM(parts) AS ventas_partes,
	SUM(support) AS ventas_soported,
	SUM(total) AS ventas_totales,
	SUM(units_sold) AS unidades_vendidas,
	SUM(profit) AS total_beneficio_categoria
FROM SALES
WHERE account = 'Adabs Entertainment' AND year = 2020
GROUP BY category;

--2. Comparison of Sales, Units Sold, and Profit Between Countries in the APAC and EMEA Regions
----Comparing sales performance across different countries within the APAC and EMEA regions. Calculate the following metrics: average revenue, average units sold, and average profit.

SELECT country, ROUND(AVG(total), 2) AS ingreso_promedio, ROUND(AVG(units_sold), 2) AS unidas_vendidas_promedio, ROUND(AVG(profit), 2) AS beneficio_promedio
FROM ACCOUNTS AS a
INNER JOIN SALES as s
ON a.account = s.account
WHERE region = 'APAC' OR region = 'EMEA'
GROUP BY country
ORDER BY ingreso_promedio DESC;

--3. Total Profit Analysis (SALES) by Industry (ACCOUNTS): Study of Clients in the Commitment Stage (FORECASTS) (Pipeline, Upside, Commit)
----Calculate the total profit for each industry and classify it as "High" if it exceeds $1,000,000 or "Normal" if it does not. 

SELECT industry, SUM(profit) AS beneficio_total,
	CASE
		WHEN beneficio_total > 1000000 THEN 'Alto'
		ELSE 'Normal'
		END AS "Clasificacion"
FROM SALES as s
INNER JOIN ACCOUNTS AS a
ON s.account = a.account
WHERE s.account IN (
	SELECT account
	FROM FORECASTS
	WHERE prediction_category = 'Commit' AND forecast > 500000
	ORDER BY account
)
GROUP BY industry
ORDER BY industry;

--4. Forecast vs. Actual Profit Evolution: Category-Level Trajectory Analysis
----Calculate the profit forecast for the year 2022 and the actual profit for Q1 2020 and Q3 2021, grouping the results by product category. Additionally, identify the oldest and the most recent opportunity within each category.

WITH vista_completa AS (
	SELECT
		COALESCE(s.category, f.category) AS categoria,
		COALESCE(s.year, f.year) AS year,
		s.quarter,
		SUM(s.profit) AS beneficio_total,
		SUM(forecast) AS pronostico_total,
		MAX(f.opportunity_age) AS oportunidad_mas_antigua,
		MIN(f.opportunity_age) AS oportunidad_mas_reciente
	FROM SALES AS s
	FULL JOIN FORECASTS as f
	ON s.category = f.category AND s.year = f.year
	WHERE quarter = '2020 Q1' OR quarter = '2021 Q3' OR f.year = 2022
	GROUP BY ALL
	ORDER BY quarter
)
SELECT 
	categoria,
	SUM(beneficio_total) AS beneficio_total,
	SUM(pronostico_total) AS pronostico_total,
	MAX(oportunidad_mas_antigua),
	MAX(oportunidad_mas_reciente)
FROM vista_completa
GROUP BY categoria
ORDER BY beneficio_total DESC, pronostico_total DESC;



---------------------------------------------------------BUSINESS CASE---------------------------------------------------------
--Exploratory Sales Analysis (General)

SELECT 
	COUNT(DISTINCT(ACCOUNT)) AS num_clientes,
	COUNT(*) AS num_filas,
	ROUND(AVG(product+parts), 2) AS ingreso_medio_producto,
	ROUND(STDDEV(product+parts), 2) AS desviacion_producto,
	ROUND((desviacion_producto/ingreso_medio_producto), 2) AS coef_variacion,
	ROUND(AVG(support+maintenance), 2) AS ingreso_medio_servicio,
	ROUND(STDDEV(support+maintenance), 2) AS desviacion_servicio,
	ROUND((desviacion_servicio/ingreso_medio_servicio), 2) AS coef_variacion,
	ROUND(AVG(total), 2) AS ingreso_medio,
	ROUND(AVG(profit), 2) AS beneficio_medio,
	ROUND(STDDEV(total), 2) AS desviacion_ingresos,
	ROUND(STDDEV(profit), 2) AS desviacion_beneficios,
	MIN(year) AS venta_mas_antigua,
	MAX(year) AS venta_mas_reciente
FROM SALES
WHERE year IN (2020, 2021);


--Exploratory Sales Analysis (By Country)

CREATE OR REPLACE VIEW sales_by_countries AS
	WITH customers AS (
		SELECT *
		FROM ACCOUNTS
		WHERE account_level = 'Customer'
	)
	SELECT year, c.country, SUM(product+parts) AS ingresos_productos, SUM(MAINTENANCE+SUPPORT) AS ingresos_servicios, SUM(total) AS ingresos_totales, SUM(profit) AS beneficios_totales, ROUND((beneficios_totales/ingresos_totales), 2) AS rentabilidad_total
	FROM SALES as s
	LEFT JOIN customers AS c
	ON s.account = c.account
	WHERE year IN (2020, 2021)
	GROUP BY year, c.country
	ORDER BY year, ingresos_totales DESC;

SELECT 
	COUNT(DISTINCT(country)) AS num_paises,
	COUNT(*) AS num_filas,
	ROUND(AVG(ingresos_productos), 2) AS ingreso_medio_producto,
	ROUND(STDDEV(ingresos_productos), 2) AS desviacion_producto,
	ROUND((desviacion_producto/ingreso_medio_producto), 2) AS coef_variacion,
	ROUND(AVG(ingresos_servicios), 2) AS ingreso_medio_servicio,
	ROUND(STDDEV(ingresos_servicios), 2) AS desviacion_servicio,
	ROUND((desviacion_servicio/ingreso_medio_servicio), 2) AS coef_variacion,
	ROUND(CORR(ingresos_totales, beneficios_totales),4) AS correlacion_ing_benef,
	ROUND(AVG(ingresos_totales), 2) AS ingreso_medio,
	ROUND(AVG(beneficios_totales), 2) AS beneficio_medio,
	ROUND(STDDEV(ingresos_totales), 2) AS desviacion_ingresos,
	ROUND(STDDEV(beneficios_totales), 2) AS desviacion_beneficios,
	ROUND((desviacion_ingresos/ingreso_medio), 2) AS coef_variacion_ing,
	ROUND((desviacion_beneficios/beneficio_medio), 2) AS coef_variacion_benef
FROM sales_by_countries
WHERE year IN (2020, 2021);

--SALES BY COUNTRY IN 2020 and 2021 (including profitability column)

SELECT * FROM sales_by_countries;

WITH country_growth AS (
    SELECT
        country,
        MAX(CASE WHEN year = 2020 THEN ingresos_productos ELSE NULL END) AS ingresos_prod_2020,
        MAX(CASE WHEN year = 2021 THEN ingresos_productos ELSE NULL END) AS ingresos_prod_2021,
        MAX(CASE WHEN year = 2020 THEN ingresos_servicios ELSE NULL END) AS ingresos_serv_2020,
        MAX(CASE WHEN year = 2021 THEN ingresos_servicios ELSE NULL END) AS ingresos_serv_2021,

        MAX(CASE WHEN year = 2020 THEN ingresos_totales ELSE NULL END) AS ingresos_2020,
        MAX(CASE WHEN year = 2021 THEN ingresos_totales ELSE NULL END) AS ingresos_2021,

        MAX(CASE WHEN year = 2020 THEN beneficios_totales ELSE NULL END) AS beneficios_2020,
        MAX(CASE WHEN year = 2021 THEN beneficios_totales ELSE NULL END) AS beneficios_2021,

        ROUND(100 * ingresos_2020 / SUM(ingresos_2020) OVER (), 2) AS peso_ingresos_2020_pct,
        ROUND(100 * ingresos_2021 / SUM(ingresos_2021) OVER (), 2) AS peso_ingresos_2021_pct,
        ROUND(100 * beneficios_2020 / SUM(beneficios_2020) OVER (), 2) AS peso_beneficios_2020_pct,
        ROUND(100 * beneficios_2021 / SUM(beneficios_2021) OVER (), 2) AS peso_beneficios_2021_pct,

        ROUND((MAX(CASE WHEN year = 2021 THEN ingresos_productos END) - MAX(CASE WHEN year = 2020 THEN ingresos_productos END)) / MAX(CASE WHEN year = 2020 THEN ingresos_productos END), 2) AS YoY_ingresos_prod,
        ROUND((MAX(CASE WHEN year = 2021 THEN ingresos_servicios END) - MAX(CASE WHEN year = 2020 THEN ingresos_servicios END)) / MAX(CASE WHEN year = 2020 THEN ingresos_servicios END), 2) AS YoY_ingresos_serv,
        ROUND((MAX(CASE WHEN year = 2021 THEN ingresos_totales END) - MAX(CASE WHEN year = 2020 THEN ingresos_totales END)) / MAX(CASE WHEN year = 2020 THEN ingresos_totales END), 2) AS YoY_ingresos,
        ROUND((MAX(CASE WHEN year = 2021 THEN beneficios_totales END) - MAX(CASE WHEN year = 2020 THEN beneficios_totales END)) / MAX(CASE WHEN year = 2020 THEN beneficios_totales END), 2) AS YoY_beneficios
    FROM sales_by_countries
    GROUP BY country
    )

SELECT country, peso_ingresos_2020_pct, peso_ingresos_2021_pct, peso_beneficios_2020_pct, peso_beneficios_2021_pct, YoY_ingresos_prod, YoY_ingresos_serv, YoY_ingresos, YoY_beneficios
FROM country_growth
ORDER BY peso_ingresos_2021_pct DESC, YOY_ingresos DESC;



