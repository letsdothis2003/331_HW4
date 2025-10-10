-- Fahim Tanvir
--Group_1045_4
-- CSCI-331
-- HW4 & 5
/*intro: These are 10 queries,  which use subexpressions(from chapter 4) and 
table expressions(from chapter5) to operate on auditing and getting data related to
sales, customers, suppliers and employees. Thank you Esfar and Justin for testing them out*/

/*Include this or some of the queries won’t work*/
USE WideWorldImporters;
GO

--1.)

/*This is to find customer with lowest ammount of sales, using a scalar subquery. The purpose of finding
customers that don't really buy much is for customer retention purposes, and in this specific query, to find 
customer credentials such as their id, order dates and orderid.*/
SELECT OrderID,OrderDate,CustomerID --Outer Query for order and customer credentials
FROM
Sales.Orders
WHERE CustomerID = ( --Inner subquery for sales details
SELECT TOP 1 CustomerID
FROM Sales. Orders
GROUP BY CustomerID
ORDER BY COUNT(CustomerID) ASC
);


--2.)
/*All customers that ordered in Thanksgiving week of 2015. Just like my christmas queries
in hw1, most retailers and shops would look at sales during the holidays and see who ordered during them.
This will simply locate unique customer names from a subquery which will find all orders from a given week.*/

SELECT DISTINCT --Outer query for customer name
CustomerName
FROM
Sales.Customers
WHERE
CustomerID IN ( --Inner subquery for customer and sales details in thanksgiving week
SELECT CustomerID
FROM Sales.Orders
WHERE OrderDate BETWEEN '2015-11-23' AND '2015-11-29'
);

--3.)
/*This one simply audits every stock item, so that the company can keep track of basic sales. This
is done through a subquery where the outer query selects all stock items and inner inner subquery
matches the ones sold in the separate order table*/

SELECT DISTINCT StockItemID, StockItemName --Outer query for item credentials
FROM Warehouse. StockItems AS SI
WHERE
EXISTS (
SELECT 1 --Inner query to select items that were ordered to that of witihn company warehouse
FROM Sales.OrderLines AS OL
WHERE OL.StockItemID = SI.StockItemID
);


--4.)
/*Find the average and maximum ammount of sales between 2014-2016. This is to keep track 
of trends seen between orders of all 3 years, so that the company can compare max and avg rates 
of items sold and notice dips or increases in profits. This is done through by declaring our
average and max count along with our respective years in the outer query and selecting the actual orders
in the inner subquery*/
SELECT Yr, AVG(Cnt) AS AvgOrders, MAX(Cnt) AS MaxOrders --Outer Query for credentials for out average and max sales along with date
FROM (
SELECT YEAR(OrderDate) AS Yr, CustomerID, COUNT(OrderID) AS Cnt --Inner query for out years and to count orderid's per customer
FROM Sales.Orders
WHERE YEAR(OrderDate) IN (2014, 2015, 2016)
GROUP BY CustomerID, YEAR(OrderDate)
) AS T
GROUP BY Yr
ORDER BY Yr;


--5.)
/*Finding all customers with their total orders spent. This is done by a subquery, which will 
find customer and order credentials, and a set of inner joins, which will match orders with their
respective customers. The purpose of this is similar to some of the other ones here and before, where
it is useful for auditing customer records and sales data.*/
SELECT D.CustomerName, D.TotalOrderValue --Outer query for order and customer details
FROM (
SELECT C.CustomerName, SUM(OL.Quantity * OL.UnitPrice) AS TotalOrderValue --inner query for customer information and the information regarding their sales
FROM Sales. Customers AS C
INNER JOIN Sales. Orders AS O ON C.CustomerID = O.CustomerID
INNER JOIN Sales. OrderLines AS OL ON O.OrderID = OL.OrderID
GROUP BY
C.CustomerName) AS D
WHERE D.TotalOrderValue < 1000000.00 
ORDER BY D.TotalOrderValue DESC;


--6.)
/*This one is to find customers based on how early they opened their account. Purpose of this
is to track customers that supported the company the longest and to page through it
in small chunks(in this case from rows 5 to 20. This is done by a common table expression which sets
up customer credentials and then turns them into rows. Then it outputs data from rows 5 to 20.*/
WITH CustomerRanks AS --Statement gere declares customer rankings based on how old their account is
(
SELECT CustomerID, CustomerName,
ROW_NUMBER() OVER (ORDER BY AccountOpenedDate) As RowNum
FROM
Sales.Customers 
)
SELECT
CustomerID,CustomerName
FROM CustomerRanks
WHERE RowNum BETWEEN 5 AND 20 --We are selecting this range as an example. 
ORDER BY RowNum;


--7.) 
/*This one goes after all the order ids and the individual profit from each of them along with
the average order value of all the orders. It will only produce the orders that are above the 
average. This is done by a table expression which finds the profits, which will then be rfrerenced by 
another table expression to find the average.*/
WITH OrderValues AS ( --Expression is used to declare and find profit of our each order
SELECT  OL.OrderID,
SUM(OL.Quantity * OL.UnitPrice) AS OrderValue
FROM Sales.OrderLines AS OL
GROUP BY OL.OrderID
),
AverageOrderValue AS ( --This expression finds the average profit
SELECT AVG(OrderValue) AS GlobalAverage
FROM OrderValues
)
SELECT Top 10 OV.OrderID, OV.OrderValue
FROM OrderValues AS OV
CROSS JOIN AverageOrderValue AS AOV --Cross join matches the afforementioned values together
WHERE OV.OrderValue > AOV.GlobalAverage
ORDER BY OV.OrderValue DESC;

--8.)
/*This query finds average sales made by salespeople to see how well
they are doing in this regard. This is done by a table expression which selects their 
id and average prices, then selfjoins their data from 2 invoice-related tables
so that any respective rows on that person matches*/
WITH AvgInvoice AS ( --Expression used to declare salesperson credentials within our invoices and invoicelines
    SELECT 
        I.SalespersonPersonID,
        AVG(IL.ExtendedPrice) AS AvgInvoiceValue --Average profit or price made by that employee
    FROM Sales.Invoices I
    JOIN Sales.InvoiceLines IL ON I.InvoiceID = IL.InvoiceID
    GROUP BY I.SalespersonPersonID
)
SELECT 
    P.FullName AS Salesperson,
    AIPS.AvgInvoiceValue
FROM Application.People P
JOIN AvgInvoice AIPS  --Connect our salesperson data with person data
    ON P.PersonID = AIPS.SalespersonPersonID
ORDER BY AIPS.AvgInvoiceValue DESC;


--9.)
/*This one finds the suppliers that sell on the pricey side, using a comparison between unit prices 
and their average. This is done through a scalar subquery where it selects each supplier and matches their
data from their item prices from that table to their own data from another table. */
SELECT DISTINCT P.SupplierName --Subquery used to find suppliers
FROM Purchasing.Suppliers AS P
WHERE 
EXISTS (
SELECT 1 
FROM Warehouse.StockItems AS S
WHERE S.SupplierID = P.SupplierID 
AND S.UnitPrice > ( --Find unit prices that are higher than average price in our warhouse
SELECT AVG(UnitPrice) FROM Warehouse.StockItems
          )
    );


--10.)
/*Reverse of last proposition, where we are finding the cheaper suppliers. This is done through
table expressions declaring the average between every supplier's unit price and then declaring each
supplier who are less than that average.*/
WITH GlobalAverage AS ( --Change from last query using table expression instead of subquery
SELECT AVG(UnitPrice) AS AvgPrice --Changed it up a bit by placing the average price on top
FROM Warehouse. StockItems
) ,
PremiumSuppliers AS ( --Expression used to find suppliers that sell on the cheap end by finding prices cheaper than average
SELECT DISTINCT SupplierID
FROM Warehouse. StockItems, GlobalAverage
WHERE UnitPrice < GlobalAverage.AvgPrice
)
SELECT SupplierName
FROM Purchasing. Suppliers
WHERE SupplierID IN (SELECT SupplierID FROM PremiumSuppliers);
