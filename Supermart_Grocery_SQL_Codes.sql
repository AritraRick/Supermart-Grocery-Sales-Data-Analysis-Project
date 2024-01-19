
select * from Supermart_Grocery_Sales

-- About to delete duplicate rows
delete tb1 from (select *,
ROW_NUMBER() over(partition by Order_ID order by Order_ID) as rn
from Supermart_Grocery_Sales) as tb1
where tb1.rn > 1

-- Find categorywise sales whose sales are less than average sales of that category
SELECT * FROM 
(SELECT Order_ID, Customer_Name, Category, Discount, Sales, 
ROUND(AVG(Sales) OVER (PARTITION BY Category),0) AS Avg_Sale
FROM Supermart_Grocery_Sales) AS tb1
WHERE Sales < tb1.Avg_Sale
ORDER BY tb1.Category, tb1.Sales DESC


-- Find the top 25% of customer details based on ranking of their sales value
SELECT * FROM (SELECT Order_ID, Customer_Name, Category, Discount, Sales, 
(PERCENT_RANK() OVER (ORDER BY Sales DESC)) AS RN2
FROM Supermart_Grocery_Sales) AS Rick_3
WHERE Rick_3.RN2 <= 0.25


-- Find customer details whose rank is 2 based on sales
SELECT * FROM 
(SELECT Order_ID, Customer_Name, Category, Discount, Sales, 
(DENSE_RANK() OVER (ORDER BY Sales DESC)) AS RN
FROM Supermart_Grocery_Sales) AS Rick_2
WHERE Rick_2.RN = 2


-- Find cumulative sum of total discount categorywise
SELECT Category, round(SUM(Discount),2) as Total_Discount, 
SUM(SUM(Discount)) OVER(ORDER BY sum(Discount)) as Cum_Discount
FROM Supermart_Grocery_Sales
GROUP BY Category


-- Find cumulative sum of total profit customerwise and arrange sum of profit in ascending order
SELECT Customer_Name, ROUND(SUM(Profit),0) as Total_Profit,
SUM(ROUND(SUM(Profit),0)) OVER(ORDER BY ROUND(SUM(Profit),0)) as Cumulative_Sum  
FROM Supermart_Grocery_Sales 
GROUP BY Customer_Name


-- Find cumulative sum of total profit over the years and arrange Years in ascending order
select YEAR(Order_Date) as Order_Year, round(sum(Profit),0) as Total_Profit,
SUM(round(sum(Profit),0)) over(order by round(sum(Profit),0)) as Cum_Profit
from Supermart_Grocery_Sales
group by YEAR(Order_Date)
order by YEAR(Order_Date)


-- Find cumulative sum of total sales over the years and arrange Years in ascending order
select YEAR(Order_Date) as Order_Year, round(sum(Sales),0) as Total_Sales,
SUM(round(sum(Sales),0)) over(order by round(sum(Sales),0)) as Cum_Sales
from Supermart_Grocery_Sales
group by YEAR(Order_Date)
order by YEAR(Order_Date)


-- Show yearwise total profit and compare the previous year profit in another column
select *,
LAG(Total_Profit,1,0) over(order by Order_Year) as Prev_Year_Profit
from (select YEAR(Order_date) as Order_Year, round(SUM(Profit),0) as Total_Profit from Supermart_Grocery_Sales
group by YEAR(Order_date)) as tb1


-- Show region wise total profit
select  
round(sum(case when Region = 'East' then Profit else 0 end),2) as EastProfit,
round(sum(case when Region = 'West' then Profit else 0 end),2) as WestProfit,
round(sum(case when Region = 'North' then Profit else 0 end),2) as NorthProfit,
round(sum(case when Region = 'South' then Profit else 0 end),2) as SouthProfit
from Supermart_Grocery_Sales


-- Identify the top 5 cities basis Profit Margin
select * from (SELECT City , ROUND((SUM(Profit)/SUM(Sales))*100, 2) AS Profit_Margin,
DENSE_RANK() over(order by ROUND((SUM(Profit)/SUM(Sales))*100, 2) desc) as dnr
FROM Supermart_Grocery_Sales 
GROUP BY City) as tb1
where tb1.dnr <= 5


-- Find out top 10 Customers who purchased the maximum number of Health Drinks
select * from (select Customer_Name, count(Sub_Category) as Total_Health_Drinks,
DENSE_RANK() over(order by count(Sub_Category) desc) as dnr
from Supermart_Grocery_Sales
where Sub_Category = 'Health Drinks'
group by Customer_Name) as tb1
where tb1.dnr <= 10


-- Who are the top 10 Customers who got the maximum Amount of overall Discount whileshopping
select * from (SELECT Customer_Name, ROUND(SUM(Sales*Discount),2) AS Overall_Discount,
DENSE_RANK() over(order by ROUND(SUM(Sales*Discount),2) desc) as dnr
FROM Supermart_Grocery_Sales 
GROUP BY Customer_Name) as tb1
where tb1.dnr <= 10


-- An order is said to be a High Discount order if Discount >=25%, Medium Discount orderif Discount is >=15% and <25% and Low Discount Order if Discount is < 15%.
-- Please report the count of High, Medium and Low Discount orders in Each category
select Category, Discount_Type, COUNT(Discount_Type) as No_Of_Discount from (SELECT Category, Discount,--COUNT(*), 
CASE 
	WHEN Discount >= 0.25 THEN 'High Discount'
	WHEN Discount >= 0.15 AND Discount < 0.25 THEN 'Medium Discount'
	ELSE 'Low Discount'
END AS Discount_Type
FROM Supermart_Grocery_Sales) as tb1
group by tb1.Category, tb1.Discount_Type
order by tb1.Category, COUNT(Discount_Type) desc


-- If any state does overall Sales of < 50000INR in a month, it’s said to be a “Lacking Sale Region” for that month. Give the list of states that were “Lull Sale Regions” along with specific time periods
select * from (SELECT State, YEAR(Order_Date) as Sale_Year, MONTH(Order_Date) as Sale_Month, SUM(Sales) as Total_Sales,
CASE
	WHEN SUM(Sales) < 50000 THEN 'Lacking Sale Region'
	ELSE ''
END AS Region_Part
FROM Supermart_Grocery_Sales
GROUP BY YEAR(Order_Date), MONTH(Order_Date), State) as tb1
where tb1.Region_Part <> ' '
order by tb1.Sale_Year, tb1.Sale_Month


-- How many days did 20+ Customers shop from the Grocery Mart?
SELECT COUNT(Order_Date) as No_Of_Days FROM (SELECT Order_Date, COUNT(Order_ID) AS Total_Order_Id FROM Supermart_Grocery_Sales 
GROUP BY Order_Date
HAVING COUNT(Order_ID)>20) AS Total_Count


-- Show which quarter gets the maximum Sales for each year?
select Order_Year, Quarter_No, Total_Sale from (select *,
DENSE_RANK() over(partition by tb1.Order_Year order by tb1.Total_Sale desc) as dns_rank
from (SELECT YEAR(Order_Date) as Order_Year,
datepart(quarter, Order_Date) AS Quarter_No, sum(Sales) as Total_Sale
FROM Supermart_Grocery_Sales
group by YEAR(Order_Date), datepart(quarter, Order_Date)
) as tb1) as tb2
where tb2.dns_rank = 1


-- What is the average frequency of orders per Customer per month?
 select Customer_Name, Order_Year, Order_Month, AVG(No_Of_Orders) as Avg_Orders from (SELECT Customer_Name, COUNT(Order_ID) as No_Of_Orders, MONTH(Order_Date) as Order_Month, YEAR(Order_Date) as Order_Year FROM Supermart_Grocery_Sales 
 GROUP BY Customer_Name, YEAR(Order_Date), MONTH(Order_Date)
 ) as tb1
 group by tb1.Customer_Name, tb1.Order_Year, tb1.Order_Month
 order by tb1.Order_Year, tb1.Order_Month, tb1.Customer_Name


 -- Show the total sales of the east and west region only and for the remaining region show the sum of sales of them as other region
select tbl1.RegDiv, sum(tbl1.Sales) as Total_Sales from
(select *, 
(case when Region = 'East' or Region = 'West' then Region else 'Other' end) as RegDiv
from Supermart_Grocery_Sales) as tbl1
group by tbl1.RegDiv


-- Determine the average profit margin for each category and sub-category
SELECT Category, Sub_Category, AVG(Profit/Sales) AS Avg_Profit_Margin
FROM Supermart_Grocery_Sales
GROUP BY Category, Sub_Category
ORDER BY Category


-- Analyze the seasonality of sales by month and quarter
SELECT YEAR(Order_Date) AS Order_Year, MONTH(Order_Date) AS Order_Month, SUM(Sales) AS Total_Sales
FROM Supermart_Grocery_Sales
GROUP BY YEAR(Order_Date), MONTH(Order_Date)
ORDER BY Order_Year, Order_Month


-- Identify the trend of profit margin changes for each Region over time
SELECT Order_Year, Region, AVG(Profit/Sales) AS Avg_Profit_Margin
FROM (
    SELECT YEAR(Order_Date) AS Order_Year, Region, SUM(Profit) AS Profit, SUM(Sales) AS Sales
    FROM Supermart_Grocery_Sales
    GROUP BY YEAR(Order_Date), Region
) AS tb1
GROUP BY Order_Year, Region
ORDER BY Order_Year, Region;


-- Calculate the Moving Average of Sales for each Category over a 3-month period
SELECT Order_ID, Category, Order_Date, Sales,
       AVG(Sales) OVER (PARTITION BY Category ORDER BY Order_Date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS Moving_Avg_Sales
FROM Supermart_Grocery_Sales
ORDER BY Category, Order_Date;



-- Calculate Customer Lifetime Value (CLTV)
SELECT
	Order_Date,
    Customer_Name,
    SUM(Sales) AS Total_Sales,
    AVG(Sales) AS Avg_Order_Value,
    COUNT(DISTINCT Order_ID) AS Purchase_Frequency,
    SUM(Profit) AS Total_Profit,
    LAG(SUM(Sales),1,0) OVER (PARTITION BY Customer_Name ORDER BY Order_Date) AS Previous_Total_Sales
FROM Supermart_Grocery_Sales
GROUP BY Customer_Name, Order_Date
ORDER BY Customer_Name, Order_Date;


-- Analyze Sales by Day of the Week
SELECT 
    DATENAME(WEEKDAY, Order_Date) AS Day_of_Week,
    SUM(Sales) AS Total_Sales
FROM Supermart_Grocery_Sales
GROUP BY DATENAME(WEEKDAY, Order_Date)
ORDER BY Total_Sales DESC;


-- Calculate Churn Rate
-- Using CTE
WITH ChurnCTE AS (
    SELECT 
        CONVERT(VARCHAR(7), Order_Date, 120) AS YearMonth,
        Customer_Name,
        COUNT(DISTINCT Order_ID) AS Num_Orders
    FROM Supermart_Grocery_Sales
    GROUP BY CONVERT(VARCHAR(7), Order_Date, 120), Customer_Name
)

SELECT 
    YearMonth,
    COUNT(DISTINCT CASE WHEN Num_Orders = 1 THEN Customer_Name END) AS New_Customers,
    COUNT(DISTINCT CASE WHEN Num_Orders > 1 THEN Customer_Name END) AS Returning_Customers,
    1.0 * COUNT(DISTINCT CASE WHEN Num_Orders = 1 THEN Customer_Name END) / COUNT(DISTINCT Customer_Name) AS Churn_Rate
FROM ChurnCTE
GROUP BY YearMonth
ORDER BY YearMonth;


-- Using subquery
SELECT 
    YearMonth,
    COUNT(DISTINCT CASE WHEN Num_Orders = 1 THEN Customer_Name END) AS New_Customers,
    COUNT(DISTINCT CASE WHEN Num_Orders > 1 THEN Customer_Name END) AS Returning_Customers,
    1.0 * COUNT(DISTINCT CASE WHEN Num_Orders = 1 THEN Customer_Name END) / COUNT(DISTINCT Customer_Name) AS Churn_Rate
FROM (
    SELECT 
        CONVERT(VARCHAR(7), Order_Date, 120) AS YearMonth,
        Customer_Name,
        COUNT(DISTINCT Order_ID) AS Num_Orders
    FROM Supermart_Grocery_Sales
    GROUP BY CONVERT(VARCHAR(7), Order_Date, 120), Customer_Name
) AS ChurnSubquery
GROUP BY YearMonth
ORDER BY YearMonth;



-- Perform cohort analysis, grouping customers based on their first order date (Cohort_Start_Date) and analyzing their behavior over time, 
-- include cohort size, number of orders, average order value, and the count of new customers in each cohort month
SELECT 
    Cohort_Start_Date,
    DATEDIFF(MONTH, Cohort_Start_Date, Order_Date) AS Cohort_Month,
    COUNT(DISTINCT Customer_Name) AS Cohort_Size,
    COUNT(DISTINCT Order_ID) AS Num_Orders,
    AVG(Sales) AS Avg_Order_Value,
    COUNT(DISTINCT CASE WHEN DATEDIFF(MONTH, Cohort_Start_Date, Order_Date) = 0 THEN Customer_Name END) AS New_Customers
FROM (
    SELECT 
        Customer_Name,
        MIN(Order_Date) OVER (PARTITION BY Customer_Name) AS Cohort_Start_Date,
        Order_Date,
        Order_ID,
        Sales
    FROM Supermart_Grocery_Sales
	) AS tb1
GROUP BY Cohort_Start_Date, DATEDIFF(MONTH, Cohort_Start_Date, Order_Date)
ORDER BY Cohort_Start_Date, Cohort_Month;













