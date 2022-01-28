-- COVID data project - more info about objetcives in the readme file

-- Query showing for wich countries we have a data on performed tests (in some countries betweem 2020-01-01 and 2020-11-24 were to tests preformed )
SELECT 
Country,
sum(tests_performed)
FROM covid19_tests ct 
GROUP BY country;

-- 1) Time related data
-- From covid19_tests table data Main table creation:
-- t_filip_n_basic_data_table
-- including following data: country, date, test performed, working day, time of year:
CREATE OR REPLACE TABLE t_filip_n_basic_data_table AS  
SELECT
	country,
	date,
	tests_performed,
		CASE -- Was test performed during working day or not (Working DAY= TRUE, Weekend=FALSE)
			WHEN weekday(date) in (5,6) then 'False'
				else 'True'
					end as Working_day,
		CASE -- Season of the year when test was performed (Spring=0, Summer=1, Autumn=2, Winter=3); The start of the seasons turn to shift which is the case e.g. of 2020 and 2021. For this Case the astronomical seasons for 2020 were used. 
		-- Spring
			WHEN (DAYOFMONTH(date) BETWEEN 20 AND 31) AND (MONTH(date) in (3)) THEN 0
			WHEN (DAYOFMONTH(date) BETWEEN 1 AND 31) AND (MONTH(date) in (4,5)) THEN 0
			WHEN (DAYOFMONTH(date) BETWEEN 1 AND 19) AND (MONTH(date) in (6)) THEN 0
		-- Summer
			WHEN (DAYOFMONTH(date) BETWEEN 20 AND 31) AND (MONTH(date) in (6)) THEN 1
			WHEN (DAYOFMONTH(date) BETWEEN 1 AND 31) AND (MONTH(date) in (7,8)) THEN 1
			WHEN (DAYOFMONTH(date) BETWEEN 1 AND 21) AND (MONTH(date) in (9)) THEN 1
		-- Autumn
			WHEN (DAYOFMONTH(date) BETWEEN 22 AND 31) AND (MONTH(date) in (9)) THEN 2
			WHEN (DAYOFMONTH(date) BETWEEN 1 AND 31) AND (MONTH(date) in (10,11)) THEN 2
			WHEN (DAYOFMONTH(date) BETWEEN 1 AND 21) AND (MONTH(date) in (12)) THEN 2
		-- Winter
			ELSE 3
			END AS Season_of_year
FROM covid19_tests ct; 

-- 2) Countries related data
-- From countries c and economices e new table creation:
-- t_filip_n_countries_economies_data
CREATE OR REPLACE TABLE t_filip_n_countries_economies_data AS 
SELECT
	c.country,
	c.population_density,
	c.median_age_2018,
	e.gdp_2020,
	e2.Average_GINI,
	e3.Average_child_mortality
FROM countries c 
	JOIN 
		(SELECT 
			e.country,
			e.gdp AS GDP_2020
		FROM economies e
			WHERE YEAR = 2020
			AND e.gdp IS NOT NULL)
			e ON c.country = e.country
	JOIN 
		(SELECT
			e2.country, 
			round(AVG(e2.gini),2) as Average_GINI
		FROM economies e2
			WHERE e2.gini != 0
			GROUP BY e2.country)
			e2 ON c.country = e2.country			
 	JOIN (SELECT 
 			e3.country, 
 			round(AVG(e3.mortaliy_under5),2) as Average_child_mortality
		FROM economies e3
		WHERE e3.mortaliy_under5 !=0
		GROUP BY e3.country)
			e3 ON c.country = e3.country;
			
-- unifing some country names
UPDATE t_filip_n_countries_economies_data
	SET country = 'Russia'
	WHERE country = 'Russian Federation';



-- 3. Religion related data. 
	-- For creation of final t_filip_n_Religions table for the Religion part the following tables/views were used:
	-- Table: 
	-- t_filip_n_religion_share - showing religions share per each country and to be used as a main table for agregation of other required data
	-- t_filip_n_Religions - final table on Religion part ready for final Join
	-- Views: 
	-- v_population_2020_from_religions -  cumulating the population for each country in 2020 based on the data from religions table (instead of a different table)
	-- v_islam_share - share of religion per country to be used in the final table
	-- v_hinduism_share - share of religion per country to be used in the final table
	-- v_buddhism_share - share of religion per country to be used in the final table
	--  v_judaism_share - share of religion per country to be used in the final table
 	-- v_folk_rel_share - share of religion per country to be used in the final table
	-- Other tables used ofr this part:
	--  countries c and religions r 
CREATE  OR REPLACE TABLE t_filip_n_religion_share as
	SELECT
		r.country, r.religion, round(r.population*100/rs.total_population, 2) AS religion_share
	FROM religions r
	JOIN (SELECT
			r.country,
			r.year,  
			sum(r.population) as total_population
			FROM religions r
			WHERE r.year = 2020 
			GROUP BY r.country) 
		rs ON r.country = rs.country
		AND r.YEAR = rs.YEAR
		AND r.population > 0;


UPDATE t_filip_n_religion_share
	SET country = 'Congo'
	WHERE country = 'The Democratic Republic of Congo';

UPDATE t_filip_n_religion_share
	SET country = 'Russia'
	WHERE country = 'Russian Federation';


-- Creating view - creation of 'sum_population' column and values from 2020 instead of using the population numbers from other tables which would lead in some countries to bigger number of believers than the number of all citizens 
CREATE OR REPLACE VIEW v_population_2020_from_religions AS 
SELECT
DISTINCT country,
Sum(population) AS 'sum_population'
FROM 
religions
WHERE YEAR = 2020
GROUP BY country;


-- Creating view with v_basic_religion_share population from v_population_2020_from_religions  - otherwise number of population from other tab les is sometime lower than number of believers in 2020 from religions table
CREATE OR REPLACE VIEW v_basic_religion_share AS
	SELECT 
		r.country,
		rp.sum_population AS population,
		r.religion AS religion,
		r.population AS no_of_believers		
	FROM religions r 
	LEFT JOIN v_population_2020_from_religions rp
		ON r.country = rp.country
	WHERE r.year = 2020;


-- Creating view of Christianity share 
CREATE OR REPLACE VIEW v_christianity_share AS 
	SELECT
		country,
		(no_of_believers/population)*100 AS Christianity_share
	FROM v_basic_religion_share brs
	WHERE religion = 'Christianity';
	

-- Creating view of Islam Share 
CREATE OR REPLACE VIEW v_islam_share AS 
	SELECT
		country,
		(no_of_believers/population)*100 AS Islam_share
	FROM v_basic_religion_share brs
	WHERE religion = 'Islam';

-- Creating view of Hinduism Share
CREATE OR REPLACE VIEW v_hinduism_share AS 
	SELECT
		country,
		(no_of_believers/population)*100 AS Hinduism_share
	FROM v_basic_religion_share brs
	WHERE religion = 'Hinduism';	
	
-- Creating view of Buddhism Share 
CREATE OR REPLACE VIEW v_buddhism_share AS 
	SELECT
		country,
		(no_of_believers/population)*100 AS Buddhism_share
	FROM v_basic_religion_share brs
	WHERE religion = 'Buddhism';	

-- Creating view of Judaism Share 
CREATE OR REPLACE VIEW v_judaism_share AS 
	SELECT
		country,
		(no_of_believers/population)*100 AS Judaism_share
	FROM v_basic_religion_share brs
	WHERE religion = 'Judaism';	
	
-- Creating view of Folk religions Share -OK 
CREATE OR REPLACE VIEW v_folk_rel_share AS 
	SELECT
		country,
		(no_of_believers/population)*100 AS Folk_rel_share
	FROM v_basic_religion_share brs
	WHERE religion = 'Folk_religions';	
	
	
-- Creating Religions final table
CREATE OR REPLACE TABLE t_filip_n_Religions AS 	
	SELECT
	vcs.country,
	vcs.Christianity_share,
	vis.Islam_share,
	vbs.Buddhism_share,
	vhs.Hinduism_share,
	vjs.Judaism_share,
	vfs.Folk_rel_share
	FROM 
	v_christianity_share vcs
	LEFT JOIN v_islam_share vis
		ON vcs.country = vis.country
	LEFT JOIN v_Buddhism_share vbs
		ON vcs.country = vbs.country	
	LEFT JOIN v_hinduism_share vhs
		ON vcs.country = vhs.country
	LEFT JOIN v_judaism_share vjs 	
		ON vcs.country = vjs.country 
	LEFT JOIN v_folk_rel_share vfs 
		ON vcs.country = vfs.country;
		
UPDATE t_filip_n_Religions
	SET country = 'Russia'
	WHERE country = 'Russian Federation';

UPDATE t_filip_n_Religions	
	SET country = 'Congo'
	WHERE country = 'The Democratic Republic of Congo';

	
-- 4. Life expectancy difference between 1965 and 2015
	-- For creation of final t_filip_n_life_expectation table for the Life expectancy  the following tables were used:
	-- Table: life_expectancy 
CREATE OR REPLACE TABLE t_filip_n_life_expectation
SELECT le2015.country, le2015.life_expectancy_2015, le1965.life_expectancy_1965, round(le2015.life_expectancy_2015 - le1965.life_expectancy_1965) AS life_expectancy_difference
FROM
	(SELECT 
		le.country, 
		le.life_expectancy AS life_expectancy_2015
		FROM life_expectancy le
		WHERE YEAR = 2015) le2015 
		JOIN 
		(SELECT
			le.country,
			le.life_expectancy AS life_expectancy_1965
			FROM life_expectancy le
			WHERE YEAR = 1965) le1965 
			ON le2015.country = le1965.country;	

UPDATE t_filip_n_life_expectation
	SET country = 'Russia'
	WHERE country = 'Russian Federation';

UPDATE t_filip_n_life_expectation
	SET country = 'Congo'
	WHERE country = 'The Democratic Republic of Congo';


-- 5. Weather conditions 
-- For creation of  t_filip_n_weather_variables  table for the Weather conditions part the following tables/views were used:
	-- Table: t_filip_n_weather_data_fixed_city_names - converting varcharacters into integers where it's needed  
		   -- t_filip_n_weather_variables - final weather table calculating required results (daily average temp., hours of rain and max wind gust)
	-- View: v_filip_n_fixed_city_name (to join tables several names of cities needed to be changed, e.g. Praha > Prague, Warszawa > Warsaw etc.))

	
-- view fixing city name -- v_filip_n_fixed_city_name
	CREATE OR REPLACE VIEW  v_filip_n_fixed_city_name AS 	 
	  	 SELECT
		DISTINCT 
		country,
		CASE 
		WHEN capital_city = 'Wien' THEN 'Vienna'
		WHEN capital_city = 'Bruxelles [Brussel]' THEN 'Brussels'
		WHEN capital_city = 'Praha' THEN 'Prague'
		WHEN capital_city = 'Helsinki [Helsingfors]' THEN 'Helsinki'
		WHEN capital_city = 'Athenai' THEN 'Athens'
		WHEN capital_city = 'Roma' THEN 'Rome'
		WHEN capital_city = 'Luxembourg [Luxemburg/L' THEN 'Luxembourg'
		WHEN capital_city = 'Warszawa' THEN 'Warsaw'
		WHEN capital_city = 'Bucuresti' THEN 'Bucharest'
		WHEN capital_city = 'Kyiv' THEN 'Kiev'
		ELSE capital_city END AS capital_city
		FROM countries c; 
		
SELECT 
*
FROM 
v_filip_n_fixed_city_name fxd_city_name;

	-- creating a table by joining columns from weather w table and v_filip_n_fixed_city_name with fixed city names 
	-- and adding required columns on daily average temp., hours of rain and max wind gust and replacing varcharacters by integers
  CREATE OR REPLACE Table t_filip_n_weather_data_fixed_city_names AS 
   SELECT
  	w.date, 
  	w.time,
  	w.city,
  fxd_city_name.country,
  		CONVERT (REPLACE(w.temp, ' °c', ''), INT) AS 'daily_avg_temp_°c',
	    CONVERT (REPLACE(w.rain, ' mm', ''), DECIMAL) AS 'rainy_hours',
	    CONVERT (REPLACE(w.gust, ' km/h', ''), INT) AS 'max_wind_gust_km_h'
	   FROM v_filip_n_fixed_city_name fxd_city_name
	  	 JOIN
	  	 	weather w 
	  	 	ON 
	  	 	fxd_city_name.capital_city = w.city 
	  	 WHERE 
	  	 	w.city IS NOT NULL 
	  	 ORDER BY w.date DESC;	 
	  	 
	  	 
	CREATE OR REPLACE TABLE t_filip_n_weather_variables 
	SELECT date,
	       city,
           country,
     AVG(CASE WHEN time IN ('06:00', '09:00', '12:00', '15:00', '18:00') THEN daily_avg_temp_°c 
                ELSE NULL END) AS avg_temp_°c,
      SUM(CASE WHEN rainy_hours > 0 THEN 1 ELSE 0 END) AS rainy_hours,
      MAX(max_wind_gust_km_h) AS max_wind_gust_km_h
  FROM t_filip_n_weather_data_fixed_city_names
 GROUP BY date,
          city,
          country
 ORDER BY date DESC,
          city ASC; 	

  UPDATE t_filip_n_weather_data_fixed_city_names 
	SET country = 'Russia'
	WHERE country = 'Russian Federation';	 
	

-- FINAL Join of Tables 

CREATE OR REPLACE Table t_filip_nowak_projekt_SQL_final as
	SELECT
		t_filip_n_countries_economies_data.country,
		t_filip_n_basic_data_table.date,
		t_filip_n_basic_data_table.tests_performed,
		t_filip_n_basic_data_table.working_day,
		t_filip_n_basic_data_table.season_of_year,
		t_filip_n_countries_economies_data.population_density,
		t_filip_n_countries_economies_data.median_age_2018,
		t_filip_n_countries_economies_data.GDP_2020,
		t_filip_n_countries_economies_data.Average_GINI,
		t_filip_n_countries_economies_data.Average_child_mortality,
		t_filip_n_Religions.Christianity_Share,
		t_filip_n_Religions.Islam_share,
		t_filip_n_Religions.Buddhism_share,
		t_filip_n_Religions.Hinduism_share,
		t_filip_n_Religions.Judaism_share,
		t_filip_n_Religions.Folk_rel_share,
		t_filip_n_life_expectation.life_expectancy_2015,
		t_filip_n_life_expectation.life_expectancy_1965,
		t_filip_n_life_expectation.life_expectancy_difference,
		t_filip_n_weather_variables.avg_temp_°c,
		t_filip_n_weather_variables.rainy_hours,
		t_filip_n_weather_variables .max_wind_gust_km_h
		FROM t_filip_n_basic_data_table
		LEFT JOIN t_filip_n_countries_economies_data
			ON    t_filip_n_basic_data_table.country = t_filip_n_countries_economies_data.country 
		LEFT JOIN t_filip_n_Religions
			ON	  t_filip_n_basic_data_table.country = t_filip_n_Religions.country
		LEFT JOIN t_filip_n_life_expectation
			ON    t_filip_n_basic_data_table.country = t_filip_n_life_expectation.country
		LEFT JOIN t_filip_n_weather_variables 
			ON t_filip_n_basic_data_table.country = t_filip_n_weather_variables.country
				AND t_filip_n_basic_data_table.date = t_filip_n_weather_variables.date
				ORDER BY date ASC, country ASC;		
		
-- FINAL QUERY
SELECT DISTINCT country
FROM t_filip_nowak_projekt_SQL_final;
	