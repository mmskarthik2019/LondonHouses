CREATE DATABASE LondonHouses;
USE LondonHouses;

select * from london_houses;

/*1. Find the MINIMUM, AVERAGE and MAXIMUM Price by Location */

select Neighborhood as Location
       , MIN(price) as MinimumPrice
	   , AVG(Price) as AvergePrice
       , MAX(price) as MaximumPrice
	   from london_houses
	   group by Neighborhood
	   order by MAX(price) desc;

/*2. Find the Minimum, Average and Max Bedrooms, Bathrooms and Building_Age*/

select Neighborhood as Location
      , MIN(Bedrooms) as MinBedroom
      , MAX(Bedrooms) as MaxBedrooms
	  , AVG(Bedrooms) as AvgBedrooms
	  , MIN(Bathrooms) as MinBathRooms
	  , Max(Bathrooms) as MaxBathRooms
	  , AVG(Bathrooms) as AvgBathrooms
	  , MIN(Building_Age) as Min_Building_Age
	  , Max(Building_Age) as Max_Building_Age
	  , AVG(Building_Age) as AVG_Building_Age
	  from london_houses
	  group by Neighborhood


/*3. Find the Addresses which has atleast 2 Bedrooms and 2 Bathrooms 
and has a garden and it is not Apartment and has Balcony 
and which under 5 Lakhs
*/

select Address
      , Neighborhood
	  , Bedrooms
	  , Bathrooms
	  , ( CASE WHEN Garden= 1 then 'Yes'
	      ELSE 'No'
	    end ) as Garden
	  , Property_Type
	  , Price
	  from london_houses
	  where Bedrooms >= 2 
	  and Bathrooms >=2 
	  and Balcony not like '%No Balcony%' 
	  and Garden = 1 
	  and Property_Type like '%Apartment%'
	  and price <= 500000
	  order by price desc;
/*
96 King's Road	Greenwich	4	3	Yes	Apartment	500000
189 Bond Street	Greenwich	2	2	Yes	Apartment	473333
137 King's Road	Shoreditch	5	2	Yes	Apartment	462000
38 Piccadilly Circus	Shoreditch	5	3	Yes	Apartment	388666
146 Piccadilly Circus	Greenwich	2	3	Yes	Apartment	386666
*/



/* 4. Find which Property Type is the Highest Price*/

select Property_Type
       , sum(price) as TotalPrice
	   from london_houses
	   group by Property_Type
	   order by sum(price) desc;
/*
From the Data Detached Houses has the Highest price

Detached House	764753984
Semi-Detached	626316704
Apartment	449736590
*/


/* 5.Retrieve properties with more than 3 bedrooms, located in Notting Hill or Soho, and priced above £1,500,000. */
select Address
       , Neighborhood
	   , Bedrooms
	   , Price
	   from london_houses
	   where 
	   Bedrooms >=3
	   and price>= 1500000
	   and (Neighborhood like '%Notting Hill%' or Neighborhood like 'soho');

/* 6. Find the Total count of Properties for Each Propert Type*/

select Property_Type
      , count(Property_Type) as TotalProperties
	  from london_houses
	  group by Property_Type
	  order by count(Property_Type) desc;

/*7. Compute the average building age for properties with a garden and a garage.*/
select AVG(Building_Age) AverageBuildingAge
	  from london_houses
	  where Garden = 1 and Garage = 1

/*8.Retrieve the top 3 most expensive properties in each neighborhood.*/
with Top3Properties as
(select Address
      ,Neighborhood
	  ,Price TotalPrice
	  , rank() over (partition by Neighborhood order by Price desc) as RankedData
	  from london_houses
)
select Address
      ,Neighborhood
	  ,TotalPrice
	  from Top3Properties
	  where RankedData <=3

/* 9.Identify neighborhoods where the average price per square meter exceeds £10,000.*/
select * from london_houses;

select Neighborhood
      , concat('$ ',AvgPricePerSqM) as AvgPricePerSqM
	  from
          (select Neighborhood
		          , AVG(Price/Square_Meters) as AvgPricePerSqM
				  from london_houses
				  group by Neighborhood
		   ) as Subquery
	    where AvgPricePerSqM > 10000;

/*10. Find the property with the smallest price per square meter that also has a sea view.*/

select [View] from london_houses;


select Address
      , Neighborhood
	  , [view]
	  , concat('$ ',PricePerSqM) as PricePerSquareMeters
	  from
          ( select Address
		          , Neighborhood
		          , [view]
		          , Price/Square_Meters as PricePerSqM
				  , rank() over (order by (Price/Square_Meters) asc) rankedData
				  from london_houses 
				  where [View] like '%Sea%'
			) as subquery  
	   where rankedData =1;


/*11.For each neighborhood, rank properties by price in descending order using a window function.*/
           select Neighborhood
		          , Price
				  , rank() over (partition by Neighborhood order by Price desc) rankedData
				  from london_houses 

/*12.Calculate the running total of property prices across all neighborhoods, ordered by price.*/
select Address
      , Neighborhood
      , Price
	  , sum(Price) over (partition by Neighborhood order by Price) RunningTotal
	  from london_houses

/*13.Compute the difference in price between each property and the neighborhood's average price.*/

with AvgPrice as (
select Neighborhood
      , AVG(Price) as AVGPriceinNeighborhood
	   from london_houses
	   group by Neighborhood
),
NormalPrice as (
select Address
      , Neighborhood
	  , price
	  from london_houses
)
select N.Address,A.Neighborhood, N.Price, A.AVGPriceinNeighborhood, (N.Price-A.AVGPriceinNeighborhood) PriceDifference
from AvgPrice A
inner join NormalPrice N
on N.Neighborhood = A.Neighborhood
order by A.Neighborhood, (N.Price-A.AVGPriceinNeighborhood) desc;

/* 14.Use a CTE to find neighborhoods where more than 50% of properties have a garden.*/

select * from london_houses

WITH GardenStats AS (
    SELECT 
        Neighborhood,
        COUNT(CASE WHEN Garden = 1 THEN 1 END) AS Properties_With_Garden,
        COUNT(*) AS Total_Properties
    FROM 
        london_houses
    GROUP BY 
        Neighborhood
)
SELECT 
    Neighborhood,
    Properties_With_Garden,
    Total_Properties,
    (Properties_With_Garden* 1.0 / Total_Properties)*100 AS Garden_Percentage 
	-- This ensures that the division results in a decimal 
	--value (rather than integer division, which would round down if both operands are integers 
    --for example 18/30 will give 0.6 (60%) but if we dont use 1.0 then it will return 0 (0%) as output).
FROM 
    GardenStats
WHERE 
    (Properties_With_Garden * 1.0 / Total_Properties)*100  > 50;

/* 15. Use a CTE to calculate the average building age for each neighborhood 
and retrieve neighborhoods with an average building age under 40.*/

select * from london_houses;

with AverageAge as (
select Neighborhood
      , AVG(Building_Age)  as AVGBuildingAge
	  from london_houses
	  group by Neighborhood
)
select * from AverageAge where AVGBuildingAge >40;

/*15. Create a derived table to calculate price per square meter and 
join it with the original dataset to filter properties priced above £10,000 per square meter.*/

--A derived table is a temporary table created within a query, typically used for intermediate calculations or transformations. 
-- It is not a physical table stored in the database but exists only for the duration of the query execution.



SELECT 
    lh.Address,
    lh.Neighborhood,
    lh.Bedrooms,
    lh.Bathrooms,
    lh.Square_Meters,
    lh.Price,
    derived.Price_Per_SqM
FROM 
    london_houses lh
JOIN 
    (SELECT 
        Address,
        (Price / Square_Meters) AS Price_Per_SqM
    FROM 
        london_houses) derived
ON lh.Address = derived.Address
WHERE 
    derived.Price_Per_SqM > 10000;


/* 16. Compare properties with and without a garage by calculating the average price and size for each group.*/

SELECT 
    Garage,
    AVG(Price) AS Avg_Price,
    AVG(Square_Meters) AS Avg_Size_in_SQM
FROM 
    london_houses
GROUP BY 
    Garage;


/*17. Extract the street names from the Address column and count how many properties exist on each street.*/
select substring(Address,CHARINDEX(' ', Address),len(Address)) AS Street_Name
      , COUNT(*) as TotalProperties
	  from london_houses
	  group by substring(Address,CHARINDEX(' ', Address),len(Address))
	  order by COUNT(*) desc;

--The SUBSTRING() function extracts some characters from a string.
-- SUBSTRING(string, start, length)
--The CHARINDEX() function searches for a substring in a string, and returns the position. If the substring is not found, this function returns 0.
--CHARINDEX(substring, string, start) start is optional
--The LEN() function returns the length of a string.



/*18. Use a string function to identify properties where the Interior Style contains the word "Classic."*/

select Address
       , Neighborhood
	   from london_houses
	   where Interior_Style like '%classic%'

/*19. Use a CASE statement to categorize properties as "Luxury" (price > £1,500,000), 
"Affordable" (price ≤ £1,000,000), or "Mid-range" (in between).*/

select Address
      , Neighborhood
	  , Price
	  , ( CASE WHEN price >= 1500000 then 'Luxury'
	      WHEN price <= 1000000 then 'Affordable'
		  ELSE 'mid-Range' end
		 ) as Category
	  from london_houses
	  order by Neighborhood, price;

/* 20.Create a new column indicating whether properties are suitable for renovation 
(Building Status is "Old" and Building Age > 50). */
select * from london_houses;

select Address
      , Neighborhood
	  , Building_Status
	  , Building_Age
	  , ( CASE WHEN (Building_Status = 'Old' and Building_Age >50) then 'YES'
	      ELSE 'NO' END
	  ) as RenovationNeeded
	  from london_houses
	  order by Building_Age desc

/* 21. Prepare a query for visualization tools to display the price distribution by neighborhood and property type.*/

SELECT 
    Neighborhood,
    Property_Type,
    (CASE 
        WHEN Price < 500000 THEN 'Under 500k'
        WHEN Price >= 500000 AND Price < 1000000 THEN '500k - 1M'
        WHEN Price >= 1000000 AND Price < 1500000 THEN '1M - 1.5M'
        WHEN Price >= 1500000 THEN 'Over 1.5M'
    END) AS Price_Bin,
    COUNT(*) AS Property_Count
FROM 
    london_houses
GROUP BY 
    Neighborhood, 
    Property_Type, 
    CASE 
        WHEN Price < 500000 THEN 'Under 500k'
        WHEN Price >= 500000 AND Price < 1000000 THEN '500k - 1M'
        WHEN Price >= 1000000 AND Price < 1500000 THEN '1M - 1.5M'
        WHEN Price >= 1500000 THEN 'Over 1.5M'
    END
ORDER BY 
    Neighborhood, 
    Property_Type, 
    Price_Bin;




/* 22. Create a temporary table to store properties located in Westminster and Soho, 
and use it to find the highest-priced property in these neighborhoods.*/

create table #Highest_priced_properties(
Address varchar(25)
, Neighborhood varchar(25)
, Price int
)

insert into #Highest_priced_properties
select Address
      , Neighborhood
	  , Price
	  from london_houses
	  where Neighborhood = 'Westminster' or Neighborhood = 'soho'


select Top 3 * 
      from #Highest_priced_properties
	  where Neighborhood <> 'westminster' -- Soho if we want Soho Information
	  order by Neighborhood, price desc


/* 24. Use a Temp Table to calculate the average price per square meter for each property type 
and then filter properties exceeding this average.*/

select * from london_houses;

create table #average_price_per_SM(
       Address varchar(50)
       , Neighborhood varchar(50)
	   , Property_type varchar(50)
	   , Price int
	   , AVG_Price int
	   , Notive varchar(100)
)


with AveragePropertyType as 
(
select Property_Type
      , AVG(Price) as AVG_Price
	  from london_houses
	  group by Property_Type
),
Datapart as (
select Address
      , Neighborhood
      , Property_Type
	  , Price
	  from london_houses
),
calculation as (
select d1.Address
      ,d1.Neighborhood
      , d1.Property_Type
	  , d1.Price 
	  , a1.AVG_Price 
	  from Datapart d1
	  inner join AveragePropertyType a1
	  on a1.Property_Type = d1.Property_Type
)

insert into #average_price_per_SM
select Address
       , Neighborhood
	   , Property_type
	   , Price
	   , AVG_Price
	   , case when Price>AVG_Price then concat('$ ',Price-AVG_Price,' Greater Than Average Price') end as Notice
	   from calculation
	   where Price>AVG_Price

select * from #average_price_per_SM

/* 25. Create a stored procedure that accepts a neighborhood name 
and returns the top 5 most expensive properties in that neighborhood.*/

select distinct(Neighborhood) from london_houses 

create procedure ExpensivePropertiesByNeighborhood(@NeighborhoodName varchar(10)) as 
(
select Address,Neighborhood,Bedrooms,Bathrooms,Square_Meters,Building_Age,Garden,Garage,Floors,Property_Type,Heating_Type,Balcony,Interior_Style,[View],Materials,Building_Status,Price
from
( select  *
	   , ( case when Neighborhood = @NeighborhoodName then rank() over(partition by Neighborhood order by Price desc) 
		   end
		  ) as RankedData
	   from london_houses
	   ) as subquery
	   where RankedData <= 5
)

exec ExpensivePropertiesByNeighborhood @NeighborhoodName = 'Islington';

drop procedure ExpensivePropertiesByNeighborhood

/* 26. Write a stored procedure that calculates and 
returns the average price per square meter for properties with specific attributes (e.g., heating type, interior style).*/

select * from london_houses

CREATE PROCEDURE GetAveragePricePerSquareMeter
    @HeatingType NVARCHAR(50), 
    @InteriorStyle NVARCHAR(50)
AS
(
    -- Calculate and return the average price per square meter
    SELECT 
        AVG(CAST(Price AS FLOAT) / Square_Meters) AS AvgPricePerSquareMeter
    FROM 
        london_houses
    WHERE 
        Heating_Type = @HeatingType 
        AND Interior_Style = @InteriorStyle
)

EXEC GetAveragePricePerSquareMeter 'Central Heating', 'Industrial';
