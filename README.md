The task is to determine the rate of spread of coronavirus at country level. For this task please prepare:
-panel data to explain daily increases in each country
- keys: country and date
-3 required variables
1) number of infected people - will be explained by variables of several types
2) numbers of tests performed
3) the number of inhabitants of the country. 
Based on those variables  suitable explanatory variable can be created. 

Table consisting of the following columns is required to be created:
1. Time variables
-binary variable for weekend/workday
-season of the day (please code as 0 to 3)
2.Country specific variables
-Population density - in states with higher population density, the disease may spread faster
-GDP per capita - use as an indicator of the economic maturity of the state
-GINI coefficient - does wealth inequality affect the spread of coronavirus?
-Infant mortality - use as an indicator of health care quality
-median age of the population in 2018 - countries with older populations may be more affected
-proportions of different religions - use as a proxy variable for cultural specificities. For each religion in a given state, I would like the percentage of its members in the total population
-the difference between life expectancy in 1965 and in 2015 - countries that have experienced rapid development may respond differently than countries that have been developed for a longer period of time
3. Weather (affects people's behaviour and also the ability to spread the virus)
-average daytime (not nighttime!) temperature
-number of hours in a given day with non-zero rainfall
-maximum wind gusts during the day

---

For this task following data tables were used:
covid19_tests,
countries,
economies,
religions,
weather.

Each tables consists of various data sets for different amount of countries which leads to several issues:
-there is not enough data for all of the countries, e.g. there are some data on performed COVID tests missing in several important economies such as Germany, China, Brazil, Hong Kong, Netherlands, Singapore, Spain. Also not all of the data is consistent: several countries have different names in different tables, e.g. Czech Republic and Czechia, US and United Sates, South Korea and Korea, South, Russia and Russian Federation (the names of the countries were changed accordingly to allow joining tables in only in several cases).  Also there is inconsistency in terms of capital city names lie Praha > Prague, Warszawa > Warsaw (names in such cases were changed). 
Some Countries were treated as two entities in one table 1. Congo (Brazzaville) 2. Congo (Kinshasa) and as one in another table: Democratic Republic of Congo. 
In the part related to religion the sum of each religion believers had to be created as opposed to using the population number from a different table (since the number of population per some countries was lower than a number of believers in this particular country).
In the religion related part also columns for each considered religion were created using different Views per religion.

Approach:
Due to the complexity of the task several Selects were created and transformed into Views or Tables. Those Tables relevant for each part of the task then were joined into the one final table allowing to one table with required data variables.
